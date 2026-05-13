open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

module Fiber : sig
  type t
end

val create : Ocaml_exception_info.t option -> Fiber.t Hashtbl.M(Int).t -> t

(** Create a new trace segment that continues from the state of an existing segment,
    taking the existing segment's last callstack as the new segment's first callstack. *)
val create_continuing_from : t -> t

val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit
val set_fiber_id : t -> int -> unit

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
