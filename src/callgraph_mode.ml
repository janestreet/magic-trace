open! Core

type t =
  | Last_branch_record
  | Frame_pointers
  | Dwarf
[@@deriving sexp]

let of_string = function
  | "lbr" -> Last_branch_record
  | "fp" -> Frame_pointers
  | "dwarf" -> Dwarf
  | str -> t_of_sexp (Sexp.of_string str)
;;

let param =
  let open Command.Param in
  flag
    "-callgraph-mode"
    (optional (Command.Arg_type.create of_string))
    ~doc:
      " When magic-trace is running with sampling collection mode, this sets how it \
       should reconstruct callstacks. The options are Last_branch_record (lbr), Dwarf \
       (dwarf), and Frame_pointers (fp). Will default to Last_branch_record if supported \
       and Dwarf otherwise."
;;

let to_perf_string = function
  | Last_branch_record -> "lbr"
  | Frame_pointers -> "fp"
  | Dwarf -> "dwarf"
;;
