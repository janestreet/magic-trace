open! Core

module End_kind : sig
  type t =
    | Call
    | Return
    | Syscall
    | Sysret
    | Iret
    | None
  [@@deriving sexp, compare, equal]
end

module Kind : sig
  type t =
    | Call
    | Return
    | Start
    | Syscall
    | Sysret
    | Hardware_interrupt
    | Iret
    | Decode_error
    | End of End_kind.t
    | Jump
  [@@deriving sexp, compare, equal]
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
  ; kind : Kind.t
  ; src : Location.t
  ; dst : Location.t
  }
[@@deriving sexp]
