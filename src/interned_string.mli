open! Core

type t = private string [@@deriving equal, hash, compare, sexp, bin_io]

val intern : string -> t
