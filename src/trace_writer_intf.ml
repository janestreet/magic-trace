open! Core

module type S_trace = sig
  type thread

  val allocate_pid : name:string -> int
  val allocate_thread : pid:int -> name:string -> thread

  val write_duration_begin
    :  args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> unit

  val write_duration_end
    :  args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> unit

  val write_duration_complete
    :  args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> time_end:Time_ns.Span.t
    -> unit

  val write_duration_instant
    :  args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> unit

  val write_counter
    :  args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> unit

  (* TODO Delete this, it's a temporary hack *)
  val base_time : Time_ns.t
end
