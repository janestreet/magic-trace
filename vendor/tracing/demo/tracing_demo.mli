(** Functions used for testing trace generation, and as examples of how to write trace
    events. These aren't inside the tests so that they can also be used in app/tracing
    to generate real trace files to check in Perfetto. *)
open! Core

(** Write trace events which demonstrate all features, for use by expect test and
    [trace generate demo] command *)
val write_demo_trace : Tracing_zero.Writer.t -> unit

(** Write hopefully a byte-identical trace as [write_demo_trace] but using the
    simplified wrapper interface. *)
val write_demo_trace_high_level : Tracing_zero.Writer.t -> unit
