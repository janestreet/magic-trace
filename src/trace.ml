(** Runs a program under Intel Processor Trace in Snapshot mode *)

open! Core
open! Async
open! Import

let supports_command command =
  Lazy.from_fun (fun () ->
      match Core_unix.fork () with
      | `In_the_child ->
        Core_unix.close Core_unix.stdout;
        Core_unix.close Core_unix.stderr;
        Core_unix.exec ~prog:command ~argv:[ command; "--version" ] ~use_path:true ()
        |> never_returns
      | `In_the_parent pid ->
        let exit_or_signal = Core_unix.waitpid pid in
        (match Core_unix.Exit_or_signal.or_error exit_or_signal with
        | Error _ -> false
        | Ok () -> true))
;;

let supports_fzf = supports_command "fzf"
let supports_perf = supports_command "perf"

let check_for_perf () =
  if force supports_perf
  then return (Ok ())
  else
    Deferred.Or_error.errorf
      "magic-trace relies on \"perf\", but it is not present in your path. You may need \
       to install it."
;;

let create_elf ~executable ~(when_to_snapshot : When_to_snapshot.t) =
  let elf = Elf.create executable in
  match when_to_snapshot, elf with
  | Application_calls_a_function _, None ->
    Deferred.Or_error.errorf
      "Cannot select a snapshot symbol because magic-trace can't find that executable's \
       symbol table. Was it built without debug info, or with debug info magic-trace \
       doesn't understand?\n\
       See \
       https://github.com/janestreet/magic-trace/wiki/Compiling-code-for-maximum-compatibility-with-magic-trace \
       for more info."
  | Magic_trace_or_the_application_terminates, _ | _, Some _ -> return (Ok elf)
;;

let evaluate_symbol_selection ~symbol_selection ~elf ~header =
  let open Deferred.Or_error.Let_syntax in
  let%bind elf =
    match elf with
    | None -> Deferred.Or_error.error_string "No ELF found"
    | Some elf -> return elf
  in
  match symbol_selection with
  | Symbol_selection.Use_fzf_to_select_one ->
    let all_symbol_names = Elf.all_symbols elf |> List.map ~f:Tuple2.get1 in
    if force supports_fzf
    then (
      match%bind Fzf.pick_one ~header (Inputs all_symbol_names) with
      | None -> Deferred.Or_error.error_string "No symbol selected"
      | Some symbol -> return symbol)
    else
      Deferred.Or_error.error_string
        "magic-trace could show you a fuzzy-finding selector here if \"fzf\" were in \
         your PATH, but it is not."
  | User_selected user_selection -> return user_selection
;;

let evaluate_trace_filter ~(trace_filter : Trace_filter.Unevaluated.t option) ~elf =
  let open Deferred.Or_error.Let_syntax in
  match trace_filter with
  | None -> return None
  | Some { start_symbol; stop_symbol } ->
    let%bind start_symbol =
      evaluate_symbol_selection
        ~symbol_selection:start_symbol
        ~elf
        ~header:"Range filter start symbol"
    in
    let%map stop_symbol =
      evaluate_symbol_selection
        ~symbol_selection:stop_symbol
        ~elf
        ~header:"Range filter stop symbol"
    in
    Some { Trace_filter.start_symbol; stop_symbol }
;;

let debug_flag flag = if Env_vars.debug then flag else Command.Param.return false

let debug_print_perf_commands =
  let open Command.Param in
  flag "-z-print-perf-commands" no_arg ~doc:"Prints perf commands when they're executed."
  |> debug_flag
;;

