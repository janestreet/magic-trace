open! Core
open! Import

type t

val create
  :  trace_mode:Trace_mode.t
  -> debug_info:Elf.Addr_table.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> Tracing.Trace.t
  -> t

module type Trace = Trace_writer_intf.S_trace

val create_expert
  :  trace_mode:Trace_mode.t
  -> debug_info:Elf.Addr_table.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> (module Trace with type thread = _)
  -> t

val write_event : t -> Event.t -> unit
val flush_all : t -> unit
