open! Core
open! Import

(* Enable this in tests to see [t] after every perf event. Don't forget to disable it when
   you're done!

   To take advantage of this from perf script tests, call [Perf_script.run ~debug:true].
*)
val debug : bool ref

type t [@@deriving sexp_of]

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
val end_of_trace : t -> unit
