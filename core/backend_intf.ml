(** Backends, which do the Processor Trace recording, present this unified
    interface in order to be exposed as commands which can generate traces. *)

open! Core
open! Async

module Event = struct
  type end_kind =
    | Call
    | Return
    | Syscall
    | None
  [@@deriving sexp]

  type kind =
    | Call
    | Return
    | Start
    | Decode_error
    | End of end_kind
    | Jump
  [@@deriving sexp]

  module Thread = struct
    type t =
      { pid : Pid.t option
      ; tid : int option
      }
    [@@deriving sexp, compare, hash]
  end

  type t =
    { thread : Thread.t
    ; time : Time_ns.Span.t
    ; addr : int
    ; kind : kind
    ; symbol : string
    ; offset : int
    }
  [@@deriving sexp]
end

module type S = sig
  type record_opts

  val record_param : record_opts Command.Param.t

  type recording

  val attach_and_record
    :  record_opts
    -> record_dir:string
    -> ?filter:string
    -> Pid.t
    -> recording Deferred.Or_error.t

  val take_snapshot : recording -> unit Or_error.t
  val finish_recording : recording -> unit Deferred.Or_error.t

  type decode_opts

  val decode_param : decode_opts Command.Param.t

  val decode_events
    :  decode_opts
    -> record_dir:string
    -> Event.t Pipe.Reader.t Deferred.Or_error.t
end
