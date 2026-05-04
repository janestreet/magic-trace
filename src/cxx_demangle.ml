open! Core

(** C++ symbol demangling via __cxa_demangle.

    Returns [Some demangled_name] when [s] is a valid Itanium ABI mangled
    symbol (i.e. starts with [_Z]).  Returns [None] for everything else —
    plain C symbols, OCaml symbols, Rust v0 symbols ([_R...]), and any
    [_Z]-prefixed string the demangler does not recognise.

    The underlying C stub passes a NULL output buffer to __cxa_demangle so it
    malloc-allocates the buffer.  Passing a stack buffer would be unsafe: the
    demangler may realloc its argument, and realloc'ing stack memory is
    undefined behaviour. *)
external demangle_unsafe : string -> string option = "magic_trace_cxx_demangle"

let demangle s =
  (* Cheap prefix guard so we don't pay the FFI cost on every OCaml/C/kernel
     symbol — only Itanium-ABI _Z names cross into C++. *)
  if String.length s >= 2 && Char.equal s.[0] '_' && Char.equal s.[1] 'Z'
  then demangle_unsafe s
  else None
;;

module%test _ = struct
  let print_result s =
    match demangle s with
    | Some d -> printf "Some %s\n" d
    | None -> printf "None\n"
  ;;

  let%expect_test "demangles a simple C++ function symbol" =
    print_result "_Z3foov";
    [%expect {| Some foo() |}]
  ;;

  let%expect_test "demangles a templated C++ symbol" =
    print_result "_Z3fooIiEvv";
    [%expect {| Some void foo<int>() |}]
  ;;

  let%expect_test "OCaml caml-prefixed symbols are skipped without an FFI call" =
    print_result "camlMain__main_42";
    [%expect {| None |}]
  ;;

  let%expect_test "_Z-prefixed garbage fails gracefully" =
    print_result "_Z!!!not_a_real_symbol";
    [%expect {| None |}]
  ;;

  let%expect_test "empty string is rejected by the length guard" =
    print_result "";
    [%expect {| None |}]
  ;;

  let%expect_test "single underscore is rejected by the length guard" =
    print_result "_";
    [%expect {| None |}]
  ;;
end
