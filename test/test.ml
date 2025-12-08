open! Core
open! Async
open! Magic_trace_lib.Trace.For_testing

include struct
  open Magic_trace_lib
  module Decode_result = Decode_result
  module Event = Event
  module Symbol = Symbol
  module Trace_filter = Trace_filter
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
  let unknown = Symbol.From_perf "unknown"
  let loc symbol = { Event.Location.instruction_pointer = 0L; symbol; symbol_offset = 0 }

  let symbol () =
    Symbol.From_perf
      (List.init (Random.State.int_incl !rng 1 10) ~f:(fun _ -> Random.State.ascii !rng)
       |> String.of_char_list)
  ;;

  let random_location ?symbol () : Event.Location.t =
    { instruction_pointer = addr ()
    ; symbol = Option.value symbol ~default:(Symbol.From_perf "")
    ; symbol_offset = offset ()
    }
  ;;

  let random_ok_event ?kind ?symbol () : Event.Ok.t =
    { thread
    ; time = time ()
    ; data =
        Trace
          { trace_state_change = None
          ; kind = Some (Option.value kind ~default:Event.Kind.Call)
          ; src = random_location ()
          ; dst = random_location ?symbol ()
          }
    ; in_transaction = false
    }
  ;;

  let start_recording () = Queue.clear events
  let random_event' kind symbol : Event.t = Ok (random_ok_event ~kind ~symbol ())

  let call () =
    let symbol = symbol () in
    Queue.enqueue events (random_event' Call symbol);
    Stack.push stack symbol
  ;;

  let add kind ns symbol =
    let time = Time_ns.Span.of_int_ns ns in
    let symbol = Symbol.From_perf symbol in
    let dst = loc symbol in
    let src =
      match kind with
      | Event.Kind.Call ->
        let src = Option.value (Stack.top stack) ~default:unknown in
        Stack.push stack symbol;
        loc src
      | Return -> Option.value (Stack.pop stack) ~default:unknown |> loc
      | _ -> loc symbol
    in
    Queue.enqueue
      events
      (Ok
         { thread
         ; time
         ; data = Trace { trace_state_change = None; kind = Some kind; src; dst }
         ; in_transaction = false
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

let dump_using_file ?range_symbols events =
  let%bind events = get_events_pipe ?range_symbols ~events () in
  let close_result = return (Ok ()) in
  let buf = Iobuf.create ~len:500_000 in
  let destination = Tracing_zero.Destinations.iobuf_destination buf in
  let writer = Tracing_zero.Writer.Expert.create ~destination () in
  let%bind or_error =
    write_trace_from_events
      ~debug_info:None
      ~trace_scope:Userspace
      ~events_writer:None
      ~writer:(Some writer)
      ~hits:[]
      ~events:[ events ]
      ~close_result
      ()
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
    dump_using_file events
  in
  let%bind () = dump_one "1" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value "+O\002B~h"))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value ""))
    (Event
     ((timestamp 13ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x38df7fb74073)) (106 (String 105))))
      (event_type Duration_begin)))
    (Interned_string (index 108) (value "\017c\004dl\\"))
    (Event
     ((timestamp 87ns) (thread 1) (category 107) (name 108)
      (arguments ((104 (Pointer 0x70b30bb76ae5)) (106 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 109) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 110) (value "\026/"))
    (Interned_string (index 111) (value true))
    (Interned_string (index 112) (value inferred_start_time))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 110)
      (arguments
       ((104 (Pointer 0xd39111cc0c)) (106 (String 110)) (112 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 166ns) (thread 1) (category 107) (name 108) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 113) (value "\0188\020"))
    (Event
     ((timestamp 166ns) (thread 1) (category 107) (name 113)
      (arguments ((104 (Pointer 0x4c43bd1036db)) (106 (String 113))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 166ns) (thread 1) (category 107) (name 113) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 166ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 166ns) (thread 1) (category 107) (name 110) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words)
    |}];
  let%bind () = dump_one "2" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value "\026/"))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value true))
    (Interned_string (index 108) (value inferred_start_time))
    (Interned_string (index 109) (value ""))
    (Event
     ((timestamp 0s) (thread 1) (category 109) (name 105)
      (arguments
       ((104 (Pointer 0xd39111cc0c)) (106 (String 105)) (108 (String 107))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 109) (name 105) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words)
    |}];
  let%bind () = dump_one "3" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value "\026/"))
    (Interned_string (index 105) (value ""))
    (Event
     ((timestamp 13ns) (thread 1) (category 105) (name 104) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 106) (value address))
    (Interned_string (index 107) (value "+O\002B~h"))
    (Interned_string (index 108) (value symbol))
    (Event
     ((timestamp 13ns) (thread 1) (category 105) (name 107)
      (arguments ((106 (Pointer 0x38df7fb74073)) (108 (String 107))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 109) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 110) (value true))
    (Interned_string (index 111) (value inferred_start_time))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 104)
      (arguments
       ((106 (Pointer 0xd39111cc0c)) (108 (String 104)) (111 (String 110))))
      (event_type Duration_begin)))
    (Interned_string (index 112) (value "\017c\004dl\\"))
    (Event
     ((timestamp 87ns) (thread 1) (category 105) (name 112)
      (arguments ((106 (Pointer 0x70b30bb76ae5)) (108 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 87ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 87ns) (thread 1) (category 105) (name 107) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words)
    |}];
  let%bind () = dump_one "4" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value "+O\002B~h"))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value ""))
    (Event
     ((timestamp 13ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x38df7fb74073)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 18ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 108) (value "\026/"))
    (Event
     ((timestamp 18ns) (thread 1) (category 107) (name 108) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 18ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Pointer 0x4b46c9ab792e)) (106 (String 105))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 68ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 109) (value "w7&\0188\020x\\"))
    (Event
     ((timestamp 78ns) (thread 1) (category 107) (name 109)
      (arguments ((104 (Pointer 0x76ae90948b21)) (106 (String 109))))
      (event_type Duration_begin)))
    (Interned_string (index 110) (value true))
    (Interned_string (index 111) (value inferred_start_time))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 108)
      (arguments
       ((104 (Pointer 0x68bf42fc6148)) (106 (String 108)) (111 (String 110))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 108)
      (arguments ((104 (Pointer 0xd39111cc0c)) (106 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 112) (value "\011X\024"))
    (Event
     ((timestamp 124ns) (thread 1) (category 107) (name 112)
      (arguments ((104 (Pointer 0x3bafd6d24276)) (106 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 124ns) (thread 1) (category 107) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 124ns) (thread 1) (category 107) (name 109) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 124ns) (thread 1) (category 107) (name 108) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words)
    |}];
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
  let%bind () = dump_using_file events in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value "\026/"))
    (Interned_string (index 105) (value ""))
    (Event
     ((timestamp 13ns) (thread 1) (category 105) (name 104) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 106) (value "+O\002B~h"))
    (Event
     ((timestamp 87ns) (thread 1) (category 105) (name 106) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 107) (value "\017c\004dl\\"))
    (Event
     ((timestamp 166ns) (thread 1) (category 105) (name 107) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 108) (value address))
    (Interned_string (index 109) (value "\011X\024\018I]"))
    (Interned_string (index 110) (value symbol))
    (Event
     ((timestamp 212ns) (thread 1) (category 105) (name 109)
      (arguments ((108 (Pointer 0x3bafd6d24276)) (110 (String 109))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value "\006\0287KS{5"))
    (Event
     ((timestamp 263ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Pointer 0x1ab97b79c3e9)) (110 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 290ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 290ns) (thread 1) (category 105) (name 109) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 290ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Pointer 0x4e875e8d5917)) (110 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 337ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 112) (value "\001/p:"))
    (Event
     ((timestamp 337ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Pointer 0x7d1910749b4d)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 396ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 113) (value "\0188\020"))
    (Event
     ((timestamp 396ns) (thread 1) (category 105) (name 113) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 396ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Pointer 0x3218dd4125e6)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 422ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 114) (value "\002s\b6t\031L&3"))
    (Interned_string (index 115) (value true))
    (Interned_string (index 116) (value inferred_start_time))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 114)
      (arguments
       ((108 (Pointer 0x1d23eb1c2889)) (110 (String 114)) (116 (String 115))))
      (event_type Duration_begin)))
    (Interned_string (index 117) (value "\015'p\011\004\027BM"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 117)
      (arguments
       ((108 (Pointer 0x668b6c8c3735)) (110 (String 117)) (116 (String 115))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 113)
      (arguments
       ((108 (Pointer 0x4c43bd1036db)) (110 (String 113)) (116 (String 115))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 107)
      (arguments
       ((108 (Pointer 0x70b30bb76ae5)) (110 (String 107)) (116 (String 115))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 106)
      (arguments
       ((108 (Pointer 0x38df7fb74073)) (110 (String 106)) (116 (String 115))))
      (event_type Duration_begin)))
    (Interned_string (index 118) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 118) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 104)
      (arguments
       ((108 (Pointer 0xd39111cc0c)) (110 (String 104)) (116 (String 115))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 470ns) (thread 1) (category 105) (name 117) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 470ns) (thread 1) (category 105) (name 114) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words)
    |}];
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
  let%bind () = dump_using_file events in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
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

