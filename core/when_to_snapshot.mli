open! Core

(* A specification of when magic-trace will take a snapshot. *)

type t =
  | Magic_trace_or_the_application_terminates
  | Application_calls_a_function of Symbol_selection.t

val param : t Command.Param.t
