open! Core

val fork_exec_stopped : prog:string -> argv:string list -> unit -> Pid.t
val resume : Pid.t -> unit
