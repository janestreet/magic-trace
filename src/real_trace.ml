open! Core
open Trace_writer_intf

let create (trace : Tracing.Trace.t) =
  let module T = struct
    type thread = Tracing.Trace.Thread.t

    let allocate_pid = Tracing.Trace.allocate_pid trace
    let allocate_thread = Tracing.Trace.allocate_thread trace
    let write_duration_begin = Tracing.Trace.write_duration_begin trace ~category:""
    let write_duration_end = Tracing.Trace.write_duration_end trace ~category:""
    let write_duration_complete = Tracing.Trace.write_duration_complete trace ~category:""
    let write_duration_instant = Tracing.Trace.write_duration_instant trace ~category:""
    let write_counter = Tracing.Trace.write_counter trace ~category:""
    let base_time = Tracing.Trace.base_time trace
  end
  in
  (module T : S_trace with type thread = Tracing.Trace.Thread.t)
;;
