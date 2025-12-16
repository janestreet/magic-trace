open! Core

(** A discrete point in time within a trace. *)
type t = private Time_ns.Span.t

val create : Time_ns.Span.t -> t
val zero : t
