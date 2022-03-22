open! Core
open! Async

type t = private Int63.t [@@deriving sexp_of]

include Flags.S with type t := t

val configurable_psb_period : t
val detect_exn : unit -> t Deferred.t
