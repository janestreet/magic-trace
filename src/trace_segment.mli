open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

val create : unit -> t
val add_event : t -> Event.Ok.Data.t -> Timestamp.t -> unit

val write_trace
  :  t
  -> Tracing.Trace.t
  -> Tracing.Trace.Thread.t
  -> Elf.Addr_table.t
  -> enter_initial_callstack:bool
       (** Emit a frame-enter for each frame in the *first* callstack of this segment. *)
  -> exit_final_callstack:bool
       (** Emit a frame-exit for each frame in the *last* callstack of this segment. *)
  -> unit
