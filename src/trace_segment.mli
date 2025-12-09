open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

val create : Ocaml_exception_info.t option -> t

(** Create a new trace segment that continues from the state of an existing segment,
    taking the existing segment's last callstack as the new segment's first callstack. *)
val create_continuing_from : t -> t

val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit

val write_trace
  :  t
  -> (module Trace_writer_intf.S_trace with type thread = 'thread)
  -> 'thread
  -> unit
