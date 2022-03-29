(** Parse ELF file using Owee and extract probe notes and section offsets. *)

(** Currently, arguments of probes are not used by probes_lib.
    Each site may have different arguments.
*)
type probe_info =
  { name : string
  ; semaphores : int64 array (** address of the semaphore corresponding to the probe *)
  ; sites : int64 array
  (** addresses of all the probe sites with the given name
      and semaphore.  *)
  }

type section =
  { name : string
  ; addr : int64
  (** The address at which the section's first byte should reside in memory,
      or 0 for non-allocatable sections.*)
  ; offset : int64
  (** The byte offset from the beginning of the ELF file to
      the first byte in the section*)
  ; size : int64
  }

(** Sectionfields are used in position independent executables
    to find the dynamic addresses of probe sites and semaphores *)
type t =
  { filename : string
  ; pie : bool (** is this a position independent executable? *)
  ; probes : (string, probe_info) Hashtbl.t
  ; text_section : section
  ; data_section : section
  ; semaphores_section : section option (** semaphores live in ".probes" section *)
  }

(** Read elf notes for SystemTap tracing probes from ocaml provider. *)
val create : filename:string -> t

(** Return the probe info or raise if not found.  *)
val find_probe_note : t -> string -> probe_info

val set_verbose : bool -> unit

exception Invalid_format of string
