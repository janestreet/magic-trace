open! Core

type t =
  | Last_branch_record of { stitched : bool }
  | Frame_pointers
  | Dwarf
[@@deriving sexp]

val param : t option Command.Param.t
val to_perf_record_args : t option -> string list
val to_perf_script_args : t option -> string list
