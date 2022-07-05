(** Backends, which do the trace recording, present this unified interface in
    order to be exposed as commands which can generate traces. *)

open! Core
open! Async

module type S = sig
  module Record_opts : sig
    type t

    val param : t Command.Param.t
  end

  module Recording : sig
    module Data : sig
      type t [@@deriving sexp]
    end

    type t

    val attach_and_record
      :  Record_opts.t
      -> debug_print_perf_commands:bool
      -> subcommand:Subcommand.t
      -> when_to_snapshot:When_to_snapshot.t
      -> trace_scope:Trace_scope.t
      -> multi_snapshot:bool
      -> timer_resolution:Timer_resolution.t
      -> record_dir:string
      -> collection_mode:Collection_mode.t
      -> Pid.t list
      -> (t * Data.t) Deferred.Or_error.t

    val maybe_take_snapshot : t -> source:[ `ctrl_c | `function_call ] -> unit
    val finish_recording : t -> unit Deferred.Or_error.t
  end

  module Decode_opts : sig
    type t

    val param : t Command.Param.t
  end

  val decode_events
    :  ?perf_maps:Perf_map.Table.t
    -> ?filter_same_symbol_jumps:bool
         (** Whether to filter unnecessary events which are jumps within the same
             function. Default [true]. *)
    -> debug_print_perf_commands:bool
    -> recording_data:Recording.Data.t option
         (** This parameter is passed to allow [decode_events] to depend
             on information or configuration from [attach_and_record]. *)
    -> record_dir:string
    -> collection_mode:Collection_mode.t
    -> Decode_opts.t
    -> Decode_result.t Deferred.Or_error.t
end
