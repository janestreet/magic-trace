open! Core

(** A continuous, lossless, error-free segment of a trace corresponding to a single
    thread. *)
type t

(** A fiber represents a suspended callstack ranging from an effect handler to a
    performed effect. Fibers are identified by a unique ID, which the OxCaml runtime
    logs as a [ptwrite] event whenever it switches fibers.

    For example, in
    {[
      Effect.Deep.match_with
        (fun () ->
          (* Run other code that calls... *)
          Effect.perform My_effect)
    ]}
    [match_with] starts a new fiber, then [perform] pops the callstack (including
    exception handlers) up to the handler and packages it for later resumption. *)
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
  -> unit
