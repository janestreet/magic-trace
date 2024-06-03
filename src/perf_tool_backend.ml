open! Core
open! Async

(* PAGER=cat because perf spawns [less] if you get the arguments wrong, and that keeps the
   parent process alive even though it just failed. That, in turn, makes magic-trace stop
   responding to Ctrl+C. *)
let perf_env = `Extend [ "PAGER", "cat" ]

module Record_opts = struct
  type t =
    { multi_thread : bool
    ; full_execution : bool
    ; snapshot_size : Pow2_pages.t option
    ; callgraph_mode : Callgraph_mode.t option
    }

  let param =
    let%map_open.Command multi_thread =
      flag
        "-multi-thread"
        no_arg
        ~doc:
          "Records every thread of an executable, instead of only the thread whose TID \
           is equal to the process' PID.\n\
           Warning: this flag decreases the trace's lookback period because the kernel \
           divides snapshot buffer resources equally across all threads."
    and full_execution =
      flag
        "-full-execution"
        no_arg
        ~doc:
          "Record a program's full execution instead of using a snapshot ring buffer.\n\
           Warning: The trace grows at a rate of hundreds of megabytes per second. The \
           trace viewer may fail to load traces larger than 100M."
    and snapshot_size =
      Pow2_pages.optional_flag
        "-snapshot-size"
        ~doc:
          " Tunes the amount of data captured in a trace. Default: 4M if root or \
           perf_event_paranoid < 0, 256K otherwise. When running with sampling,  \
           defaults to 512K, but cannot be changed. For more info: \
           https://magic-trace.org/w/s"
    and callgraph_mode = Callgraph_mode.param in
    { multi_thread; full_execution; snapshot_size; callgraph_mode }
  ;;
end

let write_perf_dlfilter filename =
  let error = Deferred.Or_error.error_string "Unable to write [perf_dlfilter.so]." in
  try
    match Perf_dlfilter.read "perf_dlfilter.so" with
    | Some data ->
      Out_channel.write_all filename ~data;
      (* Otherwise this is written without executable permission. *)
      Core_unix.chmod filename ~perm:0o775 |> Deferred.Or_error.return
    | None -> error
  with
  | Sys_error _ -> error
;;

let perf_exit_to_or_error = function
  | Ok () | Error (`Signal _) -> Ok ()
  | Error (`Exit_non_zero n) -> Core_unix.Exit.of_code n |> Core_unix.Exit.or_error
;;

(* Same as [Caml.exit] but does not run at_exit handlers *)
external sys_exit : int -> 'a = "caml_sys_exit"

let perf_fork_exec ?env ~prog ~argv () =
  let pr_set_pdeathsig = Or_error.ok_exn Linux_ext.pr_set_pdeathsig in
  match Core_unix.fork () with
  | `In_the_child ->
    pr_set_pdeathsig Signal.kill;
    never_returns
      (try Core_unix.exec ?env ~prog ~argv () with
       | _ -> sys_exit 127)
  | `In_the_parent pid -> pid
;;

let max_sampling_frequency () =
  In_channel.read_all "/proc/sys/kernel/perf_event_max_sample_rate"
  |> String.rstrip (* Strip off newline *)
  |> Int.of_string
;;

module Recording = struct
  module Data = struct
    type t = { callgraph_mode : Callgraph_mode.t option } [@@deriving sexp]
  end

  type t =
    { pid : Pid.t
    ; when_to_snapshot : [ `at_exit of [ `sigint | `sigusr2 ] | `function_call | `never ]
    }

  let perf_selector_of_trace_scope : Trace_scope.t -> string = function
    | Userspace -> "u"
    | Kernel -> "k"
    | Userspace_and_kernel -> "uk"
  ;;

  let perf_intel_pt_config_of_timer_resolution
    ~capabilities
    (timer_resolution : Timer_resolution.t)
    =
    let timer_resolution =
      match
        ( timer_resolution
        , Perf_capabilities.(do_intersect capabilities configurable_psb_period) )
      with
      | (Normal | High), false ->
        Core.eprintf
          "Warning: This machine has an older generation processor, timing granularity \
           will be ~1us instead of ~10ns. Consider using a newer machine.\n\
           %!";
        Timer_resolution.Low
      | _, _ -> timer_resolution
    in
    match timer_resolution with
    | Low -> Or_error.return ""
    | Normal -> Or_error.return "cyc=1,cyc_thresh=1,mtc_period=0"
    | High -> Or_error.return "cyc=1,cyc_thresh=1,mtc_period=0,noretcomp=1"
    | Sample _ ->
      Or_error.error_string
        "[-timer-resolution Sample] can only be used in sampling mode. (Did you forget \
         [-sampling]?)"
    | Custom { cyc; cyc_thresh; mtc; mtc_period; noretcomp; psb_period } ->
      let make_config key = function
        | None -> None
        | Some value -> Some [%string "%{key}=%{value#Int}"]
      in
      [ make_config "cyc" (Option.map ~f:Bool.to_int cyc)
      ; make_config "cyc_thresh" cyc_thresh
      ; make_config "mtc" (Option.map ~f:Bool.to_int mtc)
      ; make_config "mtc_period" mtc_period
      ; make_config "noretcomp" (Option.map ~f:Bool.to_int noretcomp)
      ; make_config "psb_period" psb_period
      ]
      |> List.filter_opt
      |> String.concat ~sep:","
      |> Or_error.return
  ;;

  let perf_cycles_config_of_timer_resolution (timer_resolution : Timer_resolution.t) =
    match timer_resolution with
    | Low -> Or_error.return "freq=1000"
    | Normal -> Or_error.return "freq=10000"
    | High -> Or_error.return [%string "freq=%{max_sampling_frequency ()#Int}"]
    | Sample { freq } -> Or_error.return [%string "freq=%{freq#Int}"]
    | Custom _ ->
      Or_error.error_string
        "[-timer-resolution Custom] can only be used with Intel PT. (Are you running on \
         a physical Intel machine without [-sampling]?)"
  ;;

  let perf_config_of_extra_events ~selector extra_events =
    List.map
      extra_events
      ~f:(fun ({ when_to_sample; name; precision } : Collection_mode.Event.t) ->
        let precision_selector =
          match precision with
          | Arbitrary_skid -> ""
          | Constant_skid -> "p"
          | Request_zero_skid -> "pp"
          | Zero_skid -> "ppp"
          | Maximum_possible -> "P"
        in
        match when_to_sample with
        | Period period ->
          [%string
            "%{name#Collection_mode.Event.Name}/period=%{period#Int}/%{selector}%{precision_selector}"]
        | Frequency freq ->
          [%string
            "%{name#Collection_mode.Event.Name}/freq=%{freq#Int}/%{selector}%{precision_selector}"])
  ;;

  let perf_args_of_collection_mode
    ~capabilities
    ~timer_resolution
    ~trace_scope
    (collection_mode : Collection_mode.t)
    =
    let selector = perf_selector_of_trace_scope trace_scope in
    let%map.Or_error primary_event =
      match collection_mode with
      | Intel_processor_trace _ ->
        let%map.Or_error intel_pt_config =
          perf_intel_pt_config_of_timer_resolution ~capabilities timer_resolution
        in
        [%string "intel_pt/%{intel_pt_config}/%{selector}"]
      | Stacktrace_sampling _ ->
        let%map.Or_error cycles_config =
          perf_cycles_config_of_timer_resolution timer_resolution
        in
        [%string "cycles/%{cycles_config}/%{selector}"]
    in
    let extra_events =
      perf_config_of_extra_events ~selector (Collection_mode.extra_events collection_mode)
    in
    let arg_string = String.concat ~sep:"," (primary_event :: extra_events) in
    [ [%string "--event=%{arg_string}"] ]
  ;;

  let init_record_dir record_dir =
    Core_unix.mkdir_p record_dir;
    Sys.readdir record_dir
    |> Deferred.bind
         ~f:
           (Deferred.Array.iter ~how:`Sequential ~f:(fun file ->
              if String.is_prefix file ~prefix:"perf.data"
              then Sys.remove (record_dir ^/ file)
              else Deferred.return ()))
  ;;

  let attach_and_record
    { Record_opts.multi_thread; full_execution; snapshot_size; callgraph_mode }
    ~debug_print_perf_commands
    ~(subcommand : Subcommand.t)
    ~(when_to_snapshot : When_to_snapshot.t)
    ~(trace_scope : Trace_scope.t)
    ~multi_snapshot
    ~(timer_resolution : Timer_resolution.t)
    ~record_dir
    ~(collection_mode : Collection_mode.t)
    pids
    =
    let%bind () = init_record_dir record_dir in
    let%bind capabilities = Perf_capabilities.detect_exn () in
    let%bind.Deferred.Or_error () =
      match trace_scope, Perf_capabilities.(do_intersect capabilities kernel_tracing) with
      | Userspace, _ | _, true -> return (Ok ())
      | (Kernel | Userspace_and_kernel), false ->
        if not Env_vars.perf_is_privileged
        then
          Deferred.Or_error.error_string
            "magic-trace must be run as root in order to trace the kernel"
        else return (Ok ())
    in
    let perf_supports_snapshot_on_exit =
      Perf_capabilities.(do_intersect capabilities snapshot_on_exit)
    in
    (match when_to_snapshot, subcommand with
     | Magic_trace_or_the_application_terminates, Run ->
       if not perf_supports_snapshot_on_exit
       then
         printf
           "Warning: magic-trace will only be able to snapshot when magic-trace is \
            Ctrl+C'd, not when the application it's running ends. If that application \
            ends before magic-trace can snapshot it, the resulting trace will be empty. \
            The ability to snapshot when an application terminates was added to perf's \
            userspace tools in version 5.4. For more information, see:\n\
            https://github.com/janestreet/magic-trace/wiki/Supported-platforms,-programming-languages,-and-runtimes#supported-perf-versions\n\
            %!"
     | Application_calls_a_function _, _ | _, Attach -> ());
    (* CR-someday alamoreaux: [--per-thread] is an important argument here.
       However perf fails with an invalid argument to mmap if [--per-thread] is
       given as well as additional events to sample. Without [--per-thread], you
       can end up with traces have gaps in time if a process was switching
       between CPUs.

       We would allow this flag always if perf didn't crash. Even then, it might
       be worth having magic-trace potentially be able to handle / filter the
       trace better. *)
    let per_thread_opts =
      match Collection_mode.extra_events collection_mode with
      | [] -> [ "--per-thread" ]
      | _ -> []
    in
    let thread_opts =
      match multi_thread with
      | false -> List.concat [ per_thread_opts; [ "-t" ] ]
      | true -> [ "-p" ]
    in
    let pid_opt = [ List.map pids ~f:Pid.to_string |> String.concat ~sep:"," ] in
    let%bind.Deferred.Or_error selected_callgraph_mode =
      let open Deferred.Or_error.Let_syntax in
      match collection_mode with
      | Intel_processor_trace _ ->
        (match callgraph_mode with
         | None -> return None
         | Some _ ->
           Deferred.Or_error.error_string
             "[-callgraph-mode] is only configurable when running magic-trace with \
              sampling.")
      | Stacktrace_sampling _ ->
        (match
           ( callgraph_mode
           , Perf_capabilities.(do_intersect capabilities last_branch_record) )
         with
         (* We choose to default to dwarf if lbr is not available. This is
            because dwarf will work on any setup, while frame pointers requires
            compilation with [-fno-omit-frame-pointers]. Although decoding is
            slow and perf.data file sizes are larger. *)
         | None, false ->
           Core.eprintf
             "Warning: [-callgraph-mode] is defaulting to [Dwarf] which may have high \
              overhead and decoding time. For more info: https://magic-trace.org/w/b\n";
           return (Some Callgraph_mode.Dwarf)
         | None, true ->
           Core.eprintf
             "Warning: [-callgraph-mode] is defaulting to [Last_branch_record] which may \
              lose data and has limited callstack depth. For more info: \
              https://magic-trace.org/w/b\n";
           return (Some (Callgraph_mode.Last_branch_record { stitched = true }))
         | Some (Last_branch_record _), false ->
           Deferred.Or_error.error_string
             "[-callgraph-mode Last_branch_record] is only supported on an Intel machine \
              which supports LBR. Try passing [Frame_pointers] or [Dwarf] instead."
         | Some mode, false -> return (Some mode)
         | Some mode, true -> return (Some mode))
    in
    let%bind.Deferred.Or_error event_opts =
      perf_args_of_collection_mode
        ~capabilities
        ~timer_resolution
        ~trace_scope
        collection_mode
      |> Deferred.return
    in
    let kcore_opts =
      match
        collection_mode, trace_scope, Perf_capabilities.(do_intersect capabilities kcore)
      with
      | Intel_processor_trace _, Userspace, _ | Stacktrace_sampling _, _, _ -> []
      | Intel_processor_trace _, (Kernel | Userspace_and_kernel), true -> [ "--kcore" ]
      | Intel_processor_trace _, (Kernel | Userspace_and_kernel), false ->
        (* Strictly speaking, we could recreate tools/perf/perf-with-kcore.sh
           here instead of bailing. But that's tricky, and upgrading to a newer
           perf is easier. *)
        Core.eprintf
          "Warning: old perf version detected! perf userspace tools v5.5 contain an \
           important feature, kcore, that make decoding kernel traces more reliable. In \
           our experience, tracing the kernel mostly works without this feature, but you \
           may run into problems if you're trying to trace through self-modifying code \
           (the kernel may do this more than you think). Install a perf version >= 5.5 \
           to avoid this.\n\
           %!";
        []
    in
    let snapshot_size_opt =
      match snapshot_size, collection_mode with
      | Some snapshot_size, Intel_processor_trace _ ->
        [ [%string "-m,%{Pow2_pages.num_pages snapshot_size#Int}"] ]
      | Some _, Stacktrace_sampling _ ->
        Core.eprintf
          "Warning: -snapshot-size is ignored when not running with Intel PT.\n";
        []
      | None, Intel_processor_trace _ | None, Stacktrace_sampling _ -> []
    in
    let when_to_snapshot =
      if full_execution
      then `never
      else (
        match when_to_snapshot with
        | Magic_trace_or_the_application_terminates ->
          if perf_supports_snapshot_on_exit then `at_exit `sigint else `at_exit `sigusr2
        | Application_calls_a_function _ -> `function_call)
    in
    let snapshot_opt =
      match collection_mode with
      | Stacktrace_sampling _ -> []
      | Intel_processor_trace _ ->
        (match when_to_snapshot with
         | `never -> []
         | `at_exit `sigint -> [ "--snapshot=e" ]
         | `function_call | `at_exit `sigusr2 -> [ "--snapshot" ])
    in
    let overwrite_opts =
      match collection_mode, full_execution with
      | Stacktrace_sampling _, false -> [ "--overwrite" ]
      | Intel_processor_trace _, false | _, true -> []
    in
    let switch_opts =
      match multi_snapshot with
      | true -> [ "--switch-output=signal" ]
      | false -> []
    in
    let argv =
      List.concat
        [ [ "perf"; "record"; "-o"; record_dir ^/ "perf.data"; "--timestamp" ]
        ; event_opts
        ; overwrite_opts
        ; switch_opts
        ; thread_opts
        ; pid_opt
        ; snapshot_opt
        ; kcore_opts
        ; snapshot_size_opt
        ; Callgraph_mode.to_perf_record_args selected_callgraph_mode
        ]
    in
    if debug_print_perf_commands then Core.printf "%s\n%!" (String.concat ~sep:" " argv);
    (* Perf prints output we don't care about and --quiet doesn't work for some reason *)
    let perf_pid = perf_fork_exec ~env:perf_env ~prog:"perf" ~argv () in
    (* This detaches the perf process from our "process group" but not our session. This
       makes it so that when Ctrl-C is sent to magic_trace in the terminal to end an attach
       session, it doesn't also send SIGINT to the perf process, allowing us to send it a
       SIGUSR2 first to get it to capture a snapshot before exiting. *)
    Core_unix.setpgid ~of_:perf_pid ~to_:perf_pid;
    let%map () = Async.Clock_ns.after (Time_ns.Span.of_ms 500.0) in
    (* Check that the process hasn't failed after waiting, because there's no point pausing
       to do recording if we've already failed. *)
    let res = Core_unix.wait_nohang (`Pid perf_pid) in
    let%map.Or_error () =
      match res with
      | Some (_, exit) -> perf_exit_to_or_error exit
      | _ -> Ok ()
    in
    ( { pid = perf_pid; when_to_snapshot }
    , { Data.callgraph_mode = selected_callgraph_mode } )
  ;;

  let maybe_take_snapshot t ~source =
    let signal =
      match t.when_to_snapshot, source with
      (* [`never] only comes up in [-full-execution] mode. In that mode, perf always gives a
         complete trace; there's no snapshotting. *)
      | `never, _ -> None
      (* Do not snapshot at the end of a program if the user has set up a trigger symbol. *)
      | `function_call, `ctrl_c -> None
      (* This shouldn't happen unless there was a bug elsewhere. It would imply that a trigger
         symbol was hit when there is no trigger symbol configured. *)
      | `at_exit _, `function_call -> None
      (* Trigger symbol was hit, and we're configured to look for them. *)
      | `function_call, `function_call -> Some Signal.usr2
      (* Ctrl-C was hit, and we're configured to look for that. *)
      | `at_exit signal, `ctrl_c ->
        (* The actual signal to use varies depending on whether or not the user's version of perf
           supports snapshot-at-exit. *)
        Some
          (match signal with
           | `sigint -> Signal.int
           | `sigusr2 -> Signal.usr2)
    in
    match signal with
    | None -> ()
    | Some signal -> Signal_unix.send_i signal (`Pid t.pid)
  ;;

  let finish_recording t =
    Signal_unix.send_i Signal.term (`Pid t.pid);
    (* This should usually be a signal exit, but we don't really care, if it didn't
       produce a good perf.data file the next step will fail.

       [Monitor.try_with] because [waitpid] raises if perf exited before we get here. *)
    match%map.Deferred Monitor.try_with (fun () -> Async_unix.Unix.waitpid t.pid) with
    | Ok res -> perf_exit_to_or_error res
    | Error _exn -> Ok ()
  ;;
end

module Decode_opts = struct
  type t = unit

  let param = Command.Param.return ()
end

let decode_events
  ?perf_maps
  ?(filter_same_symbol_jumps = true)
  ~debug_print_perf_commands
  ~(recording_data : Recording.Data.t option)
  ~record_dir
  ~(collection_mode : Collection_mode.t)
  ()
  =
  let%bind capabilities = Perf_capabilities.detect_exn () in
  let%bind.Deferred.Or_error dlfilter_opts =
    match
      ( Perf_capabilities.(do_intersect capabilities dlfilter)
      , collection_mode
      , Env_vars.no_dlfilter || not filter_same_symbol_jumps )
    with
    | true, Intel_processor_trace _, false ->
      let filename = record_dir ^/ "perf_dlfilter.so" in
      let%map.Deferred.Or_error () = write_perf_dlfilter filename in
      [ "--dlfilter"; filename ]
    | false, _, _ | true, Stacktrace_sampling _, _ | true, Intel_processor_trace _, true
      -> Deferred.Or_error.return []
  in
  let%bind files =
    Sys.readdir record_dir
    >>| Array.to_list
    >>| List.filter ~f:(String.is_prefix ~prefix:"perf.data")
  in
  let%map result =
    Deferred.List.map files ~how:`Sequential ~f:(fun perf_data_file ->
      let itrace_opts =
        match collection_mode with
        | Intel_processor_trace _ -> [ "--itrace=bep" ]
        | Stacktrace_sampling _ -> []
      in
      let fields_opts =
        match collection_mode with
        | Intel_processor_trace _ ->
          [ "-F"; "pid,tid,time,flags,ip,addr,sym,symoff,synth,dso,event,period" ]
        | Stacktrace_sampling _ -> [ "-F"; "pid,tid,time,ip,sym,symoff,dso,event,period" ]
      in
      let args =
        List.concat
          [ [ "script"; "-i"; record_dir ^/ perf_data_file; "--ns" ]
          ; itrace_opts
          ; fields_opts
          ; dlfilter_opts
          ; Option.map recording_data ~f:(fun recording_data ->
              Callgraph_mode.to_perf_script_args recording_data.callgraph_mode)
            |> Option.value ~default:[]
          ]
      in
      if debug_print_perf_commands
      then Core.printf "perf %s\n%!" (String.concat ~sep:" " args);
      (* CR-someday tbrindus: this should be switched over to using
         [perf_fork_exec] to avoid the [perf script] process from outliving
         the parent. *)
      let%map perf_script_proc = Process.create_exn ~env:perf_env ~prog:"perf" ~args () in
      let line_pipe = Process.stdout perf_script_proc |> Reader.lines in
      don't_wait_for
        (Reader.transfer
           (Process.stderr perf_script_proc)
           (Writer.pipe (force Writer.stderr)));
      let events = Perf_decode.to_events ?perf_maps line_pipe in
      let close_result =
        let%map exit_or_signal = Process.wait perf_script_proc in
        perf_exit_to_or_error exit_or_signal
      in
      events, close_result)
  in
  let events = List.map result ~f:(fun (events, _close_result) -> events) in
  (* Force [close_result] to wait on [Pipe.t]s in order. *)
  let close_result =
    List.map result ~f:(fun (_events, close_result) -> close_result)
    |> Deferred.List.fold ~init:(Ok ()) ~f:(fun acc close_result ->
      let%bind.Deferred.Or_error () = close_result in
      Deferred.return acc)
  in
  Ok { Decode_result.events; close_result }
;;
