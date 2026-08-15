open! Core
open! Async

type t

val create : tid:Pid.t -> addr:int64 -> t Or_error.t
val enable : t -> single_hit:bool -> unit Or_error.t

val monitor
  :  t
  -> interrupt:unit Deferred.t
  -> on_hit:(Breakpoint.Hit.t -> unit)
  -> [ `Bad_fd | `Closed | `Interrupted | `Unsupported ] Deferred.t

val destroy : t -> unit

module Manager : sig
  val monitor_process
    :  pid:Pid.t
    -> addr:int64
    -> single_hit:bool
    -> interrupt:unit Deferred.t
    -> on_hit:(Breakpoint.Hit.t -> unit)
    -> unit Deferred.t

  module For_testing : sig
    val new_thread_ids : active:Set.M(Pid).t -> Pid.t list -> Pid.t list
  end
end
