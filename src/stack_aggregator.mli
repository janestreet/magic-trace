(** Aggregates trace events into per-function statistics and per-stack-trace time
    distributions for flame graph and benchmark output.

    Consumes the same [Event.t] pipe that the trace writer uses, but accumulates
    aggregate data instead of writing Perfetto spans. *)

open! Core

module Function_stats : sig
  type t =
    { name : string
    ; call_count : int
    ; total_time_ns : Int63.t
    ; self_time_ns : Int63.t
    ; min_duration_ns : Int63.t
    ; max_duration_ns : Int63.t
    ; durations_ns : Int63.t list
        (** All observed durations, for computing percentiles. *)
    }

  val compare_by_self_time : t -> t -> int
end

module Collapsed_stack : sig
  (** A unique call stack with its accumulated time. *)
  type t =
    { frames : string list (** Root to leaf order. *)
    ; time_ns : Int63.t
    }
end

module Result : sig
  type t =
    { function_stats : Function_stats.t list
    ; collapsed_stacks : Collapsed_stack.t list
    ; total_trace_time_ns : Int63.t
    ; event_count : int
    }
end

(** Process a list of event pipes (one per snapshot) and produce aggregated results.
    Events that are decode errors are counted but otherwise skipped. *)
val aggregate : Event.t Async.Pipe.Reader.t list -> Result.t Async.Deferred.t
