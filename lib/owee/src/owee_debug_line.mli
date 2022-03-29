open Owee_buf

type header

(** [read_chunk cursor] expects cursor to be pointing to the beginning of a
    DWARF linenumber program.  Those are usually put in ".debug_line" section
    of an ELF binary.
    Iff such a program is found, the [cursor] is advanced to the next one (or
    to the end) and [Some (header, cursor')] is returned.
*)
val read_chunk : cursor -> (header * cursor) option

(** State of the linenumber automaton.
    IMPORTANT: this state is mutable!
    A value of this type can change as the file is scanned. *)
type state = {
  mutable address        : int;
  mutable filename       : string;
  mutable file           : int;
  mutable line           : int;
  mutable col            : int;
  mutable is_statement   : bool;
  mutable basic_block    : bool;
  mutable end_sequence   : bool;
  mutable prologue_end   : bool;
  mutable epilogue_begin : bool;
  mutable isa            : int;
  mutable discriminator  : int;
}

(** [get_filename header state] get the filename associated to the row
    described by [state].
    Linenumber programs are allowed to store the filename as an index to a
    registry in the [state.file] field.  This function reads this registry if
    [state.file] is valid, or returns [state.filename]. *)
val get_filename : header -> state -> string option

(** [fold_rows (header, cursor) f init] will fold over the rows defined by the
    program described by [(header, cursor)], using the function [f] and
    initial state [init]. *)
val fold_rows : header * cursor ->
  (header -> state -> 'a -> 'a) -> 'a -> 'a

(** [copy state] returns a copy of the mutable state *)
val copy : state -> state
