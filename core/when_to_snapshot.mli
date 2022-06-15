open! Core

(* A specification of when magic-trace will take a snapshot. *)

type which_function =
  | Use_fzf_to_select_one
  | User_selected of string

type t =
  | Magic_trace_or_the_application_terminates
  | Application_calls_a_function of which_function

val param : t Command.Param.t
