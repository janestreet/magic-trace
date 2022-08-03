open! Core
open! Async

type t

type events_output_format =
  | Sexp
  | Binio

type events_writer =
  { format : events_output_format
  ; writer : Writer.t
  ; callstack_compression_state : Callstack_compression.t
  }

(** Offers configuration parameters for where to save a file and whether to serve it *)
val param : t Command.Param.t

(** After [f] writes a trace, either hosts a Perfetto UI server for the resulting file or
    just saves it and prints a message about how to view the resulting trace.

    It is the responsibility of [f] to close the writer and Perfetto may fail to load
    the trace if the writer isn't closed. *)
val write_and_maybe_view
  :  ?num_temp_strs:int
  -> t
  -> f:
       (events_writer:events_writer option
        -> writer:Tracing_zero.Writer.t option
        -> unit
        -> 'a Deferred.Or_error.t)
  -> 'a Deferred.Or_error.t
