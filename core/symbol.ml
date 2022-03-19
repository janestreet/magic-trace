open! Core

type t =
  | From_perf of string
  | From_perf_map of Perf_map_location.t
  | Unknown
  | Untraced
  | Returned
  | Syscall
[@@deriving sexp, compare]

let display_name = function
  | Unknown -> "[unknown]"
  | Untraced -> "[untraced]"
  | Returned -> "[returned]"
  | Syscall -> "[syscall]"
  | From_perf name -> name
  | From_perf_map { function_; _ } -> function_
;;

let demangle_elf_name name =
  if String.is_prefix name ~prefix:"caml_"
  then name
  else Owee_location.demangled_symbol name
;;

let demangle t =
  match t with
  | Unknown | Untraced | Returned | Syscall | From_perf_map _ ->
    (* CR-someday cgaebel: Demangle java + other managed runtime names. *)
    t
  | From_perf name -> From_perf (demangle_elf_name name)
;;
