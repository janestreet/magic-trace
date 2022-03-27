open! Core
open! Async
open! Import

let debug_perf_commands = false

module Record_opts = struct
  type t =
    { multi_thread : bool
    ; full_execution : bool
    }

  let param =
    let%map_open.Command multi_thread =
      flag "-multi-thread" no_arg ~doc:"record multiple threads"
    and full_execution =
      flag "-full-execution" no_arg ~doc:"record full program execution"
    in
    { multi_thread; full_execution }
  ;;
end

module Recording = struct
  type t =
    { can_snapshot : bool
    ; pid : Pid.t
    }

  let perf_exit_to_or_error = function
    | Ok () | Error (`Signal _) -> Ok ()
    | Error (`Exit_non_zero n) -> Core_unix.Exit.of_code n |> Core_unix.Exit.or_error
  ;;

  let attach_and_record { Record_opts.multi_thread; full_execution } ~record_dir pid =
    let%bind capabilities = Perf_capabilities.detect_exn () in
    let thread_opts =
      match multi_thread with
      | false -> [ "--per-thread"; "-t" ]
      | true -> [ "-p" ]
    in
    let ev_arg =
      if Perf_capabilities.(do_intersect capabilities configurable_psb_period)
      then
        (* Using Intel Processor Trace with the highest possible granularity. *)
        "--event=intel_pt/cyc=1,cyc_thresh=1,mtc_period=0/u"
      else (
        Core.eprintf
          "[Warning: This machine has an older generation processor, timing granularity \
           will be ~1us instead of ~10ns. Consider using a newer machine.]\n\
           %!";
        "--event=intel_pt//u")
    in
    let argv =
      [ "perf"; "record"; "-o"; record_dir ^/ "perf.data"; ev_arg; "--timestamp" ]
      @ thread_opts
      @ [ Pid.to_int pid |> Int.to_string ]
      @ if full_execution then [] else [ "--snapshot" ]
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
end

module Decode_opts = struct
  type t = unit

  let param = Command.Param.return ()
end

