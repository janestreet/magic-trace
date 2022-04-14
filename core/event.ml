open! Core

module Kind = struct
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

  (* magic-trace has some things that aren't functions but look like they are in the trace
     (like "[untraced]" and "[syscall]") *)
  let locationless symbol = { instruction_pointer = 0L; symbol; symbol_offset = 0 }
  let unknown = locationless Unknown
  let untraced = locationless Untraced
  let returned = locationless Returned
  let syscall = locationless Syscall
end

module Ok = struct
  type t =
    { thread : Thread.t
    ; time : Time_ns.Span.t
    ; trace_state_change : Trace_state_change.t option [@sexp.option]
    ; kind : Kind.t option [@sexp.option]
    ; src : Location.t
    ; dst : Location.t
    }
  [@@deriving sexp]
end

module Decode_error = struct
  type t =
    { thread : Thread.t
          (* The time is only present sometimes. I haven't figured out when, exactly, but my
       Skylake test machine has it while my Tiger Lake test machine doesn't. It could
       easily be a difference between different versions of perf... *)
    ; time : Time_ns_unix.Span.Option.t
    ; instruction_pointer : Int64.Hex.t
    ; message : string
    }
  [@@deriving sexp]
end

type t = (Ok.t, Decode_error.t) Result.t [@@deriving sexp]

let thread (t : t) =
  match t with
  | Ok { thread; _ } | Error { thread; _ } -> thread
;;

let time (t : t) =
  match t with
  | Ok { time; _ } -> Time_ns_unix.Span.Option.some time
  | Error { time; _ } -> time
;;

let change_time (t : t) ~f : t =
  match t with
  | Ok ({ time; _ } as t) -> Ok { t with time = f time }
  | Error ({ time; _ } as u) ->
    (match%optional.Time_ns_unix.Span.Option time with
    | None -> t
    | Some time -> Error { u with time = Time_ns_unix.Span.Option.some (f time) })
;;
