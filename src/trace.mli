open! Core
open! Async
open! Import

val command : Command.t

module For_testing : sig
  val write_trace_from_events
    :  trace_mode:Trace_mode.t
    -> ?debug_info:Elf.Addr_table.t
    -> Tracing_zero.Writer.t
    -> (string * Breakpoint.Hit.t) list
    -> Decode_result.t
    -> unit Deferred.Or_error.t
end
