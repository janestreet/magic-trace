open! Core

type t =
  | Low
  | Normal
  | High
  | Custom of
      { cyc : bool option [@sexp.option]
      ; cyc_thresh : int option [@sexp.option]
      ; mtc : bool option [@sexp.option]
      ; mtc_period : int option [@sexp.option]
      ; noretcomp : bool option [@sexp.option]
      ; psb_period : int option [@sexp.option]
      }
[@@deriving sexp]

let param =
  let open Command.Param in
  flag
    "-timer-resolution"
    (optional_with_default
       High
       (Command.Arg_type.create (fun str -> t_of_sexp (Sexp.of_string str))))
    ~doc:
      "RESOLUTION How granular timing information should be, one of Low, Normal, High, \
       or Custom (default: Normal). More info: magic-trace.org/w/t"
;;
