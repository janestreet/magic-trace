open! Core
open! Async
open! Import

let saturating_sub_i64 a b =
  match Int64.(to_int (a - b)) with
  | None -> Int.max_value
  | Some offset -> offset
;;

let perf_event_header_re =
  Re.Perl.re
    {|^ *([0-9]+)/([0-9]+) +([0-9]+)\.([0-9]+): +([0-9]+) +([a-z\-]+)(/[a-z=0-9]+)?(/[a-zA-Z]*)?:([a-zA-Z]+:)?(.*)$|}
  |> Re.compile
;;

let perf_extra_sampled_event_re =
  Re.Perl.re {|^ *([0-9]+) +([0-9a-f]+) (.*)$|} |> Re.compile
;;

let perf_callstack_entry_re = Re.Perl.re "^\t *([0-9a-f]+) (.*)$" |> Re.compile

let perf_branches_event_re =
  Re.Perl.re
    {|^ *(call|return|tr strt|syscall|sysret|hw int|iret|tr end|tr strt tr end|tr end  (?:call|return|syscall|sysret|iret)|jmp|jcc) +([0-9a-f]+) (.*) => +([0-9a-f]+) (.*)$|}
  |> Re.compile
;;

let perf_cbr_event_re =
  Re.Perl.re {|^ *([a-z ]*)? +cbr: +([0-9]+ +freq: +([0-9]+) MHz)?(.*)$|} |> Re.compile
;;

let trace_error_re =
  Re.Posix.re
    {|^ instruction trace error type [0-9]+ (time ([0-9]+)\.([0-9]+) )?cpu [\-0-9]+ pid ([\-0-9]+) tid ([\-0-9]+) ip (0x[0-9a-fA-F]+|0) code [0-9]+: (.*)$|}
  |> Re.compile
;;

let symbol_and_offset_re = Re.Perl.re {|^(.*)\+(0x[0-9a-f]+)\s+\(.*\)$|} |> Re.compile
let unknown_symbol_dso_re = Re.Perl.re {|^\[unknown\]\s+\((.*)\)|} |> Re.compile

type header =
  | Trace_error
  | Event of
      { thread : Event.Thread.t
      ; time : Time_ns.Span.t
      ; period : int
      ; event : [ `Branches | `Cbr | `Psb | `Cycles | `Branch_misses | `Cache_misses ]
      ; remaining_line : string
      }

let maybe_pid_of_string = function
  | "0" -> None
  | pid -> Some (Pid.of_string pid)
;;

let parse_time ~time_hi ~time_lo =
  let time_lo =
    (* In practice, [time_lo] seems to always be 9 decimal places, but it seems
       good to guard against other possibilities. *)
    let num_decimal_places = String.length time_lo in
    match Ordering.of_int (Int.compare num_decimal_places 9) with
    | Less -> Int.of_string time_lo * Int.pow 10 (9 - num_decimal_places)
    | Equal -> Int.of_string time_lo
    | Greater -> Int.of_string (String.prefix time_lo 9)
  in
  let time_hi = Int.of_string time_hi in
  time_lo + (time_hi * 1_000_000_000) |> Time_ns.Span.of_int_ns
;;

let parse_event_header line =
  if String.is_prefix line ~prefix:" instruction trace error"
  then Trace_error
  else (
    match Re.Group.all (Re.exec perf_event_header_re line) with
    | [| _
       ; pid
       ; tid
       ; time_hi
       ; time_lo
       ; period
       ; event_name
       ; _event_config
       ; _event_selector
       ; _selector
       ; remaining_line
      |] ->
      let pid = maybe_pid_of_string pid in
      let tid = maybe_pid_of_string tid in
      let time = parse_time ~time_hi ~time_lo in
      let period = Int.of_string period in
      let event =
        match event_name with
        | "branches" -> `Branches
        | "cbr" -> `Cbr
        | "psb" -> `Psb
        | "cycles" -> `Cycles
        | "branch-misses" -> `Branch_misses
        | "cache-misses" -> `Cache_misses
        | _ ->
          raise_s
            [%message
              "Unexpected event type when parsing perf output" (event_name : string)]
      in
      Event { thread = { pid; tid }; time; period; event; remaining_line }
    | results ->
      raise_s
        [%message
          "Regex of perf output did not match expected fields" (results : string array)])
