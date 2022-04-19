(** Make it easier to use flows by buffering a flow event so that events can be added until
    the flow is finalized. See the docs in [trace.mli] for what a flow event is.

    If using this type with the [Trace.t] simplified writing interface use the functions on
    that type to write and finalize flows.*)
open! Core

type t

val create : flow_id:int -> t

(* Use these functions only if working directly with a [Tracing_zero.Writer.t] otherwise
   see the similar functions on [Tracing.Trace.t]. *)
val write_step
  :  t
  -> Tracing_zero.Writer.t
  -> thread:Tracing_zero.Writer.Thread_id.t
  -> ticks:int
  -> unit

val finish : t -> Tracing_zero.Writer.t -> unit
