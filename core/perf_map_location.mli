open! Core

type t =
  { start_addr : int64
  ; size : int
  ; function_ : string
  }
[@@deriving sexp, compare, bin_io, hash]
