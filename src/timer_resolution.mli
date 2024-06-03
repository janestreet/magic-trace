open! Core

(* A specification of how precise timing events should be. *)

type t =
  | Low
  | Normal
  | High
  | Sample of { freq : int } (** Used when sampling *)
  | Custom of
      { cyc : bool option
      ; cyc_thresh : int option
      ; mtc : bool option
      ; mtc_period : int option
      ; noretcomp : bool option
      ; psb_period : int option
      } (** Used when running with Intel PT. *)
[@@deriving sexp]

val param : t Command.Param.t
