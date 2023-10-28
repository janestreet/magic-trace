open! Core

type t =
  | Last_branch_record of { stitched : bool [@sexp.default true] }
  | Frame_pointers
  | Dwarf
[@@deriving sexp]

let of_string = function
  (* Kept the short names to match naming of callgraph modes from perf
     (lbr/dwarf/fp) for users who are familiar with perf. [lbr-no-stitch] is not
     from perf, but added as a shorter option. *)
  | "lbr" -> Last_branch_record { stitched = true }
  | "lbr-no-stitch" -> Last_branch_record { stitched = false }
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
       should reconstruct callstacks. The options are [lbr]/[lbr-no-stitch]/[dwarf]/[fp] \
       or a sexp. Will default to [lbr] is available and [dwarf] otherwise. For more \
       info: https://magic-trace.org/w/b"
;;

let to_perf_record_args = function
  | Some (Last_branch_record _) -> [ "--call-graph"; "lbr" ]
  | Some Frame_pointers -> [ "--call-graph"; "fp" ]
  | Some Dwarf -> [ "--call-graph"; "dwarf" ]
  | None -> []
;;

let to_perf_script_args = function
  | Some (Last_branch_record { stitched = true }) -> [ "--stitch-lbr" ]
  | Some (Last_branch_record { stitched = false })
  | Some Frame_pointers
  | Some Dwarf
  | None -> []
;;
