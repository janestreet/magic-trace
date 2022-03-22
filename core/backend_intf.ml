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
    ; addr : int64
    ; kind : kind
    ; symbol : string
    ; offset : int
    ; ip : int64
    ; ip_symbol : string
    ; ip_offset : int
    }
  [@@deriving sexp]
end

module type S = sig
  module Record_opts : sig
    type t

    val param : t Command.Param.t
  end

  module Recording : sig
    type t

    val attach_and_record
      :  Record_opts.t
      -> record_dir:string
      -> ?filter:string
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
    -> Event.t Pipe.Reader.t Deferred.Or_error.t
end
