open! Core

(** The logic for this function is derived from perf [0].
    This function is used to change the symbols in the application 
    executable from a mangled form to a demangled form in ocaml. Now
    when running [magic-trace run -trigger] the symbols will appear in
    their demangled form. Will return None if the symbol is not
    recognized as an OCaml symbol.
   
   [0]: https://github.com/torvalds/linux/blob/5bfc75d92efd494db37f5c4c173d3639d4772966/tools/perf/util/demangle-ocaml.c *)
val demangle : string -> string option
