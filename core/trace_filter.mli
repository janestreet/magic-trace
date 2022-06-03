open! Core

(* A specification of a trace filter for magic-trace *)

module Unevaluated : sig
  type t =
    { start_symbol : Symbol_selection.t
    ; stop_symbol : Symbol_selection.t
    }
  [@@deriving fields]
end

type t =
  { start_symbol : string
  ; stop_symbol : string
  }
[@@deriving sexp, fields]

val param : Unevaluated.t option Command.Param.t
