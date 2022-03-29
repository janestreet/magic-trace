(** An abstract type representing compiled program locations.
    It is designed to make sampling cheap (see [extract]), deferring most of
    the work in the much more expensive [lookup] function (without guarantee to
    succeed).
*)
type t

(** A location that can never be resolved *)
val none : t

(** Sample the location from an arbitrary OCaml function.
    Cheap, appropriate to use on a fast path. *)
val extract : (_ -> _) -> t

(** Turn a location into an actual position.
    If it succeeds, the position is returned as a triplet [(file, line, column)].
    To succeed, debug information must be available for the location.

    This call might be quite expensive.  *)
val lookup : t -> (string * int * int) option

(** Convenience function composing lookup and extract, to immediately turn a
    function into a position. *)
val locate : (_ -> _) -> (string * int * int) option

val nearest_symbol : t -> string

val demangled_symbol : string -> string

val nearest_demangled_symbol : t -> string
