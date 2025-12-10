open! Core

(** A discrete point in time within a trace. *)
type t

val create : Time_ns.Span.t -> t
