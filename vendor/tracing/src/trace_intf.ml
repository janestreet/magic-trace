open! Core

module Event_arg = struct
  type value =
    | Interned of string (** use for strings which can be interned into a limited pool *)
    | String of string (** use for strings with a large number of unique values *)
    | Int of int
    | Int64 of int64
    | Pointer of Int64.Hex.t
    | Float of float (** written as a double-precision float *)
  [@@deriving sexp_of]

  (** Each argument has a name, the names are interned *)
  type t = string * value [@@deriving sexp_of]
end
