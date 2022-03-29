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

(** Wrapper around [Owee_elf.find_section] that checks section type is SHT_NOTE. *)
val find_notes_section : Owee_elf.section array -> string -> Owee_elf.section

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

  (** Returns the start address of the .stapsdt.base
      section in ELF file, or None if the section is not present. *)
  val find_base_address : Owee_elf.section array -> int64 option

  (** Adjust an address from a note for the prelink effect.
      [actual_base] is the start address of the .stapsdt.base
      section in ELF file, as returned by [find_base_address]
      and [recorded_base] is the address of that section as it appears
      in the note. They may be different if there is prelink,
      because prelink does not adjust notes' content for address offsets. *)
  val adjust : int64 -> actual_base:int64 -> recorded_base:int64 -> int64
end

(** [get_buildid buf sections]
    Reads ".note.gnu.build-id" section, checks that the owner is "GNU"
    and that the type is NT_GNU_BUILD_ID=3 and returns the content.
    Expects [buf] to point to the beginning of an elf file. *)
val read_buildid : Owee_buf.t -> Owee_elf.section array -> string
