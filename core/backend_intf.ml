(** Backends, which do the Processor Trace recording, present this unified
    interface in order to be exposed as commands which can generate traces. *)

open! Core
open! Async

module type S = sig
  module Record_opts : sig
    type t

    val param : t Command.Param.t
  end

  module Recording : sig
    type t

    val attach_and_record
      :  Record_opts.t
      -> trace_mode:Trace_mode.t
      -> record_dir:string
      -> Pid.t
      -> t Deferred.Or_error.t

    val take_snapshot : t -> unit Or_error.t
    val finish_recording : t -> unit Deferred.Or_error.t
  end

  module Decode_opts : sig
    type t

    val param : t Command.Param.t
  end

  val decode_events
    :  Decode_opts.t
    -> record_dir:string
    -> perf_map:Perf_map.t option
    -> Event.t Pipe.Reader.t Deferred.Or_error.t
end
