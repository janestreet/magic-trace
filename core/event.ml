open! Core

module End_kind = struct
  type t =
    | Call
    | Return
    | Syscall
    | Sysret
    | Iret
    | None
  [@@deriving sexp, compare, equal]
end

module Kind = struct
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
  ; addr : Int64.Hex.t
  ; kind : Kind.t
  ; symbol : Symbol.t
  ; offset : Int.Hex.t
  ; ip : Int64.Hex.t
  ; ip_symbol : Symbol.t
  ; ip_offset : Int.Hex.t
  }
[@@deriving sexp]
