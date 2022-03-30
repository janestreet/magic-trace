open! Core

type t =
  | Userspace
  | Kernel
  | Userspace_and_kernel
[@@deriving sexp_of, compare, equal]

let commands_and_docs =
  [ ( Userspace_and_kernel
    , "trace-include-kernel"
    , "Trace userspace and the kernel. Requires root." )
  ; ( Kernel
    , "trace-kernel-only"
    , "Trace the kernel and do not trace userspace. Requires root." )
  ]
;;

let param =
  Command.Param.choose_one
    ~if_nothing_chosen:(Default_to Userspace)
    (List.map commands_and_docs ~f:(fun (variant, flag, doc) ->
         Command.Param.flag flag (Command.Param.no_arg_some variant) ~doc))
;;
