open! Core

module Aux_action : sig
  type t =
    | Start_paused
    | Resume
    | Pause
  [@@deriving compare, sexp]

  val to_string : t -> string
  val add_to_perf_config : t -> string -> string
end

module Aux_control_event : sig
  type t =
    { address : int64
    ; action : Aux_action.t
    }
  [@@deriving sexp]

  val to_perf_event : t -> string
end

module Event : sig
  module Name : sig
    type t =
      | Branch_misses
      | Cache_misses
    [@@deriving compare, hash, sexp, bin_io]

    val to_string : t -> string
  end

  module When_to_sample : sig
    type t =
      | Frequency of int
      | Period of int
  end

  module Precision : sig
    type t =
      | Arbitrary_skid
      | Constant_skid
      | Request_zero_skid
      | Zero_skid
      | Maximum_possible
  end

  type t =
    { when_to_sample : When_to_sample.t
    ; name : Name.t
    ; precision : Precision.t
    }
end

type t =
  | Intel_processor_trace of
      { extra_events : Event.t list
      ; aux_action : Aux_action.t option
      ; aux_control_events : Aux_control_event.t list
      }
  | Stacktrace_sampling of { extra_events : Event.t list }

val with_aux_control : t -> start_address:int64 -> stop_address:int64 -> t Or_error.t
val extra_events : t -> Event.t list
val aux_action : t -> Aux_action.t option
val aux_control_events : t -> Aux_control_event.t list
val param : t Command.Param.t
