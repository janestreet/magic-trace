open! Core
open! Async
open! Import

val command : Command.t

module For_testing : sig
  val write_trace_from_events
    :  ?debug_info:Elf.Addr_table.t
    -> Tracing.Trace.t
    -> (string * Breakpoint.Hit.t) list
    -> Event.t Pipe.Reader.t
    -> unit Deferred.t
end
