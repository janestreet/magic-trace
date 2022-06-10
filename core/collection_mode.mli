open! Core

type t =
  | Intel_processor_trace
  | Stacktrace_sampling

val param : t Command.Param.t
