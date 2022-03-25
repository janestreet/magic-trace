(** Runs a program under Intel ProcessorTrace in Snapshot mode *)
open! Core

open! Async
open! Import

let supports_fzf =
  Lazy.from_fun (fun () ->
      let pid = Core_unix.fork_exec ~prog:"fzf" ~argv:[ "--version" ] ~use_path:true () in
      let exit_or_signal = Core_unix.waitpid pid in
      match Core_unix.Exit_or_signal.or_error exit_or_signal with
      | Error _ -> false
      | Ok () -> true)
;;

(* Other parts of the process would fail after this without IPT, but by checking directly
   we can give a more helpful error message regardless of backend. *)
let check_for_processor_trace_support () =
  match Core_unix.access "/sys/bus/event_source/devices/intel_pt" [ `Exists ] with
  | Ok () -> Ok ()
  | Error _ ->
    Or_error.error_string
      "Error: This machine doesn't support Intel Processor Trace, which is a hardware \
       feature essential for magic-trace to work.\n\
       This may be because it's a virtual machine or it's a physical machine that isn't \
       new enough or uses an AMD processor.\n\
       Try again on a physical Intel machine."
;;

let write_trace_from_events
    ~verbose
    ?debug_info
    trace
    hits
    (events : Event.t Pipe.Reader.t)
  =
  (* Normalize to earliest event = 0 to avoid Perfetto rounding issues *)
  let%bind.Deferred earliest_time =
    let%map.Deferred _wait_for_first = Pipe.values_available events in
    match Pipe.peek events with
    | Some earliest -> earliest.time
    | None -> Time_ns.Span.zero
  in
  let events =
    Pipe.map events ~f:(fun (event : Event.t) ->
        if verbose then Core.print_s (Event.sexp_of_t event);
        { event with time = event.time })
  in
  let writer = Trace_writer.create ~debug_info ~earliest_time ~hits trace in
  let process_event ev = Trace_writer.write_event writer ev in
  let%map () = Pipe.iter_without_pushback events ~f:process_event in
  Trace_writer.flush_all writer
;;

module Make_commands (Backend : Backend_intf.S) = struct
  module Decode_opts = struct
    type t =
      { output_config : Tracing_tool_output.t
      ; decode_opts : Backend.Decode_opts.t
      ; verbose : bool
      }
  end

  module Hits_file = struct
    type t = (string * Breakpoint.Hit.t) list [@@deriving sexp]

    let filename ~record_dir = record_dir ^/ "hits.sexp"
  end

  let decode_to_trace ?elf ~record_dir { Decode_opts.output_config; decode_opts; verbose }
    =
    Core.eprintf "[Decoding, this may take 30s or so...]\n%!";
    Tracing_tool_output.write_and_view output_config ~f:(fun w ->
        let open Deferred.Or_error.Let_syntax in
        let trace_writer = Tracing.Trace.Expert.create ~base_time:None w in
        let hits =
          In_channel.read_all (Hits_file.filename ~record_dir)
          |> Sexp.of_string
          |> [%of_sexp: Hits_file.t]
        in
        let debug_info = Option.map elf ~f:Elf.addr_table in
        let%bind event_pipe = Backend.decode_events decode_opts ~record_dir in
        let%bind () =
          write_trace_from_events ?debug_info ~verbose trace_writer hits event_pipe
          |> Deferred.ok
        in
        Tracing.Trace.close trace_writer;
        return ())
  ;;

  module Record_opts = struct
    type t =
      { backend_opts : Backend.Record_opts.t
      ; use_filter : bool
      ; multi_snapshot : bool
      ; snap_symbol : Re.re
      ; record_dir : string
      ; executable : string
      ; snap_on_delay_over : Time_ns.Span.t option
      ; duration_thresh : Time_ns.Span.t option
      }
  end

  module Attachment = struct
    type t =
      { recording : Backend.Recording.t
      ; done_ivar : unit Ivar.t
      ; breakpoint_done : unit Deferred.t
      ; finalize_recording : unit -> unit
      }
  end

  let attach ?elf (opts : Record_opts.t) pid =
    let%bind.Deferred.Or_error () =
      check_for_processor_trace_support () |> Deferred.return
    in
    let%bind.Deferred.Or_error filter, snap_loc =
      match elf with
      | None -> Deferred.Or_error.return (None, None)
      | Some elf ->
        let snap_syms = Elf.matching_functions elf opts.snap_symbol in
        let%bind.Deferred.Or_error snap_sym =
          match Map.length snap_syms, Map.min_elt snap_syms with
          | 0, _ -> Deferred.Or_error.return None
          | 1, Some (_, s) -> Deferred.Or_error.return (Some s)
          | _ ->
            if force supports_fzf
            then Fzf.pick_one (Fzf.Pick_from.Map snap_syms)
            else
              Deferred.Or_error.error_string
                "Multiple matches found for the given symbol. magic-trace could show you \
                 a fuzzy-finding selector here if \"fzf\" were in your PATH, but it is \
                 not."
        in
        let snap_loc =
          Option.map snap_sym ~f:(fun sym -> Elf.symbol_stop_info elf pid sym)
        in
        let filter =
          match opts.use_filter, snap_loc with
          | true, Some { Elf.Stop_info.filter; _ } -> Some filter
          | _, _ -> None
        in
        Deferred.Or_error.return (filter, snap_loc)
    in
    let%map.Deferred.Or_error recording =
      Backend.Recording.attach_and_record
        opts.backend_opts
        ~record_dir:opts.record_dir
        ?filter
        pid
    in
    let done_ivar = Ivar.create () in
    let snapshot_taken = ref false in
    let take_snapshot () =
      match Backend.Recording.take_snapshot recording with
      | Ok () ->
        snapshot_taken := true;
        Core.eprintf "[Snapshot taken!]\n%!";
        if not opts.multi_snapshot then Ivar.fill_if_empty done_ivar ()
      | Error e -> Core.eprint_s [%message "failed to take snapshot" (e : Error.t)]
    in
    let hits = ref [] in
    let finalize_recording () =
      if not !snapshot_taken then take_snapshot ();
      Out_channel.write_all
        (Hits_file.filename ~record_dir:opts.record_dir)
        ~data:([%sexp (!hits : Hits_file.t)] |> Sexp.to_string)
    in
    let last_hit = ref Time_ns_unix.Option.none in
    let last_report = ref Time_ns.epoch in
    let max_since_last_report = ref Time_ns.Span.zero in
    let report_interval = Time_ns.Span.of_int_sec 5 in
    let print_report () =
      Core.eprintf
        !"[Waiting for delay over threshold. Max delay since last report: %{Time_ns.Span}]\n\
          %!"
        !max_since_last_report;
      max_since_last_report := Time_ns.Span.zero
    in
    let take_snapshot_on_hit hit =
      hits := hit :: !hits;
      take_snapshot ()
    in
    let maybe_take_snapshot' hit =
      match opts.snap_on_delay_over with
      | None -> take_snapshot_on_hit hit
      | Some span_thresh ->
        let now = Time_ns.now () in
        let open Time_ns_unix.Option.Optional_syntax in
        (match%optional !last_hit with
        | Some t ->
          let interval = Time_ns.diff now t in
          max_since_last_report := Time_ns.Span.max !max_since_last_report interval;
          if Time_ns.Span.( > ) interval span_thresh
          then take_snapshot_on_hit hit
          else if Time_ns.( > ) now (Time_ns.add !last_report report_interval)
          then (
            print_report ();
            last_report := now)
        | _ -> ());
        last_hit := Time_ns_unix.Option.some now
    in
    let maybe_take_snapshot hit =
      match opts.duration_thresh with
      | None -> maybe_take_snapshot' hit
      | Some duration_thresh ->
        let _, { Breakpoint.Hit.timestamp; passed_timestamp; _ } = hit in
        let duration = Time_ns.Span.of_int_ns (timestamp - passed_timestamp) in
        if Time_ns.Span.( > ) duration duration_thresh then maybe_take_snapshot' hit
    in
    let breakpoint_done =
      match snap_loc with
      | None ->
        Core.eprintf "[Couldn't find symbol. Will still snapshot on end]\n%!";
        Deferred.unit
      | Some { Elf.Stop_info.name; addr; _ } ->
        Core.eprintf "[Attaching to %s @ 0x%016Lx]\n%!" name addr;
        (* This is a safety feature so that if you accidentally attach to a symbol that
           gets called very frequently, in single snapshot mode it will only trigger the
           breakpoint once before the breakpoint gets disabled. In [multi_snapshot] mode
           you can accidentally incur an ~8us interrupt on every call until perf disables
           your breakpoint for exceeding the hit rate limit. *)
        let single_hit =
          (not opts.multi_snapshot)
          && Option.is_none opts.snap_on_delay_over
          && Option.is_none opts.duration_thresh
        in
        let bp = Breakpoint.breakpoint_fd pid ~addr:(Int.of_int64_exn addr) ~single_hit in
        let bp = Or_error.ok_exn bp in
        let fd =
          Async_unix.Fd.create
            Async_unix.Fd.Kind.File
            (Breakpoint.fd bp)
            (Info.of_string "perf breakpoint")
        in
        let rec read_evs snapshot_enabled =
          match Breakpoint.next_hit bp with
          | Some hit ->
            if snapshot_enabled then maybe_take_snapshot (name, hit);
            read_evs false
          | None -> ()
        in
        let interrupt = Ivar.read done_ivar in
        let%map.Deferred res =
          Async_unix.Fd.interruptible_every_ready_to
            fd
            `Read
            ~interrupt
            (fun () -> read_evs true)
            ()
        in
        (match res with
        | `Interrupted -> Breakpoint.destroy bp
        | `Bad_fd | `Closed | `Unsupported -> failwith "failed to wait on breakpoint")
    in
    { Attachment.recording; done_ivar; breakpoint_done; finalize_recording }
  ;;

  let detach { Attachment.recording; done_ivar; breakpoint_done; finalize_recording } =
    Ivar.fill_if_empty done_ivar ();
    let%bind () = breakpoint_done in
    Core.eprintf "[Finished recording!]\n%!";
    finalize_recording ();
    Backend.Recording.finish_recording recording
  ;;

  let run_and_record ?elf ~command record_opts =
    let open Deferred.Or_error.Let_syntax in
    let argv = Array.of_list command in
    let pid = Probes_lib.Raw_ptrace.start ~argv |> Pid.of_int in
    let%bind attachment = attach ?elf record_opts pid in
    Probes_lib.Raw_ptrace.detach (Pid.to_int pid);
    Async_unix.Signal.handle Async_unix.Signal.terminating ~f:(fun signal ->
        UnixLabels.kill ~pid:(Pid.to_int pid) ~signal:(Signal_unix.to_system_int signal));
    let%bind.Deferred (_ : Core_unix.Exit_or_signal.t) = Async_unix.Unix.waitpid pid in
    detach attachment
  ;;

  let attach_and_record ?elf record_opts pid =
    let%bind.Deferred.Or_error attachment = attach ?elf record_opts pid in
    let { Attachment.done_ivar; _ } = attachment in
    let stop = Ivar.read done_ivar in
    Async_unix.Signal.handle ~stop [ Signal.int ] ~f:(fun (_ : Signal.t) ->
        Core.eprintf "[Got signal, detaching...]\n%!";
        Ivar.fill_if_empty done_ivar ());
    Core.eprintf "[Attached! Press Ctrl-C to stop recording]\n%!";
    let%bind () = stop in
    detach attachment
  ;;

  let record_dir_flag mode =
    let open Command.Param in
    flag
      "-record-dir"
      (mode Filename_unix.arg_type)
      ~doc:"DIR create this directory if necessary and put raw trace data in it"
  ;;

  let record_flags =
    let%map_open.Command record_dir = record_dir_flag optional
    and executable_override =
      flag
        "-executable-override"
        (optional Filename_unix.arg_type)
        ~doc:
          "FILE executable to extract information from, default is to use the first part \
           of COMMAND"
    and snap_symbol =
      flag
        "-symbol"
        (optional string)
        ~doc:
          "SYMBOL take a snapshot when a symbol matching this regex is called, lets you \
           pick a symbol with fzf if many match, use the empty string to show all \
           symbols, defaults to Magic_trace.take_snapshot"
    and snap_on_delay_over =
      flag
        "-delay-thresh"
        (optional Time_ns_unix.Span.arg_type)
        ~doc:"SPAN only snapshot when delay between symbol calls is longer than this"
    and duration_thresh =
      flag
        "-duration-thresh"
        (optional Time_ns_unix.Span.arg_type)
        ~doc:"SPAN only snapshot intervals between mark_start and take_snapshot over this"
    and use_filter =
      flag
        "-immediate-stop"
        no_arg
        ~doc:"stop immediately on snapshot, may crash kernel on EL8"
    and multi_snapshot =
      flag "-multi-snapshot" no_arg ~doc:"allow taking multiple snapshots if possible"
    and backend_opts = Backend.Record_opts.param in
    fun ~default_executable ~f ->
      (match duration_thresh, snap_symbol with
      | Some _, Some _ ->
        failwith
          "Can't use -duration-thresh while using -symbol, the duration only works with \
           Magic_trace.take_snapshot, try -delay-thresh instead."
      | _ -> ());
      let executable =
        match executable_override with
        | Some path -> path
        | None -> default_executable ()
      in
      let snap_symbol =
        match snap_symbol with
        | Some sym -> Re.Posix.re sym |> Re.compile
        | None -> Re.str Magic_trace.Private.stop_symbol |> Re.whole_string |> Re.compile
      in
      let record_dir, cleanup =
        match record_dir with
        | Some dir ->
          if not (Sys_unix.is_directory_exn dir) then Core_unix.mkdir dir;
          dir, false
        | None -> Filename_unix.temp_dir "magic_trace" "", true
      in
      Monitor.protect
        ~finally:(fun () ->
          if cleanup then Shell.rm ~r:() ~f:() record_dir;
          Deferred.unit)
        (fun () ->
          f
            { Record_opts.backend_opts
            ; use_filter
            ; multi_snapshot
            ; snap_symbol
            ; record_dir
            ; executable
            ; snap_on_delay_over
            ; duration_thresh
            })
  ;;

  let decode_flags =
    let%map_open.Command output_config = Tracing_tool_output.param
    and verbose = flag "-verbose" no_arg ~doc:"print decoded events"
    and decode_opts = Backend.Decode_opts.param in
    { Decode_opts.output_config; decode_opts; verbose }
  ;;

  let trace_command =
    Command.async_or_error
      ~summary:
        "Generate a trace for a command, and convert the results to a viewable Fuchsia \
         trace."
      (let%map_open.Command record_opt_fn = record_flags
       and decode_opts = decode_flags
       and command = anon ("COMMAND" %: string |> non_empty_sequence_as_list)
       and command_extra = flag "--" escape ~doc:"ARGS additional arguments" in
       fun () ->
         let open Deferred.Or_error.Let_syntax in
         let command =
           match command_extra with
           | None -> command
           | Some l -> command @ l
         in
         let default_executable () =
           let cmd = List.hd_exn command in
           match Shell.which cmd with
           | Some path -> path
           | None -> failwithf "Can't find executable for %s" cmd ()
         in
         record_opt_fn ~default_executable ~f:(fun opts ->
             let elf = Elf.create opts.executable in
             let%bind () = run_and_record ?elf ~command opts in
             decode_to_trace ?elf ~record_dir:opts.record_dir decode_opts))
  ;;

  let select_pid () =
    if force supports_fzf
    then (
      (* There are no Linux APIs, or OCaml libraries that I've found, for enumerating
       running processes. The [ps] command uses the /proc/ filesystem and is much easier
       than walking the /proc/ system and filtering ourselves. *)
      let process_lines =
        [ [ "x"; "-w"; "--no-headers" ]
        ; [ "-o"; "pid,args" ]
          (* If running as root, allow tracing all processes, including those owned
         by non-root users. *)
        ; (if Core_unix.geteuid () = 0 then [ "-e" ] else [])
        ]
        |> List.concat
        |> Shell.run_lines "ps"
      in
      let%bind.Deferred.Or_error sel_line =
        Fzf.pick_one (Fzf.Pick_from.Inputs process_lines)
      in
      let pid =
        let%bind.Option sel_line = sel_line in
        let sel_line = String.lstrip sel_line in
        let%map.Option first_part = String.split ~on:' ' sel_line |> List.hd in
        Pid.of_string first_part
      in
      match pid with
      | Some s -> Deferred.return (Ok s)
      | None -> Deferred.Or_error.error_string "No pid selected")
    else
      Deferred.Or_error.error_string
        "The [-pid] argument is mandatory. magic-trace could show you a fuzzy-finding \
         selector here if \"fzf\" were in your PATH, but it is not."
  ;;

  let attach_command =
    Command.async_or_error
      ~summary:
        "Attach to a process and record it until Ctrl-C, then convert the results to a \
         viewable Fuchsia trace."
      (let%map_open.Command record_opt_fn = record_flags
       and decode_opts = decode_flags
       and pid =
         flag
           "-pid"
           (optional int)
           ~doc:
             "PID Process to attach to. Required if you don't have the \"fzf\" \
              application available in your PATH."
       in
       fun () ->
         let open Deferred.Or_error.Let_syntax in
         let%bind pid =
           match pid with
           | Some pid -> Pid.of_int pid |> Deferred.Or_error.return
           | None -> select_pid ()
         in
         let default_executable () =
           Core_unix.readlink [%string "/proc/%{pid#Pid}/exe"]
         in
         record_opt_fn ~default_executable ~f:(fun opts ->
             let elf = Elf.create opts.executable in
             let%bind () = attach_and_record ?elf opts pid in
             decode_to_trace ?elf ~record_dir:opts.record_dir decode_opts))
  ;;

  let decode_command =
    Command.async_or_error
      ~summary:
        "Decode processor trace data and convert the results to a viewable Fuchsia trace."
      (let%map_open.Command record_dir = record_dir_flag required
       and decode_opts = decode_flags
       and executable =
         flag
           "-executable"
           (required Filename_unix.arg_type)
           ~doc:"FILE executable to extract information from"
       in
       fun () ->
         let elf = Elf.create executable in
         decode_to_trace ?elf ~record_dir decode_opts)
  ;;

  let commands =
    [ "trace", trace_command; "attach", attach_command; "decode", decode_command ]
  ;;
end

module Perf_tool_commands = Make_commands (Perf_tool_backend)

let command =
  let commands = Perf_tool_commands.commands in
  Command.group ~summary:"Magical tracing based on Intel Processor Trace" commands
;;

module For_testing = struct
  let write_trace_from_events = write_trace_from_events ~verbose:false
end
