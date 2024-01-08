open! Core

module Kind : sig
  type t =
    | Async
    | Call
    | Return
    | Syscall
    | Sysret
    | Hardware_interrupt
    | Iret
    | Jump
  [@@deriving sexp, compare]
end

module Thread : sig
  type t =
    { pid : Pid.t option
    ; tid : Pid.t option
    }
  [@@deriving sexp, compare, hash]
end

module Location : sig
  type t =
    { instruction_pointer : int64
    ; symbol : Symbol.t
    ; symbol_offset : int
    }
  [@@deriving sexp, fields, bin_io]

  val unknown : t
  val untraced : t
  val returned : t
  val syscall : t
end

module Ok : sig
  module Data : sig
    type t =
      | Trace of
          { trace_state_change : Trace_state_change.t option
          ; kind : Kind.t option
          ; src : Location.t
          ; dst : Location.t
          } (** Represents an event collected from Intel PT. *)
      | Power of { freq : int } (** Power event collected by Intel PT. *)
      | Stacktrace_sample of
          { callstack : Location.t list (** Oldest to most recent calls in order. *) }
      (** Represents cycles event collected through sampling. *)
      | Event_sample of
          { location : Location.t
          ; count : int
          ; name : Collection_mode.Event.Name.t
          } (** Represents counter based events collected through sampling. *)
    [@@deriving sexp]
  end

  type t =
    { thread : Thread.t
    ; time : Time_ns.Span.t
    ; data : Data.t
    }
  [@@deriving sexp]
end

module Decode_error : sig
  type t =
    { thread : Thread.t
    ; time : Time_ns_unix.Span.Option.t
    ; instruction_pointer : int64 option
    ; message : string
    }
  [@@deriving sexp]
end

type t = (Ok.t, Decode_error.t) Result.t [@@deriving sexp, bin_io]

val thread : t -> Thread.t
val time : t -> Time_ns_unix.Span.Option.t
val change_time : t -> f:(Time_ns.Span.t -> Time_ns.Span.t) -> t

module With_write_info : sig
  type outer = t

  type t =
    { event : outer
    ; should_write : bool
    }
  [@@deriving sexp_of, fields]

  val create : ?should_write:bool -> outer -> t
end
