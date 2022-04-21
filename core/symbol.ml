open! Core

type t =
  | From_perf of string
  | From_perf_map of Perf_map_location.t
  | Unknown
  | Untraced
  | Returned
  | Syscall
[@@deriving sexp, compare]

let display_name = function
  | Unknown -> "[unknown]"
  | Untraced -> "[untraced]"
  | Returned -> "[returned]"
  | Syscall -> "[syscall]"
  | From_perf name -> name
  | From_perf_map { function_; _ } -> function_
;;
