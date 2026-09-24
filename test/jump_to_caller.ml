open! Core
open! Magic_trace_lib

let%expect_test "a jump to an existing caller does not duplicate its frame" =
  let module Trace = struct
    type thread = unit

    let allocate_pid ~name:_ = 1
    let allocate_thread ~pid:_ ~name:_ = ()

    let write_duration_begin ?category:_ () ~args:_ ~thread:_ ~name ~time:_ =
      if String.equal name "RunSync" then print_endline "begin RunSync"
    ;;

    let write_duration_end ?category:_ () ~args:_ ~thread:_ ~name ~time:_ =
      if String.equal name "RunSync" then print_endline "end RunSync"
    ;;

    let write_duration_complete ~args:_ ~thread:_ ~name:_ ~time:_ ~time_end:_ = ()
    let write_duration_instant ~args:_ ~thread:_ ~name:_ ~time:_ = ()
    let write_counter ~args:_ ~thread:_ ~name:_ ~time:_ = ()
  end
  in
  let writer =
    Trace_writer.create_expert
      ~trace_scope:Userspace
      ~debug_info:None
      ~ocaml_exception_info:None
      ~earliest_time:Time_ns.Span.zero
      ~hits:[]
      ~annotate_inferred_start_times:false
      (module Trace)
  in
  let location name : Event.Location.t =
    { instruction_pointer = 0L; symbol = From_perf name; symbol_offset = 0; dso = Null }
  in
  let thread : Event.Thread.t =
    { pid = Some (Pid.of_int 1234); tid = Some (Pid.of_int 1234) }
  in
  let event time kind src dst =
    let event : Event.t =
      Ok
        { thread
        ; time = Time_ns.Span.of_int_ns time
        ; data =
            Trace
              { kind = Some kind
              ; trace_state_change = None
              ; src = location src
              ; dst = location dst
              }
        ; in_transaction = false
        }
    in
    Trace_writer.write_event
      writer
      (Event.With_write_info.create ~should_write:true event)
  in
  event 1 Call "main" "RunSync";
  event 2 Call "RunSync" "Table";
  event 3 Call "Table" "release";
  event 4 Call "release" "dispose";
  event 5 Jump "dispose" "release";
  event 6 Jump "release" "Table";
  event 7 Return "Table" "RunSync";
  event 8 Return "RunSync" "main";
  Trace_writer.finalize writer;
  [%expect {|
    begin RunSync
    end RunSync
    |}]
;;

let%expect_test "inferred callers begin before an initial trace-start frame ends" =
  let events = ref [] in
  let record kind name time =
    events := (Time_ns.Span.to_int_ns time, kind, name) :: !events
  in
  let module Output = struct
    type thread = unit

    let allocate_pid ~name:_ = 1
    let allocate_thread ~pid:_ ~name:_ = ()

    let write_duration_begin ?category:_ () ~args:_ ~thread:_ ~name ~time =
      record "begin" name time
    ;;

    let write_duration_end ?category:_ () ~args:_ ~thread:_ ~name ~time =
      record "end" name time
    ;;

    let write_duration_complete ~args:_ ~thread:_ ~name:_ ~time:_ ~time_end:_ = ()
    let write_duration_instant ~args:_ ~thread:_ ~name:_ ~time:_ = ()
    let write_counter ~args:_ ~thread:_ ~name:_ ~time:_ = ()
  end
  in
  let writer =
    Trace_writer.create_expert
      ~trace_scope:Userspace
      ~debug_info:None
      ~ocaml_exception_info:None
      ~earliest_time:Time_ns.Span.zero
      ~hits:[]
      ~annotate_inferred_start_times:false
      (module Output)
  in
  let location name : Event.Location.t =
    { instruction_pointer = 0L; symbol = From_perf name; symbol_offset = 0; dso = Null }
  in
  let thread : Event.Thread.t =
    { pid = Some (Pid.of_int 1234); tid = Some (Pid.of_int 1234) }
  in
  let event time kind trace_state_change src dst =
    let event : Event.t =
      Ok
        { thread
        ; time = Time_ns.Span.of_int_ns time
        ; data =
            Trace { kind; trace_state_change; src = location src; dst = location dst }
        ; in_transaction = false
        }
    in
    Trace_writer.write_event
      writer
      (Event.With_write_info.create ~should_write:true event)
  in
  event 1 None (Some Start) "[unknown]" "Inner";
  event 1 (Some Return) None "Inner" "Outer";
  event 2 (Some Return) None "Outer" "main";
  Trace_writer.finalize writer;
  List.rev !events
  |> List.mapi ~f:(fun index (time, kind, name) -> time, index, kind, name)
  |> List.sort ~compare:(fun (t1, i1, _, _) (t2, i2, _, _) ->
    [%compare: int * int] (t1, i1) (t2, i2))
  |> List.iter ~f:(fun (time, _, kind, name) -> printf "%d %s %s\n" time kind name);
  [%expect
    {|
    1 begin main
    1 begin Outer
    1 begin Inner
    2 end Inner
    2 end Outer
    2 end main
    |}]
;;
