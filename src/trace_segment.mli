open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

val create : Ocaml_exception_info.t option -> in_filtered_region:bool -> t

(** Create a new trace segment that continues from the state of an existing segment,
    taking the existing segment's last callstack as the new segment's first callstack. *)
val create_continuing_from : t -> in_filtered_region:bool -> t

val in_filtered_region : t -> bool
val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit

val write_trace
  :  t
  -> (module Trace_writer_intf.S_trace with type thread = 'thread)
  -> 'thread
  -> Elf.Addr_table.t
  -> enter_initial_callstack:bool
       (** Emit a frame-enter for each frame in the *first* callstack of this segment. *)
  -> exit_final_callstack:bool
       (** Emit a frame-exit for each frame in the *last* callstack of this segment. *)
  -> unit