;;

let parse_symbol_and_offset ?perf_maps pid str ~addr =
  match Re.Group.all (Re.exec symbol_and_offset_re str) with
  | [| _; symbol; offset |] ->
    Symbol.From_perf symbol, Util.int_of_hex_string ~remove_hex_prefix:true offset
  | _ | (exception _) ->
    let failed = Symbol.Unknown, 0 in
    (match perf_maps, pid with
     | None, _ | _, None ->
       (match Re.Group.all (Re.exec unknown_symbol_dso_re str) with
        | [| _; dso |] ->
          (* CR-someday tbrindus: ideally, we would subtract the DSO base offset
           from [offset] here. *)
          Symbol.From_perf [%string "[unknown @ %{addr#Int64.Hex} (%{dso})]"], 0
        | _ | (exception _) -> failed)
     | Some perf_map, Some pid ->
       (match Perf_map.Table.symbol ~pid perf_map ~addr with
        | None -> failed
        | Some location ->
          (* It's strange that perf isn't resolving these symbols. It says on the
           tin that it supports perf map files! *)
          let offset = saturating_sub_i64 addr location.start_addr in
          From_perf_map location, offset))
;;

let trace_error_to_event line : Event.Decode_error.t =
  match Re.Group.all (Re.exec trace_error_re line) with
  | [| _; _; time_hi; time_lo; pid; tid; ip; message |] ->
    let pid = maybe_pid_of_string pid in
    let tid = maybe_pid_of_string tid in
    let instruction_pointer =
      if String.( = ) ip "0"
      then None
      else Some (Util.int64_of_hex_string ~remove_hex_prefix:true ip)
    in
    let time =
      if String.is_empty time_hi && String.is_empty time_lo
      then Time_ns_unix.Span.Option.none
      else Time_ns_unix.Span.Option.some (parse_time ~time_hi ~time_lo)
    in
    { thread = { pid; tid }; instruction_pointer; message; time }
  | results ->
    raise_s
      [%message
        "Regex of trace error did not match expected fields" (results : string array)]
;;

let parse_perf_cbr_event thread time line : Event.t =
  match Re.Group.all (Re.exec perf_cbr_event_re line) with
  | [| _; _; _; freq; _ |] ->
    Ok { thread; time; data = Power { freq = Int.of_string freq } }
  | results ->
    raise_s
      [%message
        "Regex of perf cbr event did not match expected fields" (results : string array)]
;;

let parse_location ?perf_maps ~pid instruction_pointer symbol_and_offset
  : Event.Location.t
  =
  let instruction_pointer = Util.int64_of_hex_string instruction_pointer in
  let symbol, symbol_offset =
    parse_symbol_and_offset ?perf_maps pid symbol_and_offset ~addr:instruction_pointer
  in
  { instruction_pointer; symbol; symbol_offset }
;;

let parse_callstack_entry ?perf_maps (thread : Event.Thread.t) line : Event.Location.t =
  match Re.Group.all (Re.exec perf_callstack_entry_re line) with
  | [| _; instruction_pointer; symbol_and_offset |] ->
    parse_location ?perf_maps ~pid:thread.pid instruction_pointer symbol_and_offset
  | results ->
    raise_s
      [%message
        "perf output did not match expected regex when parsing callstack entry"
          (results : string array)]
;;

let parse_perf_cycles_event ?perf_maps (thread : Event.Thread.t) time lines : Event.t =
  let callstack =
    List.map lines ~f:(parse_callstack_entry ?perf_maps thread) |> List.rev
  in
  Ok { thread; time; data = Stacktrace_sample { callstack } }
;;

