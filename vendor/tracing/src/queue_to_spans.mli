(** Sometimes you only have timing information on when messages entered the input queue of
    a system and when the result was sent out of the system.

    This module lets you guess a start time for events using the simple property that in a
    single-threaded system an event can't start processing until the later of when it
    arrives and when you finished processing the preceeding event to be sent out. *)

open! Core

type t

(** You must create a new instance for each single-threaded system you want to apply this
    logic to, since it keeps internal state about when the last message was sent out. *)
val create : unit -> t

(** Guess the start time of an event given when it entered and exited the system. *)
val event_start
  :  t
  -> output_time:Time_ns.Span.t
  -> ?input_time:Time_ns.Span.t
  -> unit
  -> Time_ns.Span.t
