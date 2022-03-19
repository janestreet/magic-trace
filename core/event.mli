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
    ; tid : int option
    }
  [@@deriving sexp, compare, hash]
end

type t =
  { thread : Thread.t
  ; time : Time_ns.Span.t
  ; addr : int64
  ; kind : Kind.t
  ; symbol : Symbol.t
  ; offset : int
  ; ip : int64
  ; ip_symbol : Symbol.t
  ; ip_offset : int
  }
[@@deriving sexp]
