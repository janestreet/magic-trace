open! Core

type t =
  | From_perf of string
  | From_perf_map of Perf_map_location.t
  | Unknown
  | Untraced
  | Returned
  | Syscall
[@@deriving sexp, compare, bin_io, hash]

(* [Int64.Hex] (used by [Perf_map_location]) doesn't derive [equal], so we implement
   explicitly. *)
let equal t1 t2 = compare t1 t2 = 0

let display_name = function
  | Unknown -> "[unknown]"
  | Untraced -> "[untraced]"
  | Returned -> "[returned]"
  | Syscall -> "[syscall]"
  | From_perf name -> name
  | From_perf_map { function_; _ } -> function_
;;
