(** Memory map of a running process *)
exception Error of string

type t =
  { vma_offset_text : int64
  ; vma_offset_semaphores : int64
  }

(** [read pid filename] reads memory map of a running process from /proc/pid/maps and
    extracts information relavant to the object file [filename]. Requires permissions to
    read maps, such as calling this function from pid itself or a process attached to pid
    using ptrace, and pid should be stopped (or memory map might be modified by the OS
    during reading). *)
val read : pid:int -> Elf.t -> t

(** Control debug printing. *)
val verbose : bool ref
