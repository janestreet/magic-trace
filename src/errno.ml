open! Core

let to_error errno =
  Core_unix.Error.of_system_int ~errno |> Core_unix.Error.message |> Or_error.error_string
;;

let to_result errno =
  match errno with
  | 0 -> Ok ()
  | errno -> to_error errno
;;
