open! Core

module Trace_state_change = struct
  type t =
    | Start
    | End
  [@@deriving sexp, compare]
end

module Kind = struct
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

module Thread = struct
  type t =
    { pid : Pid.t option
    ; tid : Pid.t option
    }
  [@@deriving sexp, compare, hash]
end

module Location = struct
  type t =
    { instruction_pointer : Int64.Hex.t
    ; symbol : Symbol.t
    ; symbol_offset : Int.Hex.t
    }
  [@@deriving sexp]
end

type t =
  { thread : Thread.t
  ; time : Time_ns.Span.t
  ; trace_state_change : Trace_state_change.t option [@sexp.option]
  ; kind : Kind.t option [@sexp.option]
  ; src : Location.t
  ; dst : Location.t
  }
[@@deriving sexp]
