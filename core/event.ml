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
  [@@deriving sexp, compare, bin_io]
end

module Thread = struct
  type t =
    { pid : Pid.t option
    ; tid : Pid.t option
    }
  [@@deriving sexp, compare, hash, bin_io]
end

module Location = struct
  type t =
    { instruction_pointer : Int64.Hex.t
    ; symbol : Symbol.t
    ; symbol_offset : Int.Hex.t
    }
  [@@deriving sexp, fields, bin_io]

  module Ignore_symbol = struct
    (* Ignoring symbol strings when serializing to save space. This reduces the size of events file
       by ~50% based on small tests. The symbol information is still available implicitly by looking at the top
      of the callstack that optionally is exported together with the events. Symbol offset will be missing.*)

    type nonrec t = t

    let to_sexpable { instruction_pointer; _ } = instruction_pointer

    let of_sexpable instruction_pointer =
      { instruction_pointer; symbol = Symbol.Unknown; symbol_offset = 0 }
    ;;

    let to_binable { instruction_pointer; _ } = instruction_pointer

    let of_binable instruction_pointer =
      { instruction_pointer; symbol = Symbol.Unknown; symbol_offset = 0 }
    ;;

    let caller_identity =
      Bin_prot.Shape.Uuid.of_string "0d14b306-09e1-11ed-9c9e-a4bb6d9e5f20"
    ;;
  end

  include Binable.Of_binable_with_uuid (Int64.Hex) (Ignore_symbol)
  include Sexpable.Of_sexpable (Int64.Hex) (Ignore_symbol)

  (* magic-trace has some things that aren't functions but look like they are in the trace
     (like "[untraced]" and "[syscall]") *)
  let locationless symbol = { instruction_pointer = 0L; symbol; symbol_offset = 0 }
  let unknown = locationless Unknown
  let untraced = locationless Untraced
  let returned = locationless Returned
  let syscall = locationless Syscall
end

module Ok = struct
  module Data = struct
    type t =
      | Trace of
          { trace_state_change : Trace_state_change.t option [@sexp.option]
          ; kind : Kind.t option [@sexp.option]
          ; src : Location.t
          ; dst : Location.t
          }
      | Power of { freq : int }
      | Stacktrace_sample of { callstack : Location.t list }
      | Event_sample of
          { location : Location.t
          ; count : int
          ; name : Collection_mode.Event.Name.t
          }
    [@@deriving sexp, bin_io]
  end

  type t =
    { thread : Thread.t
    ; time : Time_ns.Span.t
    ; data : Data.t
    }
  [@@deriving sexp, bin_io]
end

module Decode_error = struct
  type t =
    { thread : Thread.t
        (* The time is only present sometimes. I haven't figured out when, exactly, but my
       Skylake test machine has it while my Tiger Lake test machine doesn't. It could
       easily be a difference between different versions of perf... *)
    ; time : Time_ns_unix.Span.Option.t
    ; instruction_pointer : Int64.Hex.t option
    ; message : string
    }
  [@@deriving sexp, bin_io]
end

type t = (Ok.t, Decode_error.t) Result.t [@@deriving sexp, bin_io]

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

module With_write_info = struct
  type outer = t [@@deriving sexp_of]

  type t =
    { event : outer
    ; should_write : bool
    }
  [@@deriving sexp_of, fields]

  let create ?(should_write = true) event = { event; should_write }
end
