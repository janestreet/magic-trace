type header = {
  owner : string;
  typ : int;  (** each owner defines its own types *)
  size : int;  (** size of the note's descriptor that follows the header  *)
}

val read_header : Owee_buf.cursor -> header

(** Reads the header and returns the size of the note's descriptor.
    Raises if the [expected_owner] or [expected_type] does not match the header. *)
val read_desc_size
  : Owee_buf.cursor
  -> expected_owner:string
  -> expected_type:int
  -> int

exception Section_not_found of string

module Stapsdt : sig
  type t =
    { addr : int64 (** address of the probe site *)
    ; semaphore : int64 option (** address of the semaphore corresponding to the probe *)
    ; provider : string
    ; name : string
    ; args : string (** probe arguments  *)
    }

  (** [iter buf sections ~f] applies [f] to each stapsdt note,
      in order of appearance in .notes.stapsdt section.
      Expects [buf] to point to the beginning of an elf file.
      Raises [Section_not_found] if .note.stapsdt section is not found.
      Raises if .note.stapsdt is found but .stapsdt.base is not.
      Raises if the owner is not "stapsdt" or the type is not 3
      for version 3 of probes.
      Raises if parsing of notes fails for other reasons. *)
  val iter : Owee_buf.t -> Owee_elf.section array -> f:(t -> unit) -> unit
end

(** [get_buildid buf sections]
    Reads ".note.gnu.build-id" section, checks that the owner is "GNU"
    and that the type is NT_GNU_BUILD_ID=3 and returns the content.
    Expects [buf] to point to the beginning of an elf file. *)
val read_buildid : Owee_buf.t -> Owee_elf.section array -> string