let%expect_test "enqueuing events at start" =
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
  let%bind () = dump_using_file events in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
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
    (Interned_string (index 110) (value true))
    (Interned_string (index 111) (value inferred_start_time))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 108)
      (arguments ((107 (Pointer 0x0)) (109 (String 108)) (111 (String 110))))
      (event_type Duration_begin)))
    (Interned_string (index 112) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 112) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 113) (value fn1))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 113)
      (arguments ((107 (Pointer 0x0)) (109 (String 113)) (111 (String 110))))
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
     ((timestamp 3ns) (thread 1) (category 105) (name 113) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 3ns) (thread 1) (category 105) (name 108) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  return ()
;;

let%expect_test "filtered trace" =
  let%bind.With _dirname = Expect_test_helpers_async.within_temp_dir in
  let events =
    Trace_helpers.(
      add Call 0 "base_fn";
      add Call 1 "pre_fn";
      add Return 2 "base_fn";
      add Call 3 "container";
      add Call 4 "start_trigger";
      add Call 5 "fn0";
      add Return 6 "start_trigger";
      add Return 7 "container";
      add Call 8 "fn1";
      add Return 9 "container";
      add Return 10 "base_fn";
      add Call 11 "fn2";
      add Return 12 "base_fn";
      add Call 13 "stop_trigger";
      add Return 14 "base_fn";
      add Call 15 "post_fn";
      add Return 16 "base_fn";
      add Return 17 "outer";
      events ())
  in
  let%bind () =
    dump_using_file
      ~range_symbols:
        { Trace_filter.start_symbol = "start_trigger"; stop_symbol = "stop_trigger" }
      events
  in
  [%expect
    {|
    (Interned_string (index 1) (value process))
    (Tick_initialization (ticks_per_second 1000000000))
    (Interned_string (index 102) (value "[pid=1234] [tid=456]"))
    (Process_name_change (name 102) (pid 1))
    (Interned_string (index 103) (value main))
    (Thread_name_change (name 103) (pid 1) (tid 2))
    (Interned_thread (index 1)
     (value
      ((pid 1) (tid 2) (process_name ("[pid=1234] [tid=456]"))
       (thread_name (main)))))
    (Interned_string (index 104) (value address))
    (Interned_string (index 105) (value base_fn))
    (Interned_string (index 106) (value symbol))
    (Interned_string (index 107) (value true))
    (Interned_string (index 108) (value inferred_start_time))
    (Interned_string (index 109) (value ""))
    (Event
     ((timestamp 4ns) (thread 1) (category 109) (name 105)
      (arguments ((104 (Pointer 0x0)) (106 (String 105)) (108 (String 107))))
      (event_type Duration_begin)))
    (Interned_string (index 110) (value container))
    (Event
     ((timestamp 4ns) (thread 1) (category 109) (name 110)
      (arguments ((104 (Pointer 0x0)) (106 (String 110)) (108 (String 107))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value start_trigger))
    (Event
     ((timestamp 4ns) (thread 1) (category 109) (name 111)
      (arguments ((104 (Pointer 0x0)) (106 (String 111))))
      (event_type Duration_begin)))
    (Interned_string (index 112) (value fn0))
    (Event
     ((timestamp 5ns) (thread 1) (category 109) (name 112)
      (arguments ((104 (Pointer 0x0)) (106 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 6ns) (thread 1) (category 109) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 7ns) (thread 1) (category 109) (name 111) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 113) (value fn1))
    (Event
     ((timestamp 8ns) (thread 1) (category 109) (name 113)
      (arguments ((104 (Pointer 0x0)) (106 (String 113))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 9ns) (thread 1) (category 109) (name 113) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 10ns) (thread 1) (category 109) (name 110) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 114) (value fn2))
    (Event
     ((timestamp 11ns) (thread 1) (category 109) (name 114)
      (arguments ((104 (Pointer 0x0)) (106 (String 114))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 12ns) (thread 1) (category 109) (name 114) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 13ns) (thread 1) (category 109) (name 105) (arguments ())
      (event_type Duration_end)))
    (Error No_more_words) |}];
  return ()
;;

let%expect_test "get debug information from ELF" =
  let elf = Magic_trace_lib.Elf.create "sample-targets/ocaml-raise/sample.exe" in
  let debug_table =
    Magic_trace_lib.Elf.addr_table (Option.value_exn elf)
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
  Expect_test_helpers_base.require_equal (module Int) raise_after_col 22;
  [%expect {| |}];
  return ()
;;
