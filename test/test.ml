open! Core
open! Async
open! Magic_trace_lib.Trace.For_testing
module Event = Magic_trace_core.Event

module Trace_helpers : sig
  val events : unit -> Event.t list
  val start_recording : unit -> unit
  val call : unit -> unit
  val add : Event.Kind.t -> int -> string -> unit
  val ret : unit -> unit
  val jmp : unit -> unit
end = struct
  let start_time = Time_ns.Span.of_int_ns 12345
  let thread : Event.Thread.t = { pid = Some (Pid.of_int 1234); tid = Some 456 }
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
    List.init (Random.State.int_incl !rng 1 10) ~f:(fun _ -> Random.State.ascii !rng)
    |> String.of_char_list
  ;;

  let random_event () : Event.t =
    { thread
    ; time = time ()
    ; kind = Call
    ; addr = addr ()
    ; symbol = ""
    ; offset = offset ()
    ; ip = addr ()
    ; ip_symbol = ""
    ; ip_offset = offset ()
    }
  ;;

  let start_recording () = Queue.clear events

  let call () =
    let symbol = symbol () in
    Queue.enqueue events { (random_event ()) with kind = Call; symbol };
    Stack.push stack symbol
  ;;

  let add kind ns symbol =
    let time = Time_ns.Span.of_int_ns ns in
    Queue.enqueue
      events
      { thread
      ; time
      ; kind
      ; symbol
      ; addr = 0L
      ; offset = 0
      ; ip = 0L
      ; ip_symbol = symbol
      ; ip_offset = 0
      }
  ;;

  let ret () =
    let symbol =
      match Stack.pop stack with
      | Some symbol -> symbol
      | None -> symbol ()
    in
    Queue.enqueue events { (random_event ()) with kind = Return; symbol }
  ;;

  let jmp () =
    let symbol = symbol () in
    Queue.enqueue events { (random_event ()) with kind = Call; symbol };
    ignore (Stack.pop stack : string option);
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
  let buf = Iobuf.create ~len:500_000 in
  let destination = Tracing_zero.Destinations.iobuf_destination buf in
  let writer = Tracing_zero.Writer.Expert.create ~destination () in
  let trace = Tracing.Trace.Expert.create ~base_time:None writer in
  let%bind () = write_trace_from_events ~trace_mode:Userspace trace [] events in
  Tracing.Trace.close trace;
  let parser = Tracing.Parser.create (Iobuf.read_only buf) in
  while%bind_open.Result Ok true do
    let%bind.Result cur = Tracing.Parser.parse_next parser in
    Result.return (print_s [%sexp (cur : Tracing.Parser.Record.t)])
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
      (arguments ((104 (Int 117693177829825)) (106 (String 105))))
      (event_type Duration_begin)))
    (Interned_string (index 108) (value "+d8;mv5\026j"))
    (Event
     ((timestamp 152ns) (thread 1) (category 107) (name 108)
      (arguments ((104 (Int 18056637561335)) (106 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value "_\025dd;?\\"))
    (Event
     ((timestamp 185ns) (thread 1) (category 107) (name 109)
      (arguments ((104 (Int 132616083027461)) (106 (String 109))))
      (event_type Duration_begin)))
    (Interned_string (index 110) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 110) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 111) (value "\025J\015\018\023\018"))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 111)
      (arguments ((104 (Int 78866027486094)) (106 (String 111))))
      (event_type Duration_begin)))
    (Error No_more_words) |}];
  let%bind () = dump_one "2" in
  [%expect
    {|
(Interned_string (index 1) (value process))
(Interned_string (index 102) (value 1234/456))
(Process_name_change (name 102) (pid 1))
(Interned_string (index 103) (value main))
(Thread_name_change (name 103) (pid 1) (tid 2))
(Interned_thread (index 1)
 (value ((pid 1) (tid 2) (process_name (1234/456)) (thread_name (main)))))
(Interned_string (index 104) (value address))
(Interned_string (index 105) (value "\025J\015\018\023\018"))
(Interned_string (index 106) (value symbol))
(Interned_string (index 107) (value ""))
(Event
 ((timestamp 0s) (thread 1) (category 107) (name 105)
  (arguments ((104 (Int 78866027486094)) (106 (String 105))))
  (event_type Duration_begin)))
(Error No_more_words) |}];
  let%bind () = dump_one "3" in
  [%expect
    {|
    (Interned_string (index 1) (value process))
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
      (arguments ((104 (Int 117693177829825)) (106 (String 105))))
      (event_type Duration_begin)))
    (Interned_string (index 108) (value "+d8;mv5\026j"))
    (Event
     ((timestamp 152ns) (thread 1) (category 107) (name 108)
      (arguments ((104 (Int 18056637561335)) (106 (String 108))))
      (event_type Duration_begin)))
    (Interned_string (index 109) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 109) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Interned_string (index 110) (value "\025J\015\018\023\018"))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 110)
      (arguments ((104 (Int 78866027486094)) (106 (String 110))))
      (event_type Duration_begin)))
    (Error No_more_words) |}];
  let%bind () = dump_one "4" in
  [%expect
    {|
(Interned_string (index 1) (value process))
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
  (arguments ((104 (Int 117693177829825)) (106 (String 105))))
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
  (arguments ((104 (Int 127332186018541)) (106 (String 105))))
  (event_type Duration_begin)))
