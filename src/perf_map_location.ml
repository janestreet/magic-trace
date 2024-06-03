open! Core

(* all the ints print in hex to match the format in the actual perf map file *)
type t =
  { start_addr : Int64.Hex.t
  ; size : Int.Hex.t
  ; function_ : string
  }
[@@deriving sexp, compare, bin_io, hash]
