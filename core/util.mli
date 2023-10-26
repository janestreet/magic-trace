open! Core

val int64_of_hex_string : ?remove_hex_prefix:bool -> string -> int64
val int_trunc_of_hex_string : ?remove_hex_prefix:bool -> string -> int
val experimental_flag : default:'a -> 'a Command.Param.t -> 'a Command.Param.t
