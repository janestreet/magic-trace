open! Core

type t

(** Uses [perf_event_open] to set a hardware breakpoint at a given address in a process.
    When that breakpoint is hit the resulting file descriptor will poll as readable.

    If [single_hit] is set the breakpoint will disable itself after being hit once. *)
val breakpoint_fd : Pid.t -> addr:int -> single_hit:bool -> t Or_error.t

val destroy : t -> unit

module Hit : sig
  type t =
    { timestamp : Time_ns.Span.t
    ; passed_timestamp : Time_ns.Span.t
    ; passed_val : int
    ; tid : int
    ; ip : int
    }
  [@@deriving sexp]
end

val next_hit : t -> Hit.t option

(** Returns a waitable fd valid only until [t] is destroyed or GCd *)
val fd : t -> Core_unix.File_descr.t
