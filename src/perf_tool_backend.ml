open! Core
open! Async
open! Import

type record_opts =
  { multi_thread : bool
  ; full_execution : bool
  }

let record_param =
  let%map_open.Command multi_thread =
    flag "-multi-thread" no_arg ~doc:"record multiple threads"
  and full_execution =
    flag "-full-execution" no_arg ~doc:"record full program execution"
  in
  { multi_thread; full_execution }
;;

type recording =
  { can_snapshot : bool
  ; pid : Pid.t
  }

let debug_perf_commands = false

let perf_exit_to_or_error = function
  | Ok () | Error (`Signal _) -> Ok ()
  | Error (`Exit_non_zero n) -> Core_unix.Exit.of_code n |> Core_unix.Exit.or_error
;;

let supports_cyc () =
  let cyc_cap =
    In_channel.read_all "/sys/bus/event_source/devices/intel_pt/caps/psb_cyc"
  in
  let supports_cyc = String.( = ) cyc_cap "1\n" in
  if not supports_cyc
  then
    Core.eprintf
      "[Warning: This machine has an older generation processor, timing granularity will \
       be ~1us instead of ~10ns. Consider using a newer machine.]\n\
       %!";
  supports_cyc
;;

let attach_and_record { multi_thread; full_execution } ~record_dir ?filter pid =
  let opts =
    match filter with
    | None -> []
    | Some filter -> [ "--filter"; filter ]
  in
  let thread_opts =
    match multi_thread with
    | false -> [ "--per-thread"; "-t" ]
    | true -> [ "-p" ]
  in
  let ev_arg =
    if supports_cyc ()
    then
      (* Using Intel Processor Trace with the highest possible granularity. *)
      "--event=intel_pt/cyc=1,cyc_thresh=1,mtc_period=0/u"
    else "--event=intel_pt//u"
  in
  let argv =
    [ "perf"; "record"; "-o"; record_dir ^/ "perf.data"; ev_arg; "--timestamp" ]
    @ thread_opts
    @ [ Pid.to_int pid |> Int.to_string ]
    @ (if full_execution then [] else [ "--snapshot" ])
    @ opts
  in
  if debug_perf_commands then Core.printf "%s\n%!" (String.concat ~sep:" " argv);
  (* Perf prints output we don't care about and --quiet doesn't work for some reason *)
  let perf_pid = Core_unix.fork_exec ~prog:"perf" ~argv () in
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
  { can_snapshot = not full_execution; pid = perf_pid }
;;

let take_snapshot { pid; can_snapshot } =
  if can_snapshot
  then Signal_unix.send_i Signal.usr2 (`Pid pid)
  else Core.eprintf "[Warning: Snapshotting during a full-execution tracing]\n%!";
  Or_error.return ()
;;

let finish_recording { pid; _ } =
  Signal_unix.send_i Signal.term (`Pid pid);
  (* This should usually be a signal exit, but we don't really care, if it didn't produce
     a good perf.data file the next step will fail. *)
  let%map (res : Core_unix.Exit_or_signal.t) = Async_unix.Unix.waitpid pid in
  perf_exit_to_or_error res
;;

module Perf_line = struct
  let report_itraces = "b"
  let report_fields = "pid,tid,time,flags,addr,sym,symoff"

  let to_event line =
    Scanf.sscanf
      line
      " %d/%d %d.%d: %s@=> %x %s@$"
      (fun pid tid time_hi time_lo kind addr rest ->
        let symbol, offset =
          try Scanf.sscanf rest "%s@+0x%x" (fun symbol offset -> symbol, offset) with
          | Scanf.Scan_failure _ | End_of_file -> "[unknown]", 0
        in
        { Backend_intf.Event.thread = { pid = Pid.of_int pid; tid }
        ; time = time_lo + (time_hi * 1_000_000_000) |> Time_ns.Span.of_int_ns
        ; kind =
            (match String.strip kind with
            | "call" -> Call
            | "return" -> Return
            | "tr strt" -> Start
            | "tr end" -> End None
            | "tr end  call" -> End Call
            | "tr end  return" -> End Return
            | "tr end  syscall" -> End Syscall
            | "jmp" -> Jump
            | "jcc" -> Jump
            | kind ->
              raise_s [%message
                 "BUG: unrecognized perf event. Please report this to \
                  https://github.com/janestreet/magic-trace/issues/"
                   (kind : string)
                   ~unrecognized_perf_output:(line : string)])
        ; addr
        ; symbol
        ; offset
        })
  ;;
end

type decode_opts = unit

let decode_param = Command.Param.return ()

let decode_events () ~record_dir =
  let args =
    [ "script"
    ; "-i"
    ; "perf.data"
    ; "--ns"
    ; [%string "--itrace=%{Perf_line.report_itraces}"]
    ; "-F"
    ; Perf_line.report_fields
    ]
  in
  if debug_perf_commands then Core.printf "perf %s\n%!" (String.concat ~sep:" " args);
  let%map perf_script_proc =
    Process.create_exn ~prog:"perf" ~working_dir:record_dir ~args ()
  in
  let line_pipe = Process.stdout perf_script_proc |> Reader.lines in
  let event_pipe =
    (* Every route of filtering on streams in an async way seems to be deprecated,
       including converting to pipes which says that the stream creation should be
       switched to a pipe creation. Changing Async_shell is out-of-scope, and I also
       can't see a reason why filter_map would lead to memory leaks. *)
    Pipe.map line_pipe ~f:Perf_line.to_event
  in
  Ok event_pipe
;;
