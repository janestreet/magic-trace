open! Core
open! Async

val command : Command.t

module For_testing : sig
  val get_events_pipe
    :  ?range_symbols:Trace_filter.t
    -> events:Event.t list
    -> unit
    -> Event.With_write_info.t Pipe.Reader.t Deferred.t

  val write_trace_from_events
    :  ?ocaml_exception_info:Ocaml_exception_info.t
    -> events_writer:Tracing_tool_output.events_writer option
    -> writer:Tracing_zero.Writer.t option
    -> trace_scope:Trace_scope.t
    -> debug_info:Elf.Addr_table.t option
    -> hits:(string * Breakpoint.Hit.t) list
    -> events:Event.With_write_info.t Pipe.Reader.t list
    -> close_result:'a Deferred.t
    -> unit
    -> 'a Deferred.t
end
