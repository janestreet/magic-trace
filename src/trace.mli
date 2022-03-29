open! Core
open! Async
open! Import

val command : Command.t

module For_testing : sig
  val write_trace_from_events
    :  trace_mode:Trace_mode.t
    -> ?debug_info:Elf.Addr_table.t
    -> ?exn_info:Trace_writer.Exn_info.t
    -> Tracing.Trace.t
    -> (string * Breakpoint.Hit.t) list
    -> Event.t Pipe.Reader.t
    -> unit Deferred.t
end