let write_trace_from_events
    ?ocaml_exception_info
    ~print_events
    ~trace_scope
    ~debug_info
    writer
    ~hits
    ~events
    ~close_result
  =
  (* Normalize to earliest event = 0 to avoid Perfetto rounding issues *)
  let%bind.Deferred earliest_time =
    let events = List.hd_exn events in
    let%map.Deferred _wait_for_first = Pipe.values_available events in
    match Pipe.peek events |> Option.map ~f:Event.With_write_info.event with
    | Some (Ok earliest) -> earliest.time
    | None | Some (Error _) -> Time_ns.Span.zero
  in
  let trace =
    let base_time =
      Time_ns.add (Boot_time.time_ns_of_boot_in_perf_time ()) earliest_time
    in
    Tracing.Trace.Expert.create ~base_time:(Some base_time) writer
  in
  let events =
    if print_events
    then
      List.map events ~f:(fun events ->
          Pipe.map events ~f:(fun event ->
              Core.print_s ~mach:() (Event.With_write_info.event event |> Event.sexp_of_t);
              event))
    else events
  in
  let writer =
    Trace_writer.create
      ~trace_scope
      ~debug_info
      ~ocaml_exception_info
      ~earliest_time
      ~hits
      ~annotate_inferred_start_times:Env_vars.debug
      trace
  in
  let last_index = ref 0 in
  let process_event index (ev : Event.With_write_info.t) =
    (* When processing a new snapshot, clear all [Trace_writer] data in order to
       avoid sharing callstacks, start times, etc. *)
    if index > 0 && not (index = !last_index)
    then (
      match%optional.Time_ns_unix.Span.Option Event.time ev.event with
      | None -> Trace_writer.end_of_trace writer
      | Some to_time -> Trace_writer.end_of_trace ~to_time writer);
    last_index := index;
    Trace_writer.write_event writer ev
  in
  let%bind () =
    Deferred.List.iteri events ~f:(fun index events ->
        Pipe.iter_without_pushback events ~f:(process_event index))
  in
  Trace_writer.end_of_trace writer;
  Tracing.Trace.close trace;
  close_result
;;

let write_event_sexps writer events close_result =
  Writer.write_line writer "(V3 (";
  let%bind () =
    Deferred.List.iter events ~f:(fun events ->
        Pipe.iter_without_pushback
          events
          ~f:(fun { Event.With_write_info.event; should_write } ->
            if should_write
            then Writer.write_sexp ~terminate_with:Newline writer (Event.sexp_of_t event)))
  in
  Writer.write_line writer "))";
  close_result
;;

let get_events_and_close_result ~decode_events ~range_symbols =
  let open Deferred.Or_error.Let_syntax in
  match range_symbols with
  | None ->
    let%map { Decode_result.events; close_result } = decode_events () in
    ( List.map events ~f:(fun events ->
          Pipe.map events ~f:(fun event ->
              Event.With_write_info.create ~should_write:true event))
    , close_result )
  | Some range_symbols ->
    For_range.decode_events_and_annotate ~decode_events ~range_symbols
;;

