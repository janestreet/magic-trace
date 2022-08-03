open Core
open Import

type t =
  { symbol_to_id : (Symbol.t, int) Hashtbl.t
  ; id_to_symbol : (int, Symbol.t) Hashtbl.t
  ; mutable next_symbol_id : int
  ; follow_table : (int, int) Hashtbl.t
  }

(* Initialise a compression state *)
val init : unit -> t

type compression_event =
  { new_symbols : (Symbol.t * int) list
  ; callstack : (int * int) list
  }
[@@deriving sexp, bin_io]

(* Compress a callstack represented as a list of symbol, and update the compression
    state inplace.

    When compressing a sequence of many callstacks, this function should be called
    in order on all callstacks with the same compression state.
*)
val compress_callstack : t -> Symbol.t list -> compression_event

(* Decompress a callstack represented as a compression_event, and update the compression
   state inplace.

   When decompressing a sequence of many callstacks, this function should be called
   in order on all compression events with the same compression state.
*)
val decompress_callstack : t -> compression_event -> Symbol.t list
