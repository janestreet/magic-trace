(** High-speed global trace writing with timestamps for programs to record information for
    debugging and optimization as they run. Does some of the work up-front so that the
    writing path is as efficient as possible. The goal is for each event written (start and
    stop of a duration is two events) to take less than 10ns.

    There are only fast paths for a limited set of events that are composed of only a
    header word, which can be easily pre-computed, and a timestamp word. Everything else
    can be written using the exposed [global_writer].

    This is a separate library rather than part of [Tracing_zero] so that it's possible
    to have tools which write trace data without creating a global trace writer. For
    example so a trace collector process wouldn't need to handle weird cases where it
    tries to connect to itself. *)
open! Core

val set_destination : (module Tracing_zero.Writer.Expert.Destination) -> unit

(** Signals that the program is done writing events and to flush all pending events *)
val close : unit -> unit

(** Many things don't have a special fast path, and can be written directly to the trace
    using this writer. Event arguments for probes must be written using
    [Writer.Expert.Write_arg_unchecked]. *)
val global_writer : Tracing_zero.Writer.t

(** The thread ID that events are recorded to representing execution on the main thread *)
val main_thread : Tracing_zero.Writer.Thread_id.t

(** Represents a pre-computed event header that can be quickly written along with a
    hardware timestamp into the global trace. *)
module Event : sig
  type t

  (** Returns a separate duration begin and end events,
      with matching [name] and [category].
      [arg_types] are attached to duration begin event only.
      Duration end event does not have any arguments.
      [create_duration_begin] and [create_duration_end] allow different
      arguments for begin and end events, but the user must ensure
      the name and category match.
  *)
  val create_duration
    :  arg_types:Tracing_zero.Writer.Arg_types.t
    -> category:string
    -> name:string
    -> t * t

  (** Create duration begin event with arguments. *)
  val create_duration_begin
    :  arg_types:Tracing_zero.Writer.Arg_types.t
    -> category:string
    -> name:string
    -> t

  (** Create duration end event with arguments. *)
  val create_duration_end
    :  arg_types:Tracing_zero.Writer.Arg_types.t
    -> category:string
    -> name:string
    -> t

  val create_instant
    :  arg_types:Tracing_zero.Writer.Arg_types.t
    -> category:string
    -> name:string
    -> t

  (** See [Tracing.Writer.write_duration_instant].  *)
  val create_duration_instant
    :  arg_types:Tracing_zero.Writer.Arg_types.t
    -> category:string
    -> name:string
    -> t

  val write : t -> unit
  val write_and_get_tsc : t -> Time_stamp_counter.t
end

module For_testing : sig
  val tick_translation : Tracing_zero.Writer.Tick_translation.t
end
