open! Core

type t =
  | Last_branch_record
  | Frame_pointers
  | Dwarf
[@@deriving sexp]

val param : t option Command.Param.t
val to_perf_string : t -> string
