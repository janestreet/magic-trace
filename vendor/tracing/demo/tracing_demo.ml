open! Core
module TW = Tracing_zero.Writer
module Trace = Tracing.Trace

(** All functionality should be tested in this function, and also in the corresponding
    [write_demo_trace] in [test/trace.ml].

    This function is in this module instead of the tests so that there can be an
    `app/tracing` command to write out the demo trace and validate it reads correctly
    in Perfetto. *)
let write_demo_trace t =
  let base_time = Time_ns.of_int_ns_since_epoch 1 in
  let tick_translation = { TW.Tick_translation.epoch_ns with base_time } in
  TW.write_tick_initialization t tick_translation;
  let proc_name = TW.intern_string t "myproc" in
  TW.set_process_name t ~pid:1 ~name:proc_name;
  TW.set_thread_name t ~pid:1 ~tid:2 ~name:(TW.intern_string t "mythread");
  let thread = TW.set_thread_slot ~slot:0 t ~pid:1 ~tid:2 in
  let category = TW.intern_string t "stuff" in
  let name = TW.intern_string t "my_funct" in
  TW.write_duration_complete
    t
    ~arg_types:(TW.Arg_types.create ~strings:1 ())
    ~thread
    ~category
    ~name
    ~ticks:10_000
    ~ticks_end:5_000_000;
  (* re-use some existing interned strings for argument names *)
  TW.Write_arg.string t ~name category;
  let temp_str = TW.set_temp_string_slot t ~slot:1 "wow" in
  let temp_str2 = TW.set_temp_string_slot t ~slot:2 "cool" in
  TW.write_duration_complete
    t
    ~arg_types:(TW.Arg_types.create ~strings:2 ())
    ~thread
    ~category
    ~name
    ~ticks:7_000_000
    ~ticks_end:15_000_000;
  TW.Write_arg.string t ~name temp_str;
  TW.Write_arg.string t ~name:category temp_str2;
  (* This flow event is out of time order to match the way the helper library writes
     flow events by buffering them until the next event in order to know which type
     of flow event should be emitted. *)
  TW.write_flow_begin t ~thread ~ticks:2_000_000 ~flow_id:1;
  TW.write_instant
    t
    ~arg_types:TW.Arg_types.none
    ~thread
    ~category
    ~name
    ~ticks:17_000_000;
  TW.write_duration_begin
    t
    ~arg_types:TW.Arg_types.none
    ~thread
    ~category
    ~name
    ~ticks:20_000_000;
  TW.write_flow_step t ~thread ~ticks:15_000_000 ~flow_id:1;
  TW.write_duration_end
    t
    ~arg_types:(TW.Arg_types.create ~int64s:1 ~int32s:1 ~floats:1 ())
    ~thread
    ~category
    ~name
    ~ticks:40_000_000;
  TW.Write_arg.int63 t ~name Int.min_value;
  TW.Write_arg.int32 t ~name:category (-1);
  TW.Write_arg.float t ~name:proc_name (-1.0);
  TW.write_flow_end t ~thread ~ticks:20_000_000 ~flow_id:1;
  TW.write_counter
    t
    ~arg_types:(TW.Arg_types.create ~int32s:1 ())
    ~thread
    ~category
    ~name
    ~ticks:7_000_000
    ~counter_id:1;
  TW.Write_arg.int32 t ~name:category 1;
  TW.write_counter
    t
    ~arg_types:(TW.Arg_types.create ~floats:1 ())
    ~thread
    ~category
    ~name
    ~ticks:20_000_000
    ~counter_id:1;
  TW.Write_arg.float t ~name:category 2.5;
  TW.write_counter
    t
    ~arg_types:(TW.Arg_types.create ~int64s:1 ())
    ~thread
    ~category
    ~name
    ~ticks:20_000_000
    ~counter_id:1;
  TW.Write_arg.int64 t ~name:category Int64.max_value;
  TW.write_counter
    t
    ~arg_types:(TW.Arg_types.create ~int64s:1 ())
    ~thread
    ~category
    ~name
    ~ticks:20_000_000
    ~counter_id:1;
  TW.Write_arg.pointer t ~name:category Int64.max_value
;;

(** This must be kept in sync with [write_demo_trace] and write a byte-identical trace *)
let write_demo_trace_high_level writer =
  let base_time = Some (Time_ns.of_int_ns_since_epoch 1) in
  let trace = Trace.Expert.create ~base_time writer in
  let pid = Trace.allocate_pid trace ~name:"myproc" in
  let thread = Trace.allocate_thread trace ~pid ~name:"mythread" in
  let name = "my_funct" in
  let category = "stuff" in
  let time_for_us = Time_ns.Span.of_int_us in
  Trace.write_duration_complete
    trace
    ~args:Trace.Arg.[ "my_funct", Interned "stuff" ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 10)
    ~time_end:(time_for_us 5_000);
  let flow = Trace.create_flow trace in
  Trace.write_flow_step trace flow ~thread ~time:(time_for_us 2_000);
  Trace.write_duration_complete
    trace
    ~args:Trace.Arg.[ name, String "wow"; category, String "cool" ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 7_000)
    ~time_end:(time_for_us 15_000);
  Trace.write_flow_step trace flow ~thread ~time:(time_for_us 15_000);
  Trace.write_instant trace ~args:[] ~thread ~category ~name ~time:(time_for_us 17_000);
  Trace.write_duration_begin
    trace
    ~args:[]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 20_000);
  Trace.write_flow_step trace flow ~thread ~time:(time_for_us 20_000);
  Trace.write_duration_end
    trace
    ~args:
      Trace.Arg.
        [ "my_funct", Int Int.min_value; "stuff", Int (-1); "myproc", Float (-1.0) ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 40_000);
  Trace.finish_flow trace flow;
  Trace.write_counter
    trace
    ~args:Trace.Arg.[ "stuff", Int 1 ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 7_000);
  Trace.write_counter
    trace
    ~args:Trace.Arg.[ "stuff", Float 2.5 ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 20_000);
  Trace.write_counter
    trace
    ~args:Trace.Arg.[ "stuff", Int64 Int64.max_value ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 20_000);
  Trace.write_counter
    trace
    ~args:Trace.Arg.[ "stuff", Pointer Int64.max_value ]
    ~thread
    ~category
    ~name
    ~time:(time_for_us 20_000);
  ()
;;
