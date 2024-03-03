open! Core

(* Like [Byte_units.t], but must represent a power of 2 number of pages. magic-trace uses these to
   represent perf's "auxtrace mmap size" (grep for that string in
   https://man7.org/linux/man-pages/man1/perf-intel-pt.1.html). *)
type t [@@deriving sexp_of]

val optional_flag : string -> doc:string -> t option Command.Param.t
val num_pages : t -> int
