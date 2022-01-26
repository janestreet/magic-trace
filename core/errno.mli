(** Using C errno numbers is a convenient way to plumb errors we might want to handle
    gracefully out of a C stub, rather than using exceptions. This file provides some
    utilities for converting them to OCaml errors. *)
open! Core

val to_error : int -> 'a Or_error.t
val to_result : int -> unit Or_error.t
