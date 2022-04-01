open Core
open Async

type t =
  { events : Event.t Pipe.Reader.t
  ; close_result : unit Or_error.t Deferred.t
  }
