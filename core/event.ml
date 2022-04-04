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
  ; kind : Kind.t
  ; src : Location.t
  ; dst : Location.t
  }
[@@deriving sexp]
