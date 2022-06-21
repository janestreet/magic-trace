open! Core
open! Async
open! Import

(* PAGER=cat because perf spawns [less] if you get the arguments wrong, and that keeps the
   parent process alive even though it just failed. That, in turn, makes magic-trace stop
   responding to Ctrl+C. *)
let perf_env = `Extend [ "PAGER", "cat" ]

module Record_opts = struct
  type t =
    { multi_thread : bool
    ; full_execution : bool
    ; snapshot_size : Pow2_pages.t option
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
           perf_event_paranoid < 0, 256K otherwise. For more info visit \
           https://magic-trace.org/w/s"
    in
    { multi_thread; full_execution; snapshot_size }
  ;;
end

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

module Recording = struct
  type t =
    { pid : Pid.t
    ; when_to_snapshot : [ `at_exit of [ `sigint | `sigusr2 ] | `function_call | `never ]
    }

  let perf_selector_of_trace_scope : Trace_scope.t -> string = function
    | Userspace -> "u"
    | Kernel -> "k"
    | Userspace_and_kernel -> "uk"
  ;;

  let perf_intel_pt_config_of_timer_resolution : Timer_resolution.t -> string = function
    | Low -> ""
    | Normal -> "cyc=1,cyc_thresh=1,mtc_period=0"
    | High -> "cyc=1,cyc_thresh=1,mtc_period=0,noretcomp=1"
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
  ;;

  let attach_and_record
      { Record_opts.multi_thread; full_execution; snapshot_size }
      ~debug_print_perf_commands
      ~(subcommand : Subcommand.t)
      ~(when_to_snapshot : When_to_snapshot.t)
      ~(trace_scope : Trace_scope.t)
      ~(timer_resolution : Timer_resolution.t)
      ~record_dir
      pids
    =
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
           The ability to snapshot when an application teminates was added to perf's \
           userspace tools in version 5.4. For more information, see:\n\
           https://github.com/janestreet/magic-trace/wiki/Supported-platforms,-programming-languages,-and-runtimes#supported-perf-versions\n\
           %!"
    | Application_calls_a_function _, _ | _, Attach -> ());
    let thread_opts =
      match multi_thread with
      | false -> [ "--per-thread"; "-t" ]
      | true -> [ "-p" ]
    in
    let pid_opt = [ List.map pids ~f:Pid.to_string |> String.concat ~sep:"," ] in
    let ev_arg =
      let timer_resolution : Timer_resolution.t =
        match
          ( timer_resolution
          , Perf_capabilities.(do_intersect capabilities configurable_psb_period) )
        with
        | (Normal | High), false ->
          Core.eprintf
            "Warning: This machine has an older generation processor, timing granularity \
             will be ~1us instead of ~10ns. Consider using a newer machine.\n\
             %!";
          Low
        | _, _ -> timer_resolution
      in
      let intel_pt_config = perf_intel_pt_config_of_timer_resolution timer_resolution in
      let selector = perf_selector_of_trace_scope trace_scope in
      [%string "--event=intel_pt/%{intel_pt_config}/%{selector}"]
    in
    let kcore_opts =
      match trace_scope, Perf_capabilities.(do_intersect capabilities kcore) with
      | Userspace, _ -> []
      | (Kernel | Userspace_and_kernel), true -> [ "--kcore" ]
      | (Kernel | Userspace_and_kernel), false ->
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
      match snapshot_size with
      | None -> []
      | Some snapshot_size -> [ [%string "-m,%{Pow2_pages.num_pages snapshot_size#Int}"] ]
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
      match when_to_snapshot with
      | `never -> []
      | `at_exit `sigint -> [ "--snapshot=e" ]
      | `function_call | `at_exit `sigusr2 -> [ "--snapshot" ]
    in
    let argv =
      List.concat
        [ [ "perf"; "record"; "-o"; record_dir ^/ "perf.data"; ev_arg; "--timestamp" ]
        ; thread_opts
        ; pid_opt
        ; snapshot_opt
        ; kcore_opts
        ; snapshot_size_opt
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
    { pid = perf_pid; when_to_snapshot }
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
    (* This should usually be a signal exit, but we don't really care, if it didn't produce
     a good perf.data file the next step will fail. *)
    let%map (res : Core_unix.Exit_or_signal.t) = Async_unix.Unix.waitpid t.pid in
    perf_exit_to_or_error res
  ;;
end

module Decode_opts = struct
  type t = unit

  let param = Command.Param.return ()
end

let report_itraces = "bep"
let report_fields = "pid,tid,time,flags,ip,addr,sym,symoff,synth,dso"

let decode_events ?perf_maps ~debug_print_perf_commands ~record_dir () =
  let args =
    [ "script"
    ; "-i"
    ; record_dir ^/ "perf.data"
    ; "--ns"
    ; [%string "--itrace=%{report_itraces}"]
    ; "-F"
    ; report_fields
    ]
  in
  if debug_print_perf_commands
  then Core.printf "perf %s\n%!" (String.concat ~sep:" " args);
  (* CR-someday tbrindus: this should be switched over to using [perf_fork_exec] to avoid
     the [perf script] process from outliving the parent. *)
  let%bind perf_script_proc = Process.create_exn ~env:perf_env ~prog:"perf" ~args () in
  let line_pipe = Process.stdout perf_script_proc |> Reader.lines in
  don't_wait_for
    (Reader.transfer
       (Process.stderr perf_script_proc)
       (Writer.pipe (force Writer.stderr)));
  let events =
    (* Every route of filtering on streams in an async way seems to be deprecated,
       including converting to pipes which says that the stream creation should be
       switched to a pipe creation. Changing Async_shell is out-of-scope, and I also
       can't see a reason why filter_map would lead to memory leaks. *)
    Pipe.map line_pipe ~f:(Perf_decode.to_event ?perf_maps) |> Pipe.filter_map ~f:Fn.id
  in
  let close_result =
    let%map exit_or_signal = Process.wait perf_script_proc in
    perf_exit_to_or_error exit_or_signal
  in
  Ok { Decode_result.events; close_result } |> Deferred.return
;;
