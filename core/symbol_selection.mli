open! Core

type t =
  | Use_fzf_to_select_one
  | User_selected of string

val of_command_string : string -> t
