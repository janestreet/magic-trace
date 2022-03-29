open! Core
open! Import

type t

module Exn_info : sig
  type t

  val create
    :  push_traps:int64 array
    -> pop_traps:int64 array
    -> enter_traps:int64 array
    -> t
end

val create
  :  trace_mode:Trace_mode.t
  -> debug_info:Elf.Addr_table.t option
  -> exn_info:Exn_info.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> Tracing.Trace.t
  -> t

val write_event : t -> Event.t -> unit
val flush_all : t -> unit
