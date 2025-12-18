open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

val create : unit -> t
val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit

val write_trace
  :  t
  -> Tracing.Trace.t
  -> Tracing.Trace.Thread.t
  -> enter_initial_callstack:bool
  -> exit_final_callstack:bool
  -> unit

module Stitch_result : sig
  type t = private
    | Stitched
    | Indepdenent
end

val stitch : before:t -> after:t -> Stitch_result.t

val print_all_callstacks : t -> unit
val start_time : t -> Timestamp.t Or_null.t
val end_time : t -> Timestamp.t Or_null.t
