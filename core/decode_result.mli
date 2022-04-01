open Core
open Async

(* The result of decoding events is a pipe of those events, and a deferred reason why the
   decoder exited. *)
type t =
  { events : Event.t Pipe.Reader.t
  ; close_result : unit Or_error.t Deferred.t
  }
