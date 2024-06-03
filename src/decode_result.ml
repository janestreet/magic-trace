open Core
open Async

type t =
  { events : Event.t Pipe.Reader.t list
  ; close_result : unit Or_error.t Deferred.t
  }
