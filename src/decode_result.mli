open Core
open Async

(* The result of decoding events are pipe(s) of those events, and a deferred
   reason why the decoder exited. Multiple pipes will be returned if multiple
   snapshots were captured and processed, but they are returned in chronological
   order. Waiting on [close_result] will wait on pipes in sequential order. *)
type t =
  { events : Event.t Pipe.Reader.t list
  ; close_result : unit Or_error.t Deferred.t
  }
