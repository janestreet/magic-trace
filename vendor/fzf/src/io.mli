(** Input sanitization for fzf *)

open! Core
open! Import

type 'err t

val of_human_friendly_string : [ `String_contains_newline ] t
val of_escaped_string : Nothing.t t

(** A string returned from fzf. *)
module Output : Identifiable

(** A 'fzf-friendly' string, in that it doesn't contain any newlines. *)
module Input : sig
  type t = private string [@@deriving sexp_of]
end

val encode : 'a t -> string -> (Input.t, 'a) Result.t

val decode
  :  _ t
  -> Output.t
  -> (string, [ `Decoded_with_inconsistent_codec of Error.t ]) Result.t
