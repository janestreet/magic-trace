open! Core

module End_kind : sig
  type t =
    | Call
    | Return
    | Syscall
    | None
  [@@deriving sexp]
end

module Kind : sig
  type t =
    | Call
    | Return
    | Start
    | Decode_error
    | End of End_kind.t
    | Jump
  [@@deriving sexp]
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
  ; symbol : string
  ; offset : int
  ; ip : int64
  ; ip_symbol : string
  ; ip_offset : int
  }
[@@deriving sexp]
