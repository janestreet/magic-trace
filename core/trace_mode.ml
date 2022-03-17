open! Core

type t =
  | Userspace
  | Kernel
  | Userspace_and_kernel
[@@deriving sexp_of, compare, equal]

let commands_and_docs =
  [ Userspace, "trace-userspace", "trace userspace only"
  ; Userspace_and_kernel, "trace-include-kernel", "trace userspace and kernel"
  ; Kernel, "trace-kernel-only", "trace kernel only"
  ]
;;

let param =
  Command.Param.choose_one
    ~if_nothing_chosen:(Default_to Userspace)
    (List.map commands_and_docs ~f:(fun (variant, flag, doc) ->
         Command.Param.flag flag (Command.Param.no_arg_some variant) ~doc))
;;
