open! Core
open! Async
open! Magic_trace_lib.Trace.For_testing

include struct
  open Magic_trace_core
  module Decode_result = Decode_result
  module Event = Event
  module Symbol = Symbol
end

module Trace_helpers : sig
  val events : unit -> Event.t list
  val start_recording : unit -> unit
  val call : unit -> unit
  val add : Event.Kind.t -> int -> string -> unit
  val ret : unit -> unit
  val jmp : unit -> unit
end = struct
  let start_time = Time_ns.Span.of_int_ns 12345

  let thread : Event.Thread.t =
    { pid = Some (Pid.of_int 1234); tid = Some (Pid.of_int 456) }
  ;;

  let stack = Stack.create ()
  let events = Queue.create ()
  let cur_time = ref start_time
  let make_rng_array = [| 1; 2; 3; 4 |]
  let rng = ref (Random.State.make make_rng_array)

  let time () =
    (cur_time := Time_ns.Span.(!cur_time + of_int_ns (Random.State.int_incl !rng 0 100)));
    !cur_time
  ;;

  let addr () = Random.State.int64_incl !rng 0L 0x7fffffffffffL
  let offset () = Random.State.int_incl !rng 0 0x1000

  let symbol () =
    Symbol.From_perf
      (List.init (Random.State.int_incl !rng 1 10) ~f:(fun _ -> Random.State.ascii !rng)
      |> String.of_char_list)
  ;;

  let random_location () : Event.Location.t =
    { instruction_pointer = addr (); symbol = From_perf ""; symbol_offset = offset () }
  ;;

  let random_ok_event () : Event.Ok.t =
    { thread
    ; time = time ()
    ; trace_state_change = None
    ; kind = Some Call
    ; src = random_location ()
    ; dst = random_location ()
    }
  ;;

  let start_recording () = Queue.clear events

  let random_event' kind symbol : Event.t =
    let event = random_ok_event () in
    Ok { event with kind = Some kind; dst = { event.dst with symbol } }
  ;;

  let call () =
    let symbol = symbol () in
    Queue.enqueue events (random_event' Call symbol);
    Stack.push stack symbol
  ;;

  let add kind ns symbol =
    let time = Time_ns.Span.of_int_ns ns in
    let loc =
      { Event.Location.instruction_pointer = 0L
      ; symbol = From_perf symbol
      ; symbol_offset = 0
      }
    in
    Queue.enqueue
      events
      (Ok
         { thread
         ; time
         ; trace_state_change = None
         ; kind = Some kind
         ; src = loc
         ; dst = loc
         })
  ;;

  let ret () =
    let symbol =
      match Stack.pop stack with
      | Some symbol -> symbol
      | None -> symbol ()
    in
    Queue.enqueue events (random_event' Return symbol)
  ;;

  let jmp () =
    let symbol = symbol () in
    Queue.enqueue events (random_event' Jump symbol);
    ignore (Stack.pop stack : Symbol.t option);
    Stack.push stack symbol
  ;;

  (* Clear events and reset all mutable state in the module *)
  let events () =
    let ret = Queue.to_list events in
    Queue.clear events;
    Stack.clear stack;
    cur_time := start_time;
    rng := Random.State.make make_rng_array;
    ret
  ;;

  let () = ignore (events () : Event.t list)
end

module With = struct
  let bind with_ ~f = with_ f

  module Let_syntax = struct
    module Let_syntax = struct
      let bind = bind
    end
  end
end

let dump_using_file events =
  let decode_result = { Decode_result.events; close_result = return (Ok ()) } in
  let buf = Iobuf.create ~len:500_000 in
  let destination = Tracing_zero.Destinations.iobuf_destination buf in
  let writer = Tracing_zero.Writer.Expert.create ~destination () in
  let%bind or_error =
    write_trace_from_events ~trace_mode:Userspace writer [] decode_result
  in
  ok_exn or_error;
  let parser = Tracing.Parser.create (Iobuf.read_only buf) in
  while%bind_open.Result Ok true do
    let%bind.Result cur = Tracing.Parser.parse_next parser in
    (match cur with
    | Tick_initialization { ticks_per_second; base_time = _ } ->
      (* Elide [base_time], since it isn't stable. *)
      print_s [%message "Tick_initialization" (ticks_per_second : int)]
    | _ -> print_s [%sexp (cur : Tracing.Parser.Record.t)]);
    Result.return ()
  done
  |> [%sexp_of: (unit, Tracing.Parser.Parse_error.t) Result.t]
  |> print_s;
  return ()
;;

let%expect_test "random perfs" =
  let open Trace_helpers in
  let%bind.With _dirname = Expect_test_helpers_async.within_temp_dir in
  let generator =
    let open Quickcheck.Generator in
    let%map.Quickcheck.Generator calls =
      weighted_union
        [ 5., return start_recording; 30., return call; 30., return ret; 10., return jmp ]
      |> list_non_empty
    in
    List.iter calls ~f:(fun f -> f ());
    events ()
  in
  let dump_one seed =
    let events = Quickcheck.random_value ~seed:(`Deterministic seed) ~size:5 generator in
    dump_using_file (Pipe.of_list events)
  in
  let%bind () = dump_one "1" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value 1234/456))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value S))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value ""))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x663ee233c233)) (106 (String 105))))
      (event_type Duration_begin)))
    (Interned_string (index 108) (value "+d8;mv5\026j"))
    (Event
     ((timestamp 152ns) (thread 1) (category 107) (name 108)
      (arguments ((104 (Pointer 0x3ffaf4b9bc19)) (106 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 109) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 110) (value "\025J\015\018\023\018"))
    (Interned_string (index 111)
     (value "\025J\015\018\023\018 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 111)
      (arguments ((104 (Pointer 0x7daeabb33c37)) (106 (String 110))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 108) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 112) (value "_\025dd;?\\"))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 112)
      (arguments ((104 (Pointer 0xcb71f4a7934)) (106 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 110) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  let%bind () = dump_one "2" in
  [%expect
    {|
(Interned_string (index 1) (value process))
(Tick_initialization (ticks_per_second 1000000000))
(Interned_string (index 102) (value 1234/456))
(Process_name_change (name 102) (pid 1))
(Interned_string (index 103) (value main))
(Thread_name_change (name 103) (pid 1) (tid 2))
(Interned_thread (index 1)
 (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
(Interned_string (index 104) (value address))
(Interned_string (index 105) (value "\025J\015\018\023\018"))
(Interned_string (index 106) (value symbol))
(Interned_string (index 107)
 (value "\025J\015\018\023\018 [inferred start time]"))
(Interned_string (index 108) (value ""))
(Event
 ((timestamp 0s) (thread 1) (category 108) (name 107)
  (arguments ((104 (Pointer 0x7daeabb33c37)) (106 (String 105))))
  (event_type Duration_begin)))
(Event
 ((timestamp 0s) (thread 1) (category 108) (name 105) (arguments ())
  (event_type Duration_end)))
(Error No_more_words) |}];
  let%bind () = dump_one "3" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value 1234/456))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
    (Interned_string (index 104) (value "\025J\015\018\023\018"))
    (Interned_string (index 105) (value ""))
    (Event
     ((timestamp 100ns) (thread 1) (category 105) (name 104) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 106) (value address))
    (Interned_string (index 107) (value S))
    (Interned_string (index 108) (value symbol))
    (Event
     ((timestamp 100ns) (thread 1) (category 105) (name 107)
      (arguments ((106 (Pointer 0x663ee233c233)) (108 (String 107))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 109) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 110)
     (value "\025J\015\018\023\018 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 110)
      (arguments ((106 (Pointer 0x7daeabb33c37)) (108 (String 104))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value "+d8;mv5\026j"))
    (Event
     ((timestamp 152ns) (thread 1) (category 105) (name 111)
      (arguments ((106 (Pointer 0x3ffaf4b9bc19)) (108 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 152ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 152ns) (thread 1) (category 105) (name 107) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  let%bind () = dump_one "4" in
  [%expect
    {|
(Interned_string (index 1) (value process))
(Tick_initialization (ticks_per_second 1000000000))
(Interned_string (index 102) (value 1234/456))
(Process_name_change (name 102) (pid 1))
(Interned_string (index 103) (value main))
(Thread_name_change (name 103) (pid 1) (tid 2))
(Interned_thread (index 1)
 (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
(Interned_string (index 104) (value address))
(Interned_string (index 105) (value S))
(Interned_string (index 106) (value symbol))
(Interned_string (index 107) (value ""))
(Event
 ((timestamp 100ns) (thread 1) (category 107) (name 105)
  (arguments ((104 (Pointer 0x663ee233c233)) (106 (String 105))))
  (event_type Duration_begin)))
(Event
 ((timestamp 147ns) (thread 1) (category 107) (name 105) (arguments ())
  (event_type Duration_end)))
(Interned_string (index 108) (value "\025J\015\018\023\018"))
(Event
 ((timestamp 147ns) (thread 1) (category 107) (name 108) (arguments ())
  (event_type Duration_end)))
(Event
 ((timestamp 147ns) (thread 1) (category 107) (name 105)
  (arguments ((104 (Pointer 0x3e26ad26f4ea)) (106 (String 105))))
  (event_type Duration_begin)))
(Event
 ((timestamp 202ns) (thread 1) (category 107) (name 105) (arguments ())
  (event_type Duration_end)))
(Interned_string (index 109) (value "\025dd;?\\&"))
(Event
 ((timestamp 237ns) (thread 1) (category 107) (name 109)
  (arguments ((104 (Pointer 0x1e4d335982f9)) (106 (String 109))))
  (event_type Duration_begin)))
(Interned_string (index 110)
 (value "\025J\015\018\023\018 [inferred start time]"))
(Event
 ((timestamp 0s) (thread 1) (category 107) (name 110)
  (arguments ((104 (Pointer 0x6f066a246864)) (106 (String 108))))
  (event_type Duration_begin)))
(Event
 ((timestamp 0s) (thread 1) (category 107) (name 108)
  (arguments ((104 (Pointer 0x7daeabb33c37)) (106 (String 108))))
  (event_type Duration_begin)))
(Interned_string (index 111) (value "GGCP!p\015"))
(Event
 ((timestamp 274ns) (thread 1) (category 107) (name 111)
  (arguments ((104 (Pointer 0x66a5ef2d0303)) (106 (String 111))))
  (event_type Duration_begin)))
(Event
 ((timestamp 274ns) (thread 1) (category 107) (name 111) (arguments ())
  (event_type Duration_end)))
(Event
 ((timestamp 274ns) (thread 1) (category 107) (name 109) (arguments ())
  (event_type Duration_end)))
(Event
 ((timestamp 274ns) (thread 1) (category 107) (name 108) (arguments ())
  (event_type Duration_end)))
(Error No_more_words) |}];
  return ()
;;

let%expect_test "with initial returns" =
  let%bind.With _dirname = Expect_test_helpers_async.within_temp_dir in
  let events =
    Trace_helpers.(
      ret ();
      ret ();
      ret ();
      ret ();
      call ();
      call ();
      ret ();
      jmp ();
      ret ();
      ret ();
      ret ();
      events ())
  in
  let%bind () = dump_using_file (Pipe.of_list events) in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value 1234/456))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
    (Interned_string (index 104) (value "\025J\015\018\023\018"))
    (Interned_string (index 105) (value ""))
    (Event
     ((timestamp 100ns) (thread 1) (category 105) (name 104) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 106) (value S))
    (Event
     ((timestamp 152ns) (thread 1) (category 105) (name 106) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 107) (value "+d8;mv5\026j"))
    (Event
     ((timestamp 185ns) (thread 1) (category 105) (name 107) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 108) (value address))
    (Interned_string (index 109) (value GGCP!p))
    (Interned_string (index 110) (value symbol))
    (Event
     ((timestamp 222ns) (thread 1) (category 105) (name 109)
      (arguments ((108 (Pointer 0x66a5ef2d0303)) (110 (String 109))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value "\031q\0212\002\016"))
    (Event
     ((timestamp 319ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Pointer 0x1ad09e985c3)) (110 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 109) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Pointer 0x48db129b7fa)) (110 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 365ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 112) (value I))
    (Event
     ((timestamp 365ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Pointer 0x60c10fa613cc)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 113) (value "_\025dd;?\\"))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 113) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Pointer 0x43e592cf2b67)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 521ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 114) (value ";|\025K?\029A\025"))
    (Interned_string (index 115)
     (value ";|\025K?\029A\025 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 115)
      (arguments ((108 (Pointer 0x4bafaf95a3ed)) (110 (String 114))))
      (event_type Duration_begin)))
    (Interned_string (index 116) (value "N8\016$>"))
    (Interned_string (index 117) (value "N8\016$> [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 117)
      (arguments ((108 (Pointer 0x63cc6c84106a)) (110 (String 116))))
      (event_type Duration_begin)))
    (Interned_string (index 118) (value "_\025dd;?\\ [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 118)
      (arguments ((108 (Pointer 0xcb71f4a7934)) (110 (String 113))))
      (event_type Duration_begin)))
    (Interned_string (index 119) (value "+d8;mv5\026j [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 119)
      (arguments ((108 (Pointer 0x3ffaf4b9bc19)) (110 (String 107))))
      (event_type Duration_begin)))
    (Interned_string (index 120) (value "S [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 120)
      (arguments ((108 (Pointer 0x663ee233c233)) (110 (String 106))))
      (event_type Duration_begin)))
    (Interned_string (index 121) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 121) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 122)
     (value "\025J\015\018\023\018 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 122)
      (arguments ((108 (Pointer 0x7daeabb33c37)) (110 (String 104))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 562ns) (thread 1) (category 105) (name 116) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 562ns) (thread 1) (category 105) (name 114) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  return ()
;;

let%expect_test "time batch spreading" =
  let%bind.With _dirname = Expect_test_helpers_async.within_temp_dir in
  let events =
    Trace_helpers.(
      add Call 0 "main";
      (* Calls should get proportional time, returns should get none *)
      add Call 1 "sub";
      add Return 1 "main";
      add Call 1 "sub";
      add Return 1 "main";
      (* more events than nanosecond, first one should get allocated no duration *)
      add Call 100 "sub";
      add Call 100 "sub";
      add Call 100 "sub";
      add Call 100 "sub";
      add Call 103 "sub";
      add Return 103 "sub";
      events ())
  in
  let%bind () = dump_using_file (Pipe.of_list events) in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value 1234/456))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value sub))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value ""))
    (Event
     ((timestamp 1ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 50ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 50ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 101ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 102ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 103)
      (arguments ((104 (Pointer 0x0)) (106 (String 103))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 103) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  return ()
;;

let%expect_test "enqueing events at start" =
  let%bind.With _dirname = Expect_test_helpers_async.within_temp_dir in
  let events =
    Trace_helpers.(
      (* Tests double-ended queuing of events starting at time zero, with normal events
         starting at time zero done last in forward order, and inferred events in
         reverse order before the forward events. *)
      add Return 0 "fn1";
      add Call 0 "fn2";
      add Call 0 "fn3";
      add Return 1 "fn2";
      add Return 2 "fn1";
      add Return 3 "fn0";
      events ())
  in
  let%bind () = dump_using_file (Pipe.of_list events) in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value 1234/456))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
    (Interned_string (index 104) (value fn3))
    (Interned_string (index 105) (value ""))
    (Event
     ((timestamp 1ns) (thread 1) (category 105) (name 104) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 106) (value fn2))
    (Event
     ((timestamp 2ns) (thread 1) (category 105) (name 106) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 107) (value address))
    (Interned_string (index 108) (value fn0))
    (Interned_string (index 109) (value symbol))
    (Interned_string (index 110) (value "fn0 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 110)
      (arguments ((107 (Pointer 0x0)) (109 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 111) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 112) (value fn1))
    (Interned_string (index 113) (value "fn1 [inferred start time]"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 113)
      (arguments ((107 (Pointer 0x0)) (109 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 106)
      (arguments ((107 (Pointer 0x0)) (109 (String 106))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 104)
      (arguments ((107 (Pointer 0x0)) (109 (String 104))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 3ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 3ns) (thread 1) (category 105) (name 108) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  return ()
;;

let%expect_test "get debug information from ELF" =
  let elf = Magic_trace_core.Elf.create "sample-targets/ocaml-raise/sample.exe" in
  let debug_table =
    Magic_trace_core.Elf.addr_table (Option.value_exn elf)
    |> Hashtbl.filter ~f:(fun info ->
           match info.filename with
           | Some "sample.ml" -> true
           | _ -> false)
  in
  let raise_after_col =
    Hashtbl.filter_map debug_table ~f:(fun info ->
        if info.line = 5 then Some info.col else None)
    |> Hashtbl.data
    |> List.hd_exn
  in
  (* Uncomment this to print the actual table, but we can't leave it in the tree as an
     expect test because different compiler versions and build parameters will cause the
     output to change. *)
  (* print_s [%sexp (debug_table : Magic_trace_lib.Address_info.t Int.Table.t)]; *)
  (* We should hopefully be able to rely on the [function] of [raise_after] having
     an entry with the correct column. *)
  Expect_test_helpers_base.require_equal [%here] (module Int) raise_after_col 22;
  [%expect {| |}];
  return ()
;;
