open! Core
open! Import

module Entry : sig
  module Cmdline : sig
    type t = string list
  end
end

val read_proc_info : Pid.t -> unit
val read_all_proc_info : unit -> unit
val cmdline_of_pid : Pid.t -> Entry.Cmdline.t option
