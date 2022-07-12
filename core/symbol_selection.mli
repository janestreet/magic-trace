open! Core
open! Async

type t =
  | Use_fzf_to_select_one of [ `File | `Func | `File_or_func ]
  | User_selected of string

val of_command_string : string -> t

val evaluate
  :  supports_fzf:bool lazy_t
  -> elf:Elf.t option
  -> header:string
  -> t
  -> string Deferred.Or_error.t
