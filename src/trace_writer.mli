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

module Mapped_time : sig
  type t = private Time_ns.Span.t [@@deriving sexp, compare, bin_io]

  include Comparable with type t := t

  val start_of_trace : t
  val create : Time_ns.Span.t -> base_time:Time_ns.Span.t -> t
  val is_base_time : t -> bool
  val add : t -> Time_ns.Span.t -> t
  val diff : t -> t -> Time_ns.Span.t
end

module Callstack : sig
  type t =
    { stack : Event.Location.t Stack.t
    ; mutable create_time : Mapped_time.t
    }
  [@@deriving sexp, bin_io]
end

module Event_and_callstack : sig
  type t =
    { event : Event.t
    ; callstack : Callstack_compression.compression_event
    }
  [@@deriving sexp, bin_io]
end

val create_expert
  :  trace_scope:Trace_scope.t
  -> debug_info:Elf.Addr_table.t option
  -> ocaml_exception_info:Ocaml_exception_info.t option
  -> earliest_time:Time_ns.Span.t
  -> hits:(string * Breakpoint.Hit.t) list
  -> annotate_inferred_start_times:bool
  -> (module Trace with type thread = _)
  -> t

val write_event
  :  t
  -> ?events_writer:Tracing_tool_output.events_writer
  -> Event.With_write_info.t
  -> unit

(** Updates internal data structures when trace ends. If [to_time] is passed, will
    shift to new start time which is useful when writing out multiple snapshots
    from perf. *)
val end_of_trace : ?to_time:Time_ns.Span.t -> t -> unit
