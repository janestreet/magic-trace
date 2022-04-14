open! Core

type t =
  | Start
  | End
[@@deriving sexp, compare]
