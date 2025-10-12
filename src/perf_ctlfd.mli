open! Core

type t

val create : unit -> t

(** Returns the additional arguments to `perf record` to use these as control fds, and a
    callback to invoke after the fork. *)
val control_opt : t -> string list * (unit -> unit)

module Command : sig
  type t

  val snapshot : t
  val stop : t
end

val dispatch_and_block_for_ack : t -> Command.t -> (unit, [ `Perf_exited ]) result