let parse_perf_branches_event ?perf_maps (thread : Event.Thread.t) time line : Event.t =
  match Re.Group.all (Re.exec perf_branches_event_re line) with
  | [| _
     ; kind
     ; src_instruction_pointer
     ; src_symbol_and_offset
     ; dst_instruction_pointer
     ; dst_symbol_and_offset
    |] ->
    let src_instruction_pointer = Util.int64_of_hex_string src_instruction_pointer in
    let dst_instruction_pointer = Util.int64_of_hex_string dst_instruction_pointer in
    let src_symbol, src_symbol_offset =
      parse_symbol_and_offset
        ?perf_maps
        thread.pid
        src_symbol_and_offset
        ~addr:src_instruction_pointer
    in
    let dst_symbol, dst_symbol_offset =
      parse_symbol_and_offset
        ?perf_maps
        thread.pid
        dst_symbol_and_offset
        ~addr:dst_instruction_pointer
    in
    let starts_trace, kind =
      match String.chop_prefix kind ~prefix:"tr strt" with
      | None -> false, kind
      | Some rest -> true, String.lstrip ~drop:Char.is_whitespace rest
    in
    let ends_trace, kind =
      match String.chop_prefix kind ~prefix:"tr end" with
      | None -> false, kind
      | Some rest -> true, String.lstrip ~drop:Char.is_whitespace rest
    in
    let trace_state_change : Trace_state_change.t option =
      match starts_trace, ends_trace with
      | true, false -> Some Start
      | false, true -> Some End
      | false, false
      (* "tr strt tr end" happens when someone `go run`s ./demo/demo.go. But
         that trace is pretty broken for other reasons, so it's hard to say if
         this is truly necessary. Regardless, it's slightly more user friendly
         to show a broken trace instead of crashing here. *)
      | true, true -> None
    in
    let kind : Event.Kind.t option =
      match String.strip kind with
      | "call" -> Some Call
      | "return" -> Some Return
      | "jmp" -> Some Jump
      | "jcc" -> Some Jump
      | "syscall" -> Some Syscall
      | "hw int" -> Some Hardware_interrupt
      | "iret" -> Some Iret
      | "sysret" -> Some Sysret
      | "" -> None
      | _ ->
        printf "Warning: skipping unrecognized perf output: %s\n%!" line;
        None
    in
    Ok
      { thread
      ; time
      ; data =
          Trace
            { trace_state_change
            ; kind
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
      }
  | results ->
    raise_s
      [%message "Regex of expected perf output did not match." (results : string array)]
;;

let parse_perf_extra_sampled_event
  ?perf_maps
  (thread : Event.Thread.t)
  time
  period
  line
  lines
  name
  : Event.t
  =
  let (location : Event.Location.t) =
    match lines with
    | [] ->
      (match Re.Group.all (Re.exec perf_extra_sampled_event_re line) with
       | [| _str; _; instruction_pointer; symbol_and_offset |] ->
         parse_location ?perf_maps ~pid:thread.pid instruction_pointer symbol_and_offset
       | results ->
         raise_s
           [%message
             "Regex of perf event did not match expected fields" (results : string array)])
    | lines -> List.hd_exn lines |> parse_callstack_entry ?perf_maps thread
  in
  Ok { thread; time; data = Event_sample { location; count = period; name } }
;;

let to_event ?perf_maps lines : Event.t option =
  try
    match lines with
    | first_line :: lines ->
      let header = parse_event_header first_line in
      (match header with
       | Trace_error -> Some (Error (trace_error_to_event first_line))
       | Event { thread; time; period; event; remaining_line } ->
         (match event with
          | `Branches ->
            Some (parse_perf_branches_event ?perf_maps thread time remaining_line)
          | `Cbr ->
            (* cbr (core-to-bus ratio) are events which show frequency changes. *)
            Some (parse_perf_cbr_event thread time remaining_line)
          | `Psb -> (* Ignore psb (packet stream boundary) packets *) None
          | `Cycles -> Some (parse_perf_cycles_event ?perf_maps thread time lines)
          | `Branch_misses ->
            Some
              (parse_perf_extra_sampled_event
                 ?perf_maps
                 thread
                 time
                 period
                 remaining_line
                 lines
                 Collection_mode.Event.Name.Branch_misses)
          | `Cache_misses ->
            Some
              (parse_perf_extra_sampled_event
                 ?perf_maps
                 thread
                 time
                 period
                 remaining_line
                 lines
                 Collection_mode.Event.Name.Cache_misses)))
    | [] -> raise_s [%message "Unexpected line while parsing perf output."]
  with
  | exn ->
    raise_s
      [%message
        "BUG: exception raised while parsing perf output. Please report this to \
         https://github.com/janestreet/magic-trace/issues/"
          (exn : exn)
          ~perf_output:(lines : string list)]
;;

let split_line_pipe pipe : string list Pipe.Reader.t =
  let reader, writer = Pipe.create () in
  don't_wait_for
    (let%bind acc =
       Pipe.fold pipe ~init:[] ~f:(fun acc line ->
         let should_acc = not String.(line = "") in
         let should_write =
           String.(line = "") || not (Char.equal (String.get line 0) '\t')
         in
         let%map () =
           if List.length acc > 0 && should_write
           then Pipe.write writer (List.rev acc)
           else Deferred.return ()
         in
         let prev_acc = if should_write then [] else acc in
         if should_acc then line :: prev_acc else prev_acc)
     in
     let%map () =
       if List.length acc > 0
       then Pipe.write writer (List.rev acc)
       else Deferred.return ()
     in
     Pipe.close writer);
  reader
;;

let to_events ?perf_maps pipe =
  let pipe = split_line_pipe pipe in
  (* Every route of filtering on streams in an async way seems to be deprecated,
     including converting to pipes which says that the stream creation should be
     switched to a pipe creation. Changing Async_shell is out-of-scope, and I also
     can't see a reason why filter_map would lead to memory leaks. *)
  Pipe.map pipe ~f:(to_event ?perf_maps) |> Pipe.filter_map ~f:Fn.id
;;

let%test_module _ =
  (module struct
    open Core

    let check s =
      to_event (String.split ~on:'\n' s) |> [%sexp_of: Event.t option] |> print_s
    ;;

    let%expect_test "C symbol" =
      check
        {| 25375/25375 4509191.343298468:                            1   branches:uH:   call                     7f6fce0b71f4 __clock_gettime+0x24 (foo.so) =>     7ffd193838e0 __vdso_clock_gettime+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (data (Trace (kind Call) (src 0x7f6fce0b71f4) (dst 0x7ffd193838e0)))))) |}]
    ;;

    let%expect_test "C symbol trace start" =
      check
        {| 25375/25375 4509191.343298468:                            1   branches:uH:   tr strt                             0 [unknown] (foo.so) =>     7f6fce0b71d0 __clock_gettime+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (25375)) (tid (25375)))) (time 52d4h33m11.343298468s)
           (data (Trace (trace_state_change Start) (src 0x0) (dst 0x7f6fce0b71d0)))))) |}]
    ;;

    let%expect_test "C++ symbol" =
      check
        {| 7166/7166  4512623.871133092:                            1   branches:uH:   call                           9bc6db a::B<a::C, a::D<a::E>, a::F, a::F, G::H, a::I>::run+0x1eb (foo.so) =>           9f68b0 J::K<int, std::string>+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (7166)) (tid (7166)))) (time 52d5h30m23.871133092s)
           (data (Trace (kind Call) (src 0x9bc6db) (dst 0x9f68b0)))))) |}]
    ;;

    let%expect_test "OCaml symbol" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b Base.Comparable.=_2352+0xb (foo.so) =>     56234f4bc7a0 caml_apply2+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    (* CR-someday wduff: Leaving this concrete example here for when we support this. See my
       comment above as well.

       {[
         let%expect_test "Unknown Go symbol" =
         check
           {|2118573/2118573 770614.599007116:                                branches:uH:   tr strt tr end                      0 [unknown] (foo.so) =>           4591e1 [unknown] (foo.so)|};
           [%expect]
         ;;
       ]}
      *)

    let%expect_test "manufactured example 1" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b x => +0xb (foo.so) =>     56234f4bc7a0 caml_apply2+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    let%expect_test "manufactured example 2" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b x => +0xb (foo.so) =>     56234f4bc7a0 => +0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    let%expect_test "manufactured example 3" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b + +0xb (foo.so) =>     56234f4bc7a0 caml_apply2+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    let%expect_test "unknown symbol in DSO" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b [unknown] (foo.so) =>     56234f4bc7a0 caml_apply2+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    let%expect_test "DSO with spaces in it" =
      check
        {|2017001/2017001 761439.053336670:                            1   branches:uH:   call                     56234f77576b [unknown] (this is a spaced dso.so) =>     56234f4bc7a0 caml_apply2+0x0 (foo.so)|};
      [%expect
        {|
        ((Ok
          ((thread ((pid (2017001)) (tid (2017001)))) (time 8d19h30m39.05333667s)
           (data (Trace (kind Call) (src 0x56234f77576b) (dst 0x56234f4bc7a0)))))) |}]
    ;;

    let%expect_test "decode error with a timestamp" =
      check
        " instruction trace error type 1 time 47170.086912826 cpu -1 pid 293415 tid \
         293415 ip 0x7ffff7327730 code 7: Overflow packet";
      [%expect
        {|
          ((Error
            ((thread ((pid (293415)) (tid (293415)))) (time (13h6m10.086912826s))
             (instruction_pointer (0x7ffff7327730)) (message "Overflow packet")))) |}]
    ;;

    let%expect_test "decode error without a timestamp" =
      check
        " instruction trace error type 1 cpu -1 pid 293415 tid 293415 ip 0x7ffff7327730 \
         code 7: Overflow packet";
      [%expect
        {|
          ((Error
            ((thread ((pid (293415)) (tid (293415)))) (time ())
             (instruction_pointer (0x7ffff7327730)) (message "Overflow packet")))) |}]
    ;;

    let%expect_test "lost trace data" =
      check
        " instruction trace error type 1 time 2651115.104731379 cpu -1 pid 1801680 tid \
         1801680 ip 0 code 8: Lost trace data";
      [%expect
        {|
          ((Error
            ((thread ((pid (1801680)) (tid (1801680)))) (time (30d16h25m15.104731379s))
             (instruction_pointer ()) (message "Lost trace data")))) |}]
    ;;

    let%expect_test "never-ending loop" =
      check
        " instruction trace error type 1 time 406036.830210719 cpu -1 pid 114362 tid \
         114362 ip 0xffffffffb0999ed5 code 10: Never-ending loop (refer perf config \
         intel-pt.max-loops)";
      [%expect
        {|
          ((Error
            ((thread ((pid (114362)) (tid (114362)))) (time (4d16h47m16.830210719s))
             (instruction_pointer (-0x4f66612b))
             (message "Never-ending loop (refer perf config intel-pt.max-loops)")))) |}]
    ;;

    let%expect_test "power event cbr" =
      check
        "2937048/2937048 448556.689322817:                                   1    \
         cbr:                        cbr: 46 freq: 4606 MHz (159%)                   \
         0                0 [unknown] ([unknown])";
      [%expect
        {|
        ((Ok
          ((thread ((pid (2937048)) (tid (2937048)))) (time 5d4h35m56.689322817s)
           (data (Power (freq 4606)))))) |}]
    ;;

    (* Perf seems to change spacing when frequency is small and our regex was
       crashing on this case. *)
    let%expect_test "cbr event with double spaces" =
      check
        "2420596/2420596 525062.244538101:          \
         1                                        cbr:   syscall              cbr:  8 \
         freq:  801 MHz ( 28%)                   0     7f77dc9f4646 __nanosleep+0x16 \
         (/usr/lib64/libc-2.28.so)";
      [%expect
        {|
        ((Ok
          ((thread ((pid (2420596)) (tid (2420596)))) (time 6d1h51m2.244538101s)
           (data (Power (freq 801)))))) |}]
    ;;

    let%expect_test "cbr event with tr end" =
      check
        "21302/21302 82318.700445693:         1           cbr:  tr end               \
         cbr: 45 freq: 4500 MHz (118%)                   0          5368e58 \
         __symbol+0x168 (/dev/foo.exe)";
      [%expect
        {|
        ((Ok
          ((thread ((pid (21302)) (tid (21302)))) (time 22h51m58.700445693s)
           (data (Power (freq 4500)))))) |}]
    ;;

    (* Expected [None] because we ignore these events currently. *)
    let%expect_test "power event psb offs" =
      check
        "2937048/2937048 448556.689403475:                             1          \
         psb:                        psb offs: 0x4be8                                \
         0     7f068fbfd330 mmap64+0x50 (/usr/lib64/ld-2.28.so)";
      [%expect {|
        () |}]
    ;;

    let%expect_test "sampled callstack" =
      check
        "2060126/2060126 178090.391624068:     555555 cycles:u:\n\
         \tffffffff97201100 [unknown] ([unknown])\n\
         \t7f9bd48c1d80 _dl_setup_hash+0x0 (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd48bd18f _dl_map_object_from_fd+0xb8f (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd48bf6b0 _dl_map_object+0x1e0 (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd48ca184 dl_open_worker_begin+0xa4 (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd44521a2 _dl_catch_exception+0x82 (/usr/lib64/libc-2.28.so)\n\
         \t7f9bd48c9ac2 dl_open_worker+0x32 (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd44521a2 _dl_catch_exception+0x82 (/usr/lib64/libc-2.28.so)\n\
         \t7f9bd48c9d0c _dl_open+0xac (/usr/lib64/ld-2.28.so)\n\
         \t7f9bd46ae1e8 dlopen_doit+0x58 (/usr/lib64/libdl-2.28.so)\n\
         \t7f9bd44521a2 _dl_catch_exception+0x82 (/usr/lib64/libc-2.28.so)\n\
         \t7f9bd445225e _dl_catch_error+0x2e (/usr/lib64/libc-2.28.so)\n\
         \t7f9bd46ae964 _dlerror_run+0x64 (/usr/lib64/libdl-2.28.so)\n\
         \t7f9bd46ae285 dlopen@@GLIBC_2.2.5+0x45 (/usr/lib64/libdl-2.28.so)\n\
         \t4008de main+0x87 (/home/demo)";
      [%expect
        {|
        ((Ok
          ((thread ((pid (2060126)) (tid (2060126)))) (time 2d1h28m10.391624068s)
           (data
            (Stacktrace_sample
             (callstack
              (0x4008de 0x7f9bd46ae285 0x7f9bd46ae964 0x7f9bd445225e 0x7f9bd44521a2
               0x7f9bd46ae1e8 0x7f9bd48c9d0c 0x7f9bd44521a2 0x7f9bd48c9ac2
               0x7f9bd44521a2 0x7f9bd48ca184 0x7f9bd48bf6b0 0x7f9bd48bd18f
               0x7f9bd48c1d80 -0x68dfef00))))))) |}]
    ;;

    let%expect_test "cache-misses event with ipt" =
      check
        "3871580/3871580 430720.265503976:         50                   \
         cache-misses/period=50/u:                                      0     \
         7fca9945c595 __sleep+0x55 (/usr/lib64/libc-2.28.so)";
      [%expect
        {|
        ((Ok
          ((thread ((pid (3871580)) (tid (3871580)))) (time 4d23h38m40.265503976s)
           (data
            (Event_sample (location 0x7fca9945c595) (count 50) (name Cache_misses)))))) |}]
    ;;

    let%expect_test "cache-misses event with sampling" =
      check
        "3871580/3871580 431043.387175119:         50 cache-misses/period=50/u: \n\
         \t7fca999481a0 _dl_unmap+0x0 (/usr/lib64/ld-2.28.so)\n\
         \t7fca999454cc _dl_close_worker+0x83c (/usr/lib64/ld-2.28.so)\n\
         \t7fca99945dbd _dl_close+0x2d (/usr/lib64/ld-2.28.so)\n\
         \t7fca994cc1a2 _dl_catch_exception+0x82 (/usr/lib64/libc-2.28.so)\n\
         \t7fca994cc25e _dl_catch_error+0x2e (/usr/lib64/libc-2.28.so)\n\
         \t7fca99728964 _dlerror_run+0x64 (/usr/lib64/libdl-2.28.so)\n\
         \t7fca99728313 dlclose+0x23 (/usr/lib64/libdl-2.28.so)\n\
         \t4009b7 main+0x160 (/usr/local/home/demo)\n";
      [%expect
        {|
        ((Ok
          ((thread ((pid (3871580)) (tid (3871580)))) (time 4d23h44m3.387175119s)
           (data
            (Event_sample (location 0x7fca999481a0) (count 50) (name Cache_misses)))))) |}]
    ;;

    let%expect_test "branch-misses event with ipt" =
      check
        "3871580/3871580 431228.526799230:         50                  \
         branch-misses/period=50/u:                                      0     \
         7fca99943c60 _dl_open+0x0 (/usr/lib64/ld-2.28.so)";
      [%expect
        {|
        ((Ok
          ((thread ((pid (3871580)) (tid (3871580)))) (time 4d23h47m8.52679923s)
           (data
            (Event_sample (location 0x7fca99943c60) (count 50) (name Branch_misses)))))) |}]
    ;;
  end)
;;

module For_testing = struct
  let to_event = to_event
  let split_line_pipe = split_line_pipe
end
