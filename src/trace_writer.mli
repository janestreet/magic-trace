open! Core
open! Import

type t

val create
  :  debug_info:Elf.Addr_table.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> Tracing.Trace.t
  -> t

val write_event : t -> Backend_intf.Event.t -> unit
val flush_all : t -> unit
