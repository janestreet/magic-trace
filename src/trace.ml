(** Runs a program under Intel Processor Trace in Snapshot mode *)
open! Core

open! Async
open! Import

let supports_fzf =
  Lazy.from_fun (fun () ->
      match Core_unix.fork () with
      | `In_the_child ->
        Core_unix.close Core_unix.stdout;
        Core_unix.exec ~prog:"fzf" ~argv:[ "fzf"; "--version" ] ~use_path:true ()
        |> never_returns
      | `In_the_parent pid ->
        let exit_or_signal = Core_unix.waitpid pid in
        (match Core_unix.Exit_or_signal.or_error exit_or_signal with
        | Error _ -> false
        | Ok () -> true))
;;

let create_elf ~executable ~(when_to_snapshot : When_to_snapshot.t) =
  let elf = Elf.create executable in
  match when_to_snapshot, elf with
  | Application_calls_a_function _, None ->
    Deferred.Or_error.errorf
      "As far as magic-trace can tell, that executable doesn't have a symbol table. Was \
       the binary built without debug info?"
  | Magic_trace_or_the_application_terminates, _ | _, Some _ -> return (Ok elf)
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
    ~trace_mode
    ?debug_info
    writer
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
  let trace =
    let base_time =
      Time_ns.add (Boot_time.time_ns_of_boot_in_perf_time ()) earliest_time
    in
    Tracing.Trace.Expert.create ~base_time:(Some base_time) writer
  in
  let events =
    Pipe.map events ~f:(fun (event : Event.t) ->
        if verbose then Core.print_s (Event.sexp_of_t event);
        { event with time = event.time })
  in
  let writer = Trace_writer.create ~trace_mode ~debug_info ~earliest_time ~hits trace in
  let process_event ev = Trace_writer.write_event writer ev in
  let%map () = Pipe.iter_without_pushback events ~f:process_event in
  Trace_writer.flush_all writer;
  Tracing.Trace.close trace
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

  let decode_to_trace
      ~elf
      ~trace_mode
      ~record_dir
      { Decode_opts.output_config; decode_opts; verbose }
    =
    Core.eprintf "[Decoding, this may take 30s or so...]\n%!";
    Tracing_tool_output.write_and_maybe_view output_config ~f:(fun writer ->
        let open Deferred.Or_error.Let_syntax in
        let hits =
          In_channel.read_all (Hits_file.filename ~record_dir)
          |> Sexp.of_string
          |> [%of_sexp: Hits_file.t]
        in
        let debug_info = Option.map elf ~f:Elf.addr_table in
        let%bind event_pipe = Backend.decode_events decode_opts ~record_dir in
        let%bind () =
          write_trace_from_events ?debug_info ~trace_mode ~verbose writer hits event_pipe
          |> Deferred.ok
        in
        return ())
  ;;

  module Record_opts = struct
    type t =
      { backend_opts : Backend.Record_opts.t
      ; multi_snapshot : bool
      ; when_to_snapshot : When_to_snapshot.t
      ; record_dir : string
      ; executable : string
      ; trace_mode : Trace_mode.t
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

  let attach ~elf (opts : Record_opts.t) pid =
    let%bind.Deferred.Or_error () =
      check_for_processor_trace_support () |> Deferred.return
    in
    let%bind.Deferred.Or_error snap_loc =
      match elf with
      | None -> return (Ok None)
      | Some elf ->
        (match opts.when_to_snapshot with
        | Magic_trace_or_the_application_terminates -> return (Ok None)
        | Application_calls_a_function which_function ->
          let%bind.Deferred.Or_error snap_sym =
            match which_function with
            | Use_fzf_to_select_one ->
              let all_symbols = Elf.all_symbols elf in
              if force supports_fzf
              then (
                match%bind.Deferred.Or_error Fzf.pick_one (Assoc all_symbols) with
                | None -> Deferred.Or_error.error_string "No symbol selected"
                | Some symbol -> return (Ok symbol))
              else
                Deferred.Or_error.error_string
                  "magic-trace could show you a fuzzy-finding selector here if \"fzf\" \
                   were in your PATH, but it is not."
            | User_selected symbol_name ->
              (match Elf.find_symbol elf symbol_name with
              | None ->
                Deferred.Or_error.errorf "Snapshot symbol not found: %s" symbol_name
              | Some symbol -> return (Ok symbol))
          in
          let snap_loc = Elf.symbol_stop_info elf pid snap_sym in
          return (Ok (Some snap_loc)))
    in
    let%map.Deferred.Or_error recording =
      Backend.Recording.attach_and_record
        opts.backend_opts
        ~trace_mode:opts.trace_mode
        ~record_dir:opts.record_dir
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
    let take_snapshot_on_hit hit =
      hits := hit :: !hits;
      take_snapshot ()
    in
    let breakpoint_done =
      match snap_loc with
      | None -> Deferred.unit
      | Some { Elf.Stop_info.name; addr; _ } ->
        Core.eprintf "[Attaching to %s @ 0x%016Lx]\n%!" name addr;
        (* This is a safety feature so that if you accidentally attach to a symbol that
           gets called very frequently, in single snapshot mode it will only trigger the
           breakpoint once before the breakpoint gets disabled. In [multi_snapshot] mode
           you can accidentally incur an ~8us interrupt on every call until perf disables
           your breakpoint for exceeding the hit rate limit. *)
        let single_hit = not opts.multi_snapshot in
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
            if snapshot_enabled then take_snapshot_on_hit (name, hit);
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

  let run_and_record ~elf ~command_with_args record_opts =
    let open Deferred.Or_error.Let_syntax in
    let argv = Array.of_list command_with_args in
    let pid = Probes_lib.Raw_ptrace.start ~argv |> Pid.of_int in
    let%bind attachment = attach ~elf record_opts pid in
    Probes_lib.Raw_ptrace.detach (Pid.to_int pid);
    Async_unix.Signal.handle Async_unix.Signal.terminating ~f:(fun signal ->
        UnixLabels.kill ~pid:(Pid.to_int pid) ~signal:(Signal_unix.to_system_int signal));
    let%bind.Deferred (_ : Core_unix.Exit_or_signal.t) = Async_unix.Unix.waitpid pid in
    detach attachment
  ;;

  let attach_and_record ?elf record_opts pid =
    let%bind.Deferred.Or_error attachment = attach ~elf record_opts pid in
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
      "-working-directory"
      (mode Filename_unix.arg_type)
      ~doc:
        "DIR Where to store intermediate files (including raw perf.data files). If not \
         provided, magic-trace stores them in a subdirectory of $TMPDIR and deletes them \
         when it's done. If provided, files will be stored in the given directory, \
         creating the directory if necessary, and magic-trace will not delete the \
         directory when it's done."
  ;;

  let record_flags =
    let%map_open.Command record_dir = record_dir_flag optional
    and when_to_snapshot = When_to_snapshot.param
    and multi_snapshot =
      flag
        "-multi-snapshot"
        no_arg
        ~doc:
          "Take a snapshot every time the trigger is hit, instead of only the first \
           time. This flag has two caveats:\n\
           (1) There's an ~8us performance hit every time the trigger symbol is hit. If \
           snapshots trigger frequently, your application's performance may be \
           materially impacted.\n\
           (2) Each snapshot linearly increases the size of the trace file. Large trace \
           files may crash the trace viewer."
    and trace_mode = Trace_mode.param
    and backend_opts = Backend.Record_opts.param in
    fun ~executable ~f ->
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
            ; multi_snapshot
            ; when_to_snapshot
            ; record_dir
            ; executable
            ; trace_mode
            })
  ;;

  let decode_flags =
    let%map_open.Command output_config = Tracing_tool_output.param
    and verbose = flag "-verbose" no_arg ~doc:"print decoded events"
    and decode_opts = Backend.Decode_opts.param in
    { Decode_opts.output_config; decode_opts; verbose }
  ;;

  let run_command =
    Command.async_or_error
      ~summary:"Runs a command and traces it."
      (let%map_open.Command record_opt_fn = record_flags
       and decode_opts = decode_flags
       and command = anon ("COMMAND" %: string)
       and args =
         flag "--" escape ~doc:"ARGS Arguments for the command. Ignored by magic-trace."
       in
       fun () ->
         let open Deferred.Or_error.Let_syntax in
         let command_with_args = command :: List.concat (Option.to_list args) in
         let executable =
           match Shell.which command with
           | Some path -> path
           | None -> failwithf "Can't find executable for %s" command ()
         in
         record_opt_fn ~executable ~f:(fun opts ->
             let elf = Elf.create opts.executable in
             let%bind () = run_and_record ~elf ~command_with_args opts in
             decode_to_trace
               ~elf
               ~trace_mode:opts.trace_mode
               ~record_dir:opts.record_dir
               decode_opts))
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
      ~summary:"Traces a running process."
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
           | Some pid -> return (Pid.of_int pid)
           | None -> select_pid ()
         in
         let executable = Core_unix.readlink [%string "/proc/%{pid#Pid}/exe"] in
         record_opt_fn ~executable ~f:(fun opts ->
             let { Record_opts.executable; when_to_snapshot; _ } = opts in
             let%bind elf = create_elf ~executable ~when_to_snapshot in
             let%bind () = attach_and_record ?elf opts pid in
             decode_to_trace
               ~elf
               ~trace_mode:opts.trace_mode
               ~record_dir:opts.record_dir
               decode_opts))
  ;;

  let decode_command =
    Command.async_or_error
      ~summary:"Converts perf-script output to a trace. (expert)"
      (let%map_open.Command record_dir = record_dir_flag required
       and trace_mode = Trace_mode.param
       and decode_opts = decode_flags
       and executable =
         flag
           "-executable"
           (required Filename_unix.arg_type)
           ~doc:"FILE Executable to extract debug symbols from."
       in
       fun () ->
         (* Doesn't use create_elf because there's no need to check that the binary has symbols if
            we're trying to snapshot it. *)
         let elf = Elf.create executable in
         decode_to_trace ~elf ~trace_mode ~record_dir decode_opts)
  ;;

  let commands =
    [ "run", run_command; "attach", attach_command; "decode", decode_command ]
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
