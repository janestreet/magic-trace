open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

val create : unit -> t
val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit
