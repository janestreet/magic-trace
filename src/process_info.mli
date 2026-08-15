open! Core

module Entry : sig
  module Cmdline : sig
    type t = string list
  end
end

val read_proc_info : Pid.t -> unit
val read_all_proc_info : unit -> unit
val thread_ids : Pid.t -> Pid.t list Or_error.t
val thread_exists : pid:Pid.t -> tid:Pid.t -> bool
val cmdline_of_pid : Pid.t -> Entry.Cmdline.t option

module For_testing : sig
  val thread_ids_of_dir_entries : string array -> Pid.t list
end
