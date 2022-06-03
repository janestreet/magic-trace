open! Core
open! Async
open! Import

val command : Command.t

module For_testing : sig
  val get_events_pipe
    :  ?range_symbols:Trace_filter.t
    -> events:Event.t list
    -> unit
    -> Event.With_write_info.t Pipe.Reader.t Deferred.t

  val write_trace_from_events
    :  ?ocaml_exception_info:Ocaml_exception_info.t
    -> trace_scope:Trace_scope.t
    -> debug_info:Elf.Addr_table.t option
    -> Tracing_zero.Writer.t
    -> hits:(string * Breakpoint.Hit.t) list
    -> events:Event.With_write_info.t Pipe.Reader.t list
    -> close_result:unit Deferred.Or_error.t
    -> unit Deferred.Or_error.t
end
