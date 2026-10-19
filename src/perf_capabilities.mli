open! Core
open! Async

type t = private Int63.t [@@deriving sexp_of]

include Flags.S with type t := t

val configurable_psb_period : t
val kernel_tracing : t
val kcore : t
val snapshot_on_exit : t
val last_branch_record : t
val dlfilter : t
val ctlfd : t
val ptwrite : t
val detect_exn : unit -> t Deferred.t
