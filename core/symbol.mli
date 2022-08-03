open! Core

type t =
  | From_perf of string
  | From_perf_map of Perf_map_location.t
  | Unknown
  | Untraced
  | Returned
  | Syscall
[@@deriving sexp, compare, equal, bin_io, hash]

val display_name : t -> string
