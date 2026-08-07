open! Core

module Entry : sig
  module Cmdline : sig
    type t = string list
  end
end

val read_proc_info : Pid.t -> unit
val read_all_proc_info : unit -> unit
val cmdline_of_pid : Pid.t -> Entry.Cmdline.t option
val is_kernel_thread : Pid.t -> bool
val find_vmlinux : unit -> string option
val executable_of_pid : Pid.t -> string Or_error.t
