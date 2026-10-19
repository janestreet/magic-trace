open! Core
open Trace_writer_intf

let create (trace : Tracing.Trace.t) =
  let module T = struct
    type thread = Tracing.Trace.Thread.t

    let allocate_pid = Tracing.Trace.allocate_pid trace
    let allocate_thread = Tracing.Trace.allocate_thread trace

    let write_duration_begin ?(category = "") () =
      Tracing.Trace.write_duration_begin trace ~category
    ;;

    let write_duration_end ?(category = "") () =
      Tracing.Trace.write_duration_end trace ~category
    ;;

    let write_duration_complete = Tracing.Trace.write_duration_complete trace ~category:""
    let write_duration_instant = Tracing.Trace.write_duration_instant trace ~category:""
    let write_counter = Tracing.Trace.write_counter trace ~category:""

    module Flow = struct
      type t = Tracing.Flow.t

      let create () = Tracing.Trace.create_flow trace

      let write_step flow ~thread ~time =
        Tracing.Trace.write_flow_step trace flow ~thread ~time
      ;;

      let finish flow = Tracing.Trace.finish_flow trace flow
    end
  end
  in
  (module T : S_trace with type thread = Tracing.Trace.Thread.t)
;;