module Make_commands (Backend : Backend_intf.S) = struct
  module Decode_opts = struct
    type t =
      { output_config : Tracing_tool_output.t
      ; decode_opts : Backend.Decode_opts.t
      ; print_events : bool
      }
  end

  module Hits_file = struct
    type t = (string * Breakpoint.Hit.t) list [@@deriving sexp]

    let filename ~record_dir = record_dir ^/ "hits.sexp"
  end

  let decode_to_trace
      ?perf_maps
      ?range_symbols
      ~elf
      ~trace_scope
      ~debug_print_perf_commands
      ~record_dir
      ~collection_mode
      { Decode_opts.output_config; decode_opts; print_events }
    =
    Core.eprintf "[ Decoding, this takes a while... ]\n%!";
    let recording_data =
      try
        Some
          (In_channel.read_all (record_dir ^/ "recording_data.sexp")
          |> Sexp.of_string
          |> [%of_sexp: Backend.Recording.Data.t])
      with
      | Sys_error _ -> None
    in
    let decode_events ?filter_same_symbol_jumps () =
      Backend.decode_events
        ?perf_maps
        ?filter_same_symbol_jumps
        decode_opts
        ~debug_print_perf_commands
        ~recording_data
        ~record_dir
        ~collection_mode
    in
    Tracing_tool_output.write_and_maybe_view
      output_config
      ~f_sexp:(fun writer ->
        let open Deferred.Or_error.Let_syntax in
        let%bind events, close_result =
          get_events_and_close_result
            ~decode_events:(decode_events ~filter_same_symbol_jumps:false)
            ~range_symbols
        in
        let%bind () = write_event_sexps writer events close_result in
        return ())
      ~f_fuchsia:(fun writer ->
        let open Deferred.Or_error.Let_syntax in
        let hits =
          In_channel.read_all (Hits_file.filename ~record_dir)
          |> Sexp.of_string
          |> [%of_sexp: Hits_file.t]
        in
        let debug_info =
          match
            Option.bind elf ~f:(fun elf -> Option.try_with (fun () -> Elf.addr_table elf))
          with
          | None ->
            eprintf
              "Warning: Debug info is unavailable, so filenames and line numbers will \
               not be available in the trace.\n\
               See \
               https://github.com/janestreet/magic-trace/wiki/Compiling-code-for-maximum-compatibility-with-magic-trace \
               for more info.\n";
            None
          | Some _ as x -> x
        in
        let ocaml_exception_info = Option.bind elf ~f:Elf.ocaml_exception_info in
        let%bind events, close_result =
          get_events_and_close_result ~decode_events ~range_symbols
        in
        let%bind () =
          write_trace_from_events
            ?ocaml_exception_info
            ~debug_info
            ~trace_scope
            ~print_events
            writer
            ~hits
            ~events
            ~close_result
        in
        return ())
  ;;

  module Record_opts = struct
    type t =
      { backend_opts : Backend.Record_opts.t
      ; multi_snapshot : bool
      ; when_to_snapshot : When_to_snapshot.t
      ; trace_filter : Trace_filter.Unevaluated.t option
      ; record_dir : string
      ; executable : string
      ; trace_scope : Trace_scope.t
      ; timer_resolution : Timer_resolution.t
      ; collection_mode : Collection_mode.t
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

  let attach
      (opts : Record_opts.t)
      ~elf
      ~debug_print_perf_commands
      ~subcommand
      ~collection_mode
      pids
    =
    let open Deferred.Or_error.Let_syntax in
    Process_info.read_all_proc_info ();
    let head_pid = List.hd_exn pids in
    let%bind snap_loc =
      match opts.when_to_snapshot with
      | Magic_trace_or_the_application_terminates -> return None
      | Application_calls_a_function symbol_selection ->
        (match elf with
        | None -> Deferred.Or_error.error_string "No ELF found"
        | Some elf ->
          let%bind symbol_name =
            evaluate_symbol_selection
              ~symbol_selection
              ~elf:(Some elf)
              ~header:"Snapshot symbol"
          in
          let%bind snap_sym =
            Deferred.return
              (Result.of_option
                 (Elf.find_symbol elf symbol_name)
                 ~error:
                   (Error.of_string [%string "Snapshot symbol not found: %{symbol_name}"]))
          in
          let snap_loc = Elf.symbol_stop_info elf head_pid snap_sym in
          return (Some snap_loc))
    in
    let%map.Deferred.Or_error recording, recording_data =
      Backend.Recording.attach_and_record
        opts.backend_opts
        ~debug_print_perf_commands
        ~subcommand
        ~when_to_snapshot:opts.when_to_snapshot
        ~trace_scope:opts.trace_scope
        ~multi_snapshot:opts.multi_snapshot
        ~timer_resolution:opts.timer_resolution
        ~record_dir:opts.record_dir
        ~collection_mode
        pids
    in
    let done_ivar = Ivar.create () in
    let snapshot_taken = ref false in
    let take_snapshot ~source =
      Backend.Recording.maybe_take_snapshot recording ~source;
      snapshot_taken := true;
      Core.eprintf "[ Snapshot taken. ]\n%!";
      if not opts.multi_snapshot then Ivar.fill_if_empty done_ivar ()
    in
    let hits = ref [] in
    let finalize_recording () =
      if not !snapshot_taken then take_snapshot ~source:`ctrl_c;
      Out_channel.write_all
        (Hits_file.filename ~record_dir:opts.record_dir)
        ~data:([%sexp (!hits : Hits_file.t)] |> Sexp.to_string);
      Out_channel.write_all
        (opts.record_dir ^/ "recording_data.sexp")
        ~data:([%sexp (recording_data : Backend.Recording.Data.t)] |> Sexp.to_string)
    in
    let take_snapshot_on_hit hit =
      hits := hit :: !hits;
      take_snapshot ~source:`function_call
    in
    let breakpoint_done =
      match snap_loc with
      | None -> Deferred.unit
      | Some { Elf.Stop_info.name; addr; _ } ->
        Core.eprintf "[ Attaching to %s @ 0x%016Lx ]\n%!" name addr;
        (* This is a safety feature so that if you accidentally attach to a symbol that
           gets called very frequently, in single snapshot mode it will only trigger the
           breakpoint once before the breakpoint gets disabled. In [multi_snapshot] mode
           you can accidentally incur an ~8us interrupt on every call until perf disables
           your breakpoint for exceeding the hit rate limit. *)
        let single_hit = not opts.multi_snapshot in
        let bp = Breakpoint.breakpoint_fd head_pid ~addr ~single_hit in
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
    finalize_recording ();
    let%bind.Deferred.Or_error () = Backend.Recording.finish_recording recording in
    Core.eprintf "[ Finished recording. ]\n%!";
    return (Ok ())
  ;;

  let run_and_record
      record_opts
      ~elf
      ~debug_print_perf_commands
      ~prog
      ~argv
      ~collection_mode
    =
    let open Deferred.Or_error.Let_syntax in
    let pid = Ptrace.fork_exec_stopped ~prog ~argv () in
    let%bind attachment =
      attach
        record_opts
        ~elf
        ~debug_print_perf_commands
        ~subcommand:Run
        ~collection_mode
        [ pid ]
    in
    Ptrace.resume pid;
    (* Forward ^C to the child, unless it has already exited. *)
    let exited_ivar = Ivar.create () in
    Async_unix.Signal.handle
      ~stop:(Ivar.read exited_ivar)
      Async_unix.Signal.terminating
      ~f:(fun signal ->
        try
          UnixLabels.kill ~pid:(Pid.to_int pid) ~signal:(Signal_unix.to_system_int signal)
        with
        | Core_unix.Unix_error (_, (_ : string), (_ : string)) ->
          (* We raced, but it's OK because the child still exited. *)
          ());
    (* [Monitor.try_with] because [waitpid] raises if perf died before we got here. *)
    let%bind.Deferred (waitpid_result : (Core_unix.Exit_or_signal.t, exn) result) =
      Monitor.try_with (fun () -> Async_unix.Unix.waitpid pid)
    in
    (match waitpid_result with
    | Ok _ -> ()
    | Error error ->
      Core.eprintf
        !"Warning: [perf] exited suspiciously quickly; it may have crashed.\n\
          Error: %{Exn}\n\
          %!"
        error);
    (* This is still a little racey, but it's the best we can do without pidfds. *)
    Ivar.fill exited_ivar ();
    let%bind () = detach attachment in
    return pid
  ;;

  let attach_and_record record_opts ~elf ~debug_print_perf_commands ~collection_mode pids =
    let%bind.Deferred.Or_error attachment =
      attach
        record_opts
        ~elf
        ~debug_print_perf_commands
        ~subcommand:Attach
        ~collection_mode
        pids
    in
    let { Attachment.done_ivar; _ } = attachment in
    let stop = Ivar.read done_ivar in
    Async_unix.Signal.handle ~stop [ Signal.int ] ~f:(fun (_ : Signal.t) ->
        Core.eprintf "[ Got signal, detaching... ]\n%!";
        Ivar.fill_if_empty done_ivar ());
    Core.eprintf "[ Attached. Press Ctrl-C to stop recording. ]\n%!";
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
    and trace_filter = Trace_filter.param
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
    and trace_scope = Trace_scope.param
    and timer_resolution = Timer_resolution.param
    and backend_opts = Backend.Record_opts.param
    and collection_mode = Collection_mode.param in
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
            ; trace_filter
            ; record_dir
            ; executable
            ; trace_scope
            ; timer_resolution
            ; collection_mode
            })
  ;;

  let decode_flags =
    let%map_open.Command output_config = Tracing_tool_output.param
    and print_events =
      flag "-z-print-events" no_arg ~doc:"Prints decoded [Event.t]s." |> debug_flag
    and decode_opts = Backend.Decode_opts.param in
    { Decode_opts.output_config; decode_opts; print_events }
  ;;

  let open_url_flags =
    let open Command.Param in
    flag
      "open-url"
      (optional string)
      ~doc:
        "opens a url to display trace. options are local, magic, or android to open \
         http://localhost:10000, https://magic-trace.org, or https://ui.perfetto.dev \
         respectively"
    |> map ~f:(fun user_input ->
           Option.map user_input ~f:(fun user_choice ->
               match user_choice with
               | "local" -> "http://localhost:10000"
               | "magic" -> "https://magic-trace.org"
               | "android" -> "https://ui.perfetto.dev"
               | _ -> raise_s [%message "unkown user input" (user_choice : string)]))
  ;;

  let use_processor_flag =
    let open Command.Param in
    flag
      "use-processor-exe"
      (optional string)
      ~doc:"path for standalone processor exe to use to process trace file"
  ;;

  let run_command =
    Command.async_or_error
      ~summary:"Runs a command and traces it."
      ~readme:(fun () ->
        "=== examples ===\n\n\
         # Run a process, snapshotting at ^C or exit\n\
         magic-trace run ./program -- arg1 arg2\n\n\
         # Run and trace all threads of a process, not just the main one, snapshotting \
         at ^C or exit\n\
         magic-trace run -multi-thread ./program -- arg1 arg2\n\n\
         # Run a process, tracing its entire execution (only practical for short-lived \
         processes)\n\
         magic-trace run -full-execution ./program\n\
         # Run a process that generates a large trace file, and view it on \
         magic-trace.org magic-trace run ./program -open-url magic -use-processor-exe \
         ~/local-trace-processor\n")
      (let%map_open.Command record_opt_fn = record_flags
       and decode_opts = decode_flags
       and debug_print_perf_commands = debug_print_perf_commands
       and prog = anon ("COMMAND" %: string)
       and trace_processor_exe = use_processor_flag
       and url = open_url_flags
       and argv =
         flag "--" escape ~doc:"ARGS Arguments for the command. Ignored by magic-trace."
       in
       fun () ->
         let open Deferred.Or_error.Let_syntax in
         let%bind () = check_for_perf () in
         let executable =
           match Shell.which prog with
           | Some path -> path
           | None -> failwithf "Can't find executable for %s" prog ()
         in
         let%bind () =
           record_opt_fn ~executable ~f:(fun opts ->
               let elf = Elf.create opts.executable in
               let%bind range_symbols =
                 evaluate_trace_filter ~trace_filter:opts.trace_filter ~elf
               in
               let%bind pid =
                 let argv = prog :: List.concat (Option.to_list argv) in
                 run_and_record
                   opts
                   ~elf
                   ~debug_print_perf_commands
                   ~prog
                   ~argv
                   ~collection_mode:opts.collection_mode
               in
               let%bind.Deferred perf_maps = Perf_map.Table.load_by_pids [ pid ] in
               decode_to_trace
                 ~perf_maps
                 ?range_symbols
                 ~elf
                 ~trace_scope:opts.trace_scope
                 ~debug_print_perf_commands
                 ~record_dir:opts.record_dir
                 ~collection_mode:opts.collection_mode
                 decode_opts)
         in
         let%bind.Deferred () =
           match url with
           | None -> Deferred.return ()
           | Some url -> Async_shell.run "open" [ url ]
         in
         let output_config = decode_opts.Decode_opts.output_config in
         let output = Tracing_tool_output.output output_config in
         let output_file =
           match output with
           | `Sexp _ -> failwith "unimplemented"
           | `Fuchsia store_path -> store_path
         in
         let%bind.Deferred () =
           match trace_processor_exe with
           | None ->
             print_endline "warning: must use local processor on large trace files";
             Deferred.return ()
           | Some processor_path -> Async_shell.run processor_path [ "-D"; output_file ]
         in
         return ())
  ;;

  let select_pid () =
    if force supports_fzf
    then (
      let deselect_pid_args pid =
        let pid = Pid.to_string pid in
        [ "--ppid"; pid; "-p"; pid; "--deselect" ]
      in
      (* There are no Linux APIs, or OCaml libraries that I've found, for enumerating
       running processes. The [ps] command uses the /proc/ filesystem and is much easier
       than walking the /proc/ system and filtering ourselves. *)
      let process_lines =
        [ [ "x"; "-w"; "--no-headers" ]
        ; [ "-o"; "pid,args" ]
          (* If running as root, allow tracing all processes, including those owned
             by non-root users.

             Hide kernel threads (PID 2 and children), since though we can trace them in
             theory, in practice they don't have their image under /proc/$pid/exe, which
             we currently rely on. *)
        ; (if Core_unix.geteuid () = 0 then deselect_pid_args (Pid.of_int 2) else [])
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
      ~readme:(fun () ->
        "=== examples ===\n\n\
         # Fuzzy-find to select a running process to trace the main thread of, \
         snapshotting at ^C or exit\n\
         magic-trace attach\n\n\
         # Fuzzy-find to select a running process and symbol to trigger on, snapshotting \
         the next time the symbol is called\n\
         magic-trace attach -trigger ?\n")
      (let%map_open.Command record_opt_fn = record_flags
       and decode_opts = decode_flags
       and debug_print_perf_commands = debug_print_perf_commands
       and pids =
         flag
           "-pid"
           (optional (Arg_type.comma_separated int))
           ~aliases:[ "-p" ]
           ~doc:
             "PID Processes to attach to as a comma separated list. Required if you \
              don't have the \"fzf\" application available in your PATH."
       in
       fun () ->
         let open Deferred.Or_error.Let_syntax in
         let%bind () = check_for_perf () in
         let%bind (pids : Pid.t list) =
           match pids with
           | None -> select_pid () |> Deferred.Or_error.map ~f:(fun pid -> [ pid ])
           | Some pids -> return (List.map ~f:Pid.of_int pids)
         in
         if List.contains_dup pids ~compare:Pid.compare
         then Deferred.Or_error.error_string "Duplicate PIDs were passed"
         else (
           (* Always use the head PID for locating triggers since only a single
              trigger can be passed currently. *)
           let executable =
             List.hd_exn pids
             |> fun pid -> Core_unix.readlink [%string "/proc/%{pid#Pid}/exe"]
           in
           record_opt_fn ~executable ~f:(fun opts ->
               let { Record_opts.executable; when_to_snapshot; collection_mode; _ } =
                 opts
               in
               let%bind elf = create_elf ~executable ~when_to_snapshot in
               let%bind range_symbols =
                 evaluate_trace_filter ~trace_filter:opts.trace_filter ~elf
               in
               let%bind () =
                 attach_and_record
                   opts
                   ~elf
                   ~debug_print_perf_commands
                   ~collection_mode
                   pids
               in
               let%bind.Deferred perf_maps = Perf_map.Table.load_by_pids pids in
               decode_to_trace
                 ~perf_maps
                 ?range_symbols
                 ~elf
                 ~trace_scope:opts.trace_scope
                 ~debug_print_perf_commands
                 ~record_dir:opts.record_dir
                 ~collection_mode
                 decode_opts)))
  ;;

  let decode_command =
    Command.async_or_error
      ~summary:"Converts perf-script output to a trace. (expert)"
      (let%map_open.Command record_dir = record_dir_flag required
       and trace_scope = Trace_scope.param
       and decode_opts = decode_flags
       and executable =
         flag
           "-executable"
           (required Filename_unix.arg_type)
           ~doc:"FILE Executable to extract debug symbols from."
       and perf_map_files =
         flag
           "-perf-map-file"
           (optional (Arg_type.comma_separated Filename_unix.arg_type))
           ~doc:"FILE for JITs, path to a perf map file, in /tmp/perf-PID.map"
       and collection_mode = Collection_mode.param
       and debug_print_perf_commands = debug_print_perf_commands in
       fun () ->
         (* Doesn't use create_elf because there's no need to check that the binary has symbols if
            we're trying to snapshot it. *)
         let elf = Elf.create executable in
         let%bind perf_maps =
           match perf_map_files with
           | None -> Deferred.return None
           | Some files ->
             Perf_map.Table.load_by_files files |> Deferred.map ~f:Option.some
         in
         decode_to_trace
           ?perf_maps
           ~elf
           ~trace_scope
           ~debug_print_perf_commands
           ~record_dir
           ~collection_mode
           decode_opts)
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
  let get_events_pipe ?range_symbols ~events () =
    let decode_events () =
      Deferred.Or_error.return
        { Decode_result.events = [ Pipe.of_list events ]
        ; close_result = Deferred.Or_error.return ()
        }
    in
    let%map events, _ =
      get_events_and_close_result ~decode_events ~range_symbols
      |> Deferred.Or_error.ok_exn
    in
    List.hd_exn events
  ;;

  let write_trace_from_events = write_trace_from_events ~print_events:false
end
