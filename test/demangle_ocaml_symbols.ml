open! Core
open Magic_trace_core

let demangle_symbol_test symbol =
  let demangle_symbol = Demangle_ocaml_symbols.demangle symbol in
  print_s [%sexp (demangle_symbol : string option)]
;;

let%expect_test "real mangled symbol" =
  demangle_symbol_test "camlAsync_unix__Unix_syscalls__to_string_57255";
  [%expect {| (Async_unix.Unix_syscalls.to_string) |}]
;;

let%expect_test "proper hexcode" =
  demangle_symbol_test "caml$3f";
  [%expect {| (?) |}]
;;

let%expect_test "improper hexcode" =
  demangle_symbol_test "caml$7l";
  [%expect {| ($7l) |}]
;;

let%expect_test "when the symbol is not a demangled ocaml symbol" =
  demangle_symbol_test "dr__$3e$21_358";
  [%expect {| () |}]
;;