(Event
 ((timestamp 202ns) (thread 1) (category 107) (name 105) (arguments ())
  (event_type Duration_end)))
(Interned_string (index 109) (value "\025dd;?\\&"))
(Event
 ((timestamp 237ns) (thread 1) (category 107) (name 109)
  (arguments ((104 (Int 85218555566586)) (106 (String 109))))
  (event_type Duration_begin)))
(Interned_string (index 110) (value "GGCP!p\015"))
(Event
 ((timestamp 274ns) (thread 1) (category 107) (name 110)
  (arguments ((104 (Int 122787015563720)) (106 (String 110))))
  (event_type Duration_begin)))
(Event
 ((timestamp 0s) (thread 1) (category 107) (name 108)
  (arguments ((104 (Int 121487422884678)) (106 (String 108))))
  (event_type Duration_begin)))
(Event
 ((timestamp 0s) (thread 1) (category 107) (name 108)
  (arguments ((104 (Int 78866027486094)) (106 (String 108))))
  (event_type Duration_begin)))
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
      (arguments ((108 (Int 122787015563720)) (110 (String 109))))
      (event_type Duration_begin)))
    (Interned_string (index 111) (value "\031q\0212\002\016"))
    (Event
     ((timestamp 319ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Int 32921123688219)) (110 (String 111))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 109) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 329ns) (thread 1) (category 105) (name 111)
      (arguments ((108 (Int 20989024948660)) (110 (String 111))))
      (event_type Duration_begin)))
    (Interned_string (index 112) (value I))
    (Event
     ((timestamp 365ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Int 51976414893270)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 111) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 436ns) (thread 1) (category 105) (name 112)
      (arguments ((108 (Int 133110582289134)) (110 (String 112))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 521ns) (thread 1) (category 105) (name 112) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 113) (value "_\025dd;?\\"))
    (Event
     ((timestamp 521ns) (thread 1) (category 105) (name 113) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 114) (value "N8\016$>"))
    (Event
     ((timestamp 521ns) (thread 1) (category 105) (name 114)
      (arguments ((108 (Int 8892312327129)) (110 (String 114))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 562ns) (thread 1) (category 105) (name 114) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 115) (value ";|\025K?\029A\025"))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 115)
      (arguments ((108 (Int 1972815520075)) (110 (String 115))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 113)
      (arguments ((108 (Int 132616083027461)) (110 (String 113))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 107)
      (arguments ((108 (Int 18056637561335)) (110 (String 107))))
      (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 106)
      (arguments ((108 (Int 117693177829825)) (110 (String 106))))
      (event_type Duration_begin)))
    (Interned_string (index 116) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 116) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 104)
      (arguments ((108 (Int 78866027486094)) (110 (String 104))))
      (event_type Duration_begin)))
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
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 50ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 50ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 100ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 101ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 102ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 103ns) (thread 1) (category 107) (name 105)
      (arguments ((104 (Int 0)) (106 (String 105)))) (event_type Duration_begin)))
    (Event
     ((timestamp 113ns) (thread 1) (category 107) (name 105) (arguments ())
      (event_type Duration_end)))
    (Event
     ((timestamp 0s) (thread 1) (category 107) (name 103)
      (arguments ((104 (Int 0)) (106 (String 103)))) (event_type Duration_begin)))
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
    (Interned_string (index 107) (value fn1))
    (Event
     ((timestamp 3ns) (thread 1) (category 105) (name 107) (arguments ())
      (event_type Duration_end)))
    (Interned_string (index 108) (value address))
    (Interned_string (index 109) (value fn0))
    (Interned_string (index 110) (value symbol))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 109)
      (arguments ((108 (Int 0)) (110 (String 109)))) (event_type Duration_begin)))
    (Interned_string (index 111) (value [unknown]))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 111) (arguments ())
      (event_type (Duration_complete (end_time 0s)))))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 107)
      (arguments ((108 (Int 0)) (110 (String 107)))) (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 106)
      (arguments ((108 (Int 0)) (110 (String 106)))) (event_type Duration_begin)))
    (Event
     ((timestamp 0s) (thread 1) (category 105) (name 104)
      (arguments ((108 (Int 0)) (110 (String 104)))) (event_type Duration_begin)))
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