module Perf_line = struct
  let report_itraces = "b"
  let report_fields = "pid,tid,time,flags,ip,addr,sym,symoff"

  let line_re =
    Re.Posix.re
      {|^ *([0-9]+)/([0-9]+) +([0-9]+).([0-9]+): +(call|return|tr strt|tr end|tr strt tr end|tr end  call|tr end  return|tr end  syscall|jmp|jcc) +([0-9a-f]+) (.*) => +([0-9a-f]+) (.*)$|}
    |> Re.compile
  ;;

  let symbol_and_offset_re = Re.Posix.re {|^(.*)\+(0x[0-9a-f]+)$|} |> Re.compile

  let to_event line : Event.t =
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
        let parse_symbol_and_offset str =
          match Re.Group.all (Re.exec symbol_and_offset_re str) with
          | [| _; symbol; offset |] -> symbol, Int.Hex.of_string offset
          | _ | (exception _) -> "[unknown]", 0
        in
        let src_symbol, src_symbol_offset =
          parse_symbol_and_offset src_symbol_and_offset
        in
        let dst_symbol, dst_symbol_offset =
          parse_symbol_and_offset dst_symbol_and_offset
        in
        { thread =
            { pid = (if pid = 0 then None else Some (Pid.of_int pid))
            ; tid = (if tid = 0 then None else Some tid)
            }
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
            (* CR-someday wduff: I saw "tr strt tr end" in practice, but I'm not sure what we want
               to do with it. Calling it out redundantly here for now. *)
            | ("tr strt tr end" as kind) | kind ->
              raise_s [%message "unrecognized perf event" (kind : string)])
            (* CR-someday wduff: These names make a lot more sense to me than the names that were here
           before, but maybe I'm missing some context. We should either change the names in
           [Event.t], or change them here, or something in between. That said, it seems best to
           separate figuring out the names from the present improvements. *)
        ; addr = dst_instruction_pointer
        ; symbol = dst_symbol
        ; offset = dst_symbol_offset
        ; ip = src_instruction_pointer
        ; ip_symbol = src_symbol
        ; ip_offset = src_symbol_offset
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

      let%expect_test "C symbol" =
        to_event
          {| 25375/25375 4509191.343298468:   call                     7f6fce0b71f4 __clock_gettime+0x24 =>     7ffd193838e0 __vdso_clock_gettime+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (addr 0x7ffd193838e0) (kind Call) (symbol __vdso_clock_gettime) (offset 0x0)
           (ip 0x7f6fce0b71f4) (ip_symbol __clock_gettime) (ip_offset 0x24)) |}]
      ;;

      let%expect_test "C symbol trace start" =
        to_event
          {| 25375/25375 4509191.343298468:   tr strt                             0 [unknown] =>     7f6fce0b71d0 __clock_gettime+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (addr 0x7f6fce0b71d0) (kind Start) (symbol __clock_gettime) (offset 0x0)
           (ip 0x0) (ip_symbol [unknown]) (ip_offset 0x0)) |}]
      ;;

      let%expect_test "C++ symbol" =
        to_event
          {| 7166/7166  4512623.871133092:   call                           9bc6db a::B<a::C, a::D<a::E>, a::F, a::F, G::H, a::I>::run+0x1eb =>           9f68b0 J::K<int, std::string>+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (7166)) (tid (7166)))) (time 52d5h30m23.871133092s)
           (addr 0x9f68b0) (kind Call) (symbol "J::K<int, std::string>") (offset 0x0)
           (ip 0x9bc6db)
           (ip_symbol "a::B<a::C, a::D<a::E>, a::F, a::F, G::H, a::I>::run")
           (ip_offset 0x1eb)) |}]
      ;;

      let%expect_test "OCaml symbol" =
        to_event
          {|2017001/2017001 761439.053336670:   call                     56234f77576b Base.Comparable.=_2352+0xb =>     56234f4bc7a0 caml_apply2+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (addr 0x56234f4bc7a0) (kind Call) (symbol caml_apply2) (offset 0x0)
           (ip 0x56234f77576b) (ip_symbol Base.Comparable.=_2352) (ip_offset 0xb)) |}]
      ;;

      (* CR-someday wduff: Leaving this concrete example here for when we support this. See my
         comment above as well.

         {[
           let%expect_test "Unknown Go symbol" =
             to_event
               {|2118573/2118573 770614.599007116:   tr strt tr end                      0 [unknown] =>           4591e1 [unknown]|}
             |> [%sexp_of: Event.t]
             |> print_s;
             [%expect]
           ;;
         ]}
      *)

      let%expect_test "manufactured example 1" =
        to_event
          {|2017001/2017001 761439.053336670:   call                     56234f77576b x => +0xb =>     56234f4bc7a0 caml_apply2+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (addr 0x56234f4bc7a0) (kind Call) (symbol caml_apply2) (offset 0x0)
           (ip 0x56234f77576b) (ip_symbol "x => ") (ip_offset 0xb)) |}]
      ;;

      let%expect_test "manufactured example 2" =
        to_event
          {|2017001/2017001 761439.053336670:   call                     56234f77576b x => +0xb =>     56234f4bc7a0 => +0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (addr 0x56234f4bc7a0) (kind Call) (symbol "=> ") (offset 0x0)
           (ip 0x56234f77576b) (ip_symbol "x => ") (ip_offset 0xb)) |}]
      ;;

      let%expect_test "manufactured example 3" =
        to_event
          {|2017001/2017001 761439.053336670:   call                     56234f77576b + +0xb =>     56234f4bc7a0 caml_apply2+0x0|}
        |> [%sexp_of: Event.t]
        |> print_s;
        [%expect
          {|
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (addr 0x56234f4bc7a0) (kind Call) (symbol caml_apply2) (offset 0x0)
           (ip 0x56234f77576b) (ip_symbol "+ ") (ip_offset 0xb)) |}]
      ;;
    end)
  ;;
end

let decode_events () ~record_dir =
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
