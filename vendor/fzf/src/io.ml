open! Core
open! Import
module Output = String
module Input = String

type 'err t =
  | Human_friendly_string : [ `String_contains_newline ] t
  | Escaped_string : Nothing.t t

let of_human_friendly_string = Human_friendly_string
let of_escaped_string = Escaped_string

let encode (type err) (t : err t) (string : string) : (_, err) Result.t =
  match t with
  | Human_friendly_string ->
    if String.exists string ~f:(Char.equal '\n')
    then Error `String_contains_newline
    else Ok string
  | Escaped_string -> Ok (String.escaped string)
;;

let decode (type err) (t : err t) output_from_fzf_binary =
  match t with
  | Human_friendly_string -> Ok output_from_fzf_binary
  | Escaped_string ->
    (match Scanf.unescaped output_from_fzf_binary with
     | unescaped -> Ok unescaped
     | exception _ ->
       let err =
         Error.create_s [%message "string was not encoded with [String.escaped]"]
       in
       Error (`Decoded_with_inconsistent_codec err))
;;
