open! Core

module type S_trace = sig
  type thread

  val allocate_pid : name:string -> int
  val allocate_thread : pid:int -> name:string -> thread

  val write_duration_begin
    :  ?category:string
    -> unit
    -> args:Tracing.Trace.Arg.t list
    -> thread:thread
    -> name:string
    -> time:Time_ns.Span.t
    -> unit

  val write_duration_end
    :  ?category:string
    -> unit
    -> args:Tracing.Trace.Arg.t list
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

  module Flow : sig
    type t

    val create : unit -> t
    val write_step : t -> thread:thread -> time:Time_ns.Span.t -> unit
    val finish : t -> unit
  end
end
