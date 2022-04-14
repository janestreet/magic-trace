open! Core

module Kind : sig
  type t =
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
  [@@deriving sexp]

  val unknown : t
  val untraced : t
  val returned : t
  val syscall : t
end

module Ok : sig
  type t =
    { thread : Thread.t
    ; time : Time_ns.Span.t
    ; trace_state_change : Trace_state_change.t option
    ; kind : Kind.t option
    ; src : Location.t
    ; dst : Location.t
    }
  [@@deriving sexp]
end

module Decode_error : sig
  type t =
    { thread : Thread.t
    ; time : Time_ns_unix.Span.Option.t
    ; instruction_pointer : int64
    ; message : string
    }
  [@@deriving sexp]
end

type t = (Ok.t, Decode_error.t) Result.t [@@deriving sexp]

val thread : t -> Thread.t
val time : t -> Time_ns_unix.Span.Option.t
val change_time : t -> f:(Time_ns.Span.t -> Time_ns.Span.t) -> t
