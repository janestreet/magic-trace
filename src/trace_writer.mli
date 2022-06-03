open! Core
open! Import

(* Enable this in tests to see [t] after every perf event. Don't forget to disable it when
   you're done!

   To take advantage of this from perf script tests, call [Perf_script.run ~debug:true].
*)
val debug : bool ref

type t [@@deriving sexp_of]

val create
  :  trace_scope:Trace_scope.t
  -> debug_info:Elf.Addr_table.t option
  -> ocaml_exception_info:Ocaml_exception_info.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> annotate_inferred_start_times:bool
  -> Tracing.Trace.t
  -> t

module type Trace = Trace_writer_intf.S_trace

val create_expert
  :  trace_scope:Trace_scope.t
  -> debug_info:Elf.Addr_table.t option
  -> ocaml_exception_info:Ocaml_exception_info.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> annotate_inferred_start_times:bool
  -> (module Trace with type thread = _)
  -> t

val write_event : t -> Event.With_write_info.t -> unit

(** Updates interal data structures when trace ends. If [to_time] is passed, will
   shift to new start time which is useful when writing out multiple snapshots
   from perf. *)
val end_of_trace : ?to_time:Time_ns.Span.t -> t -> unit
