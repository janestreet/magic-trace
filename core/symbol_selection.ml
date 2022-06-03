open! Core

type t =
  | Use_fzf_to_select_one
  | User_selected of string

let of_command_string s =
  match s with
  | "?" -> Use_fzf_to_select_one
  | "." -> User_selected Magic_trace.Private.stop_symbol
  | s -> User_selected s
;;
