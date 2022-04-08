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
           perf_event_paranoid < 0, 256K otherwise. More info: magic-trace.org/w/s"
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
    { can_snapshot : bool
    ; pid : Pid.t
    }

  let perf_selector_of_trace_mode : Trace_mode.t -> string = function
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
      ~(when_to_snapshot : When_to_snapshot.t)
      ~(trace_mode : Trace_mode.t)
      ~(timer_resolution : Timer_resolution.t)
      ~record_dir
      pid
    =
    let%bind capabilities = Perf_capabilities.detect_exn () in
    let%bind.Deferred.Or_error () =
      match trace_mode, Perf_capabilities.(do_intersect capabilities kernel_tracing) with
      | Userspace, _ | _, true -> return (Ok ())
      | (Kernel | Userspace_and_kernel), false ->
        Deferred.Or_error.error_string
          "magic-trace must be run as root in order to trace the kernel"
    in
    let thread_opts =
      match multi_thread with
      | false -> [ "--per-thread"; "-t" ]
      | true -> [ "-p" ]
    in
    let ev_arg =
      let timer_resolution : Timer_resolution.t =
        match
          ( timer_resolution
          , Perf_capabilities.(do_intersect capabilities configurable_psb_period) )
        with
        | (Normal | High), false ->
          Core.eprintf
            "[Warning: This machine has an older generation processor, timing \
             granularity will be ~1us instead of ~10ns. Consider using a newer machine.]\n\
             %!";
          Low
        | _, _ -> timer_resolution
      in
      let intel_pt_config = perf_intel_pt_config_of_timer_resolution timer_resolution in
      let selector = perf_selector_of_trace_mode trace_mode in
      [%string "--event=intel_pt/%{intel_pt_config}/%{selector}"]
    in
    let kcore_opts =
      match trace_mode, Perf_capabilities.(do_intersect capabilities kcore) with
      | Userspace, _ -> []
      | (Kernel | Userspace_and_kernel), true -> [ "--kcore" ]
      | (Kernel | Userspace_and_kernel), false ->
        (* Strictly speaking, we could recreate tools/perf/perf-with-kcore.sh
           here instead of bailing. But that's tricky, and upgrading to a newer
           perf is easier. *)
        Core.eprintf
          "[Warning: old perf version detected! perf userspace tools v5.5 contain an \
           important feature, kcore, that make decoding kernel traces more reliable. In \
           our experience, tracing the kernel mostly works without this feature, but you \
           may run into problems if you're trying to trace through self-modifying code \
           (the kernel may do this more than you think). Install a perf version >= 5.5 \
           to avoid this.]\n\
           %!";
        []
    in
    let snapshot_size_opt =
      match snapshot_size with
      | None -> []
      | Some snapshot_size -> [ [%string "-m,%{Pow2_pages.num_pages snapshot_size#Int}"] ]
    in
    let pid_opt = [ Pid.to_int pid |> Int.to_string ] in
    let snapshot_opt =
      if full_execution
      then []
      else (
        match when_to_snapshot with
        | Magic_trace_or_the_application_terminates -> [ "--snapshot=e" ]
        | Application_calls_a_function _ -> [ "--snapshot" ])
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
    { can_snapshot = not full_execution; pid = perf_pid }
  ;;

  let take_snapshot { pid; can_snapshot } =
    if can_snapshot
    then Signal_unix.send_i Signal.int (`Pid pid)
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
end

module Decode_opts = struct
  type t = unit

  let param = Command.Param.return ()
end

module Perf_line = struct
  let report_itraces = "b"
  let report_fields = "pid,tid,time,flags,ip,addr,sym,symoff"

  let saturating_sub_i64 a b =
    match Int64.(to_int (a - b)) with
    | None -> Int.max_value
    | Some offset -> offset
  ;;

  let line_re =
    Re.Perl.re
      {|^ *([0-9]+)/([0-9]+) +([0-9]+).([0-9]+): +(call|return|tr strt|syscall|sysret|hw int|iret|tr end|tr strt tr end|tr end  (?:call|return|syscall|sysret|iret)|jmp|jcc) +([0-9a-f]+) (.*) => +([0-9a-f]+) (.*)$|}
    |> Re.compile
  ;;

  let symbol_and_offset_re = Re.Posix.re {|^(.*)\+(0x[0-9a-f]+)$|} |> Re.compile

  let to_event line ~(perf_map : Perf_map.t option) : Event.t =
    try
      match Re.Group.all (Re.exec line_re line) with
      | [| _
         ; pid
         ; tid
         ; time_hi
         ; time_lo
         ; kind
         ; src_instruction_pointer
         ; src_symbol_and_offset
         ; dst_instruction_pointer
         ; dst_symbol_and_offset
        |] ->
        let pid = Int.of_string pid in
        let tid = Int.of_string tid in
        let time_lo =
          (* In practice, [time_lo] seems to always be 9 decimal places, but it seems good to guard
             against other possibilities. *)
          let num_decimal_places = String.length time_lo in
          match Ordering.of_int (Int.compare num_decimal_places 9) with
          | Less -> Int.of_string time_lo * Int.pow 10 (9 - num_decimal_places)
          | Equal -> Int.of_string time_lo
          | Greater -> Int.of_string (String.prefix time_lo 9)
        in
        let time_hi = Int.of_string time_hi in
        let int64_of_hex_string str =
          try Scanf.sscanf str "%Lx" Fn.id with
          | Scanf.Scan_failure _ | End_of_file -> 0L
        in
        let src_instruction_pointer = int64_of_hex_string src_instruction_pointer in
        let dst_instruction_pointer = int64_of_hex_string dst_instruction_pointer in
        let parse_symbol_and_offset str ~addr =
          match Re.Group.all (Re.exec symbol_and_offset_re str) with
          | [| _; symbol; offset |] -> Symbol.From_perf symbol, Int.Hex.of_string offset
          | _ | (exception _) ->
            let failed = Symbol.Unknown, 0 in
            (match perf_map with
            | None -> failed
            | Some perf_map ->
              (match Perf_map.symbol perf_map ~addr with
              | None -> failed
              | Some location ->
                (* It's strange that perf isn't resolving these symbols. It says on the tin that
                   it supports perf map files! *)
                let offset = saturating_sub_i64 addr location.start_addr in
                From_perf_map location, offset))
        in
        let src_symbol, src_symbol_offset =
          parse_symbol_and_offset src_symbol_and_offset ~addr:src_instruction_pointer
        in
        let dst_symbol, dst_symbol_offset =
          parse_symbol_and_offset dst_symbol_and_offset ~addr:dst_instruction_pointer
        in
        { thread =
            { pid = (if pid = 0 then None else Some (Pid.of_int pid))
            ; tid = (if tid = 0 then None else Some (Pid.of_int tid))
            }
        ; time = time_lo + (time_hi * 1_000_000_000) |> Time_ns.Span.of_int_ns
        ; kind =
            (match String.strip kind with
            | "call" -> Call
            | "return" -> Return
            | "jmp" -> Jump
            | "jcc" -> Jump
            | "syscall" -> Syscall
            | "hw int" -> Hardware_interrupt
            | "iret" -> Iret
            | "sysret" -> Sysret
            | "tr strt" -> Start
            | "tr end" -> End None
            | "tr end  call" -> End Call
            | "tr end  return" -> End Return
            | "tr end  syscall" -> End Syscall
            | "tr end  iret" -> End Iret
            | "tr end  sysret" -> End Sysret
            (* "tr strt tr end" happens when someone `go run`s ./demo/demo.go. But that trace is
               pretty broken for other reasons, so it's hard to say if this is truly necessary.
               Regardless, it's slightly more user friendly to show a broken trace instead of
               crashing here. *)
            | "tr strt tr end" -> Jump
            | kind -> raise_s [%message "unrecognized perf event" (kind : string)])
        ; src =
            { instruction_pointer = src_instruction_pointer
            ; symbol = src_symbol
            ; symbol_offset = src_symbol_offset
            }
        ; dst =
            { instruction_pointer = dst_instruction_pointer
            ; symbol = dst_symbol
            ; symbol_offset = dst_symbol_offset
            }
        }
      | results ->
        raise_s
          [%message
            "Regex of expected perf output did not match." (results : string array)]
    with
    | exn ->
      raise_s
        [%message
          "BUG: exception raised while parsing perf output. Please report this to \
           https://github.com/janestreet/magic-trace/issues/"
            (exn : exn)
            ~perf_output:(line : string)]
  ;;

  let%test_module _ =
    (module struct
      open Core

      let check s = to_event s ~perf_map:None |> [%sexp_of: Event.t] |> print_s

      let%expect_test "C symbol" =
        check
          {| 25375/25375 4509191.343298468:   call                     7f6fce0b71f4 __clock_gettime+0x24 =>     7ffd193838e0 __vdso_clock_gettime+0x0|};
        [%expect
          {|
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (kind Call)
           (src
            ((instruction_pointer 0x7f6fce0b71f4) (symbol (From_perf __clock_gettime))
             (symbol_offset 0x24)))
           (dst
            ((instruction_pointer 0x7ffd193838e0)
             (symbol (From_perf __vdso_clock_gettime)) (symbol_offset 0x0)))) |}]
      ;;

      let%expect_test "C symbol trace start" =
        check
          {| 25375/25375 4509191.343298468:   tr strt                             0 [unknown] =>     7f6fce0b71d0 __clock_gettime+0x0|};
        [%expect
          {|
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (kind Start)
           (src ((instruction_pointer 0x0) (symbol Unknown) (symbol_offset 0x0)))
           (dst
            ((instruction_pointer 0x7f6fce0b71d0) (symbol (From_perf __clock_gettime))
             (symbol_offset 0x0)))) |}]
      ;;

      let%expect_test "C++ symbol" =
        check
          {| 7166/7166  4512623.871133092:   call                           9bc6db a::B<a::C, a::D<a::E>, a::F, a::F, G::H, a::I>::run+0x1eb =>           9f68b0 J::K<int, std::string>+0x0|};
        [%expect
          {|
          ((thread ((pid (7166)) (tid (7166)))) (time 52d5h30m23.871133092s)
           (kind Call)
           (src
            ((instruction_pointer 0x9bc6db)
             (symbol (From_perf "a::B<a::C, a::D<a::E>, a::F, a::F, G::H, a::I>::run"))
             (symbol_offset 0x1eb)))
           (dst
            ((instruction_pointer 0x9f68b0)
             (symbol (From_perf "J::K<int, std::string>")) (symbol_offset 0x0)))) |}]
      ;;

      let%expect_test "OCaml symbol" =
        check
          {|2017001/2017001 761439.053336670:   call                     56234f77576b Base.Comparable.=_2352+0xb =>     56234f4bc7a0 caml_apply2+0x0|};
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (kind Call)
           (src
            ((instruction_pointer 0x56234f77576b)
             (symbol (From_perf Base.Comparable.=_2352)) (symbol_offset 0xb)))
           (dst
            ((instruction_pointer 0x56234f4bc7a0) (symbol (From_perf caml_apply2))
             (symbol_offset 0x0)))) |}]
      ;;

      (* CR-someday wduff: Leaving this concrete example here for when we support this. See my
         comment above as well.

         {[
           let%expect_test "Unknown Go symbol" =
           check
               {|2118573/2118573 770614.599007116:   tr strt tr end                      0 [unknown] =>           4591e1 [unknown]|};
             [%expect]
           ;;
         ]}
      *)

      let%expect_test "manufactured example 1" =
        check
          {|2017001/2017001 761439.053336670:   call                     56234f77576b x => +0xb =>     56234f4bc7a0 caml_apply2+0x0|};
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (kind Call)
           (src
            ((instruction_pointer 0x56234f77576b) (symbol (From_perf "x => "))
             (symbol_offset 0xb)))
           (dst
            ((instruction_pointer 0x56234f4bc7a0) (symbol (From_perf caml_apply2))
             (symbol_offset 0x0)))) |}]
      ;;

      let%expect_test "manufactured example 2" =
        check
          {|2017001/2017001 761439.053336670:   call                     56234f77576b x => +0xb =>     56234f4bc7a0 => +0x0|};
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (kind Call)
           (src
            ((instruction_pointer 0x56234f77576b) (symbol (From_perf "x => "))
             (symbol_offset 0xb)))
           (dst
            ((instruction_pointer 0x56234f4bc7a0) (symbol (From_perf "=> "))
             (symbol_offset 0x0)))) |}]
      ;;

      let%expect_test "manufactured example 3" =
        check
          {|2017001/2017001 761439.053336670:   call                     56234f77576b + +0xb =>     56234f4bc7a0 caml_apply2+0x0|};
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (kind Call)
           (src
            ((instruction_pointer 0x56234f77576b) (symbol (From_perf "+ "))
             (symbol_offset 0xb)))
           (dst
            ((instruction_pointer 0x56234f4bc7a0) (symbol (From_perf caml_apply2))
             (symbol_offset 0x0)))) |}]
      ;;
    end)
  ;;
end

let decode_events () ~debug_print_perf_commands ~record_dir ~perf_map =
  let args =
    [ "script"
    ; "-i"
    ; record_dir ^/ "perf.data"
    ; "--ns"
    ; [%string "--itrace=%{Perf_line.report_itraces}"]
    ; "-F"
    ; Perf_line.report_fields
    ]
  in
  if debug_print_perf_commands
  then Core.printf "perf %s\n%!" (String.concat ~sep:" " args);
  (* CR-someday tbrindus: this should be switched over to using [perf_fork_exec] to avoid
     the [perf script] process from outliving the parent. *)
  let%map perf_script_proc =
    Process.create_exn ~env:perf_env ~prog:"perf" ~working_dir:record_dir ~args ()
  in
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
    Pipe.map line_pipe ~f:(Perf_line.to_event ~perf_map)
  in
  let close_result =
    let%map exit_or_signal = Process.wait perf_script_proc in
    perf_exit_to_or_error exit_or_signal
  in
  Ok { Decode_result.events; close_result }
;;
