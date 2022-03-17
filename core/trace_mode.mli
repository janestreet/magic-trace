open! Core

type t =
  | Userspace
  | Kernel
  | Userspace_and_kernel
[@@deriving sexp_of, compare, equal]

val param : t Command.Param.t
