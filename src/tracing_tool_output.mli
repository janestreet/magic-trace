open! Core
open! Async

type t

(** Offers configuration parameters for where to save a file and whether to serve it *)
val param : t Command.Param.t

(** After [f] writes a trace, either hosts a Perfetto UI server for the resulting file or
    just saves it and prints a message about how to view the resulting trace.

    It is the responsibility of [f] to close the writer and Perfetto may fail to load
    the trace if the writer isn't closed. *)
val write_and_maybe_view
  :  ?num_temp_strs:int
  -> t
  -> f_sexp:(Writer.t -> 'a Deferred.Or_error.t)
  -> f_fuchsia:(Tracing_zero.Writer.t -> 'a Deferred.Or_error.t)
  -> 'a Deferred.Or_error.t
