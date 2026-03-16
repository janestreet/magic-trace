open! Core

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
  | Intel_processor_trace of { extra_events : Event.t list }
  | Stacktrace_sampling of { extra_events : Event.t list }

val extra_events : t -> Event.t list

(** Returns the sysfs device path for the hardware trace source. On aarch64, this is
    [/sys/bus/event_source/devices/cs_etm]. On x86_64, this is
    [/sys/bus/event_source/devices/intel_pt]. *)
val hardware_trace_device_path : unit -> string

val param : t Command.Param.t
