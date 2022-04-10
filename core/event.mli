open! Core

module Trace_state_change : sig
  type t =
    | Start
    | End
  [@@deriving sexp, compare]
end

module Kind : sig
  type t =
    | Call
    | Return
    | Syscall
    | Sysret
    | Hardware_interrupt
    | Iret
    | Decode_error
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
end

type t =
  { thread : Thread.t
  ; time : Time_ns.Span.t
  ; trace_state_change : Trace_state_change.t option
  ; kind : Kind.t option
  ; src : Location.t
  ; dst : Location.t
  }
[@@deriving sexp]
