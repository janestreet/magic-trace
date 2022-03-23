(** This is a high-level API for parsing Fuchsia Trace Format traces created by a
    [Tracing_zero.Writer.t] (or one of the wrappers like [Trace.t]).

    To create a parser, pass in an [Iobuf.t] containing the output of a trace. Each call
    to [parse_next] will advance through the iobuf and will either return a Fuchsia record
    or a parse error. *)
open! Core

include module type of Parser_intf

(** String indices are in the range [1, 32767]. *)
module String_index : sig
  type t = private int [@@deriving sexp_of, compare, hash, equal]

  val to_int : t -> int
  val zero : t
end

(** Thread indices are in the range [1, 255]. *)
module Thread_index : sig
  type t = private int [@@deriving sexp_of, compare, hash, equal]

  val to_int : t -> int
end

module Event_arg : sig
  type value =
    | String of String_index.t
    | Int of int
    | Float of float
  [@@deriving sexp_of, compare]

  type t = String_index.t * value [@@deriving sexp_of, compare]
end

module Event : sig
  type t =
    { timestamp : Time_ns.Span.t
    ; thread : Thread_index.t
    ; category : String_index.t
    ; name : String_index.t
    ; arguments : Event_arg.t list
    ; event_type : Event_type.t
    }
  [@@deriving sexp_of, compare]
end

module Record : sig
  type t =
    | Event of Event.t
    (* [Intered_string] records correspond to "string records" (record type 2) in the
       Fuchsia spec. *)
    | Interned_string of
        { index : String_index.t
        ; value : string
        }
    (* [Intered_thread] records correspond to "thread records" (record type 3) in the
       Fuchsia spec. *)
    | Interned_thread of
        { index : Thread_index.t
        ; value : Thread.t
        }
    (* [Process_name_change] records correspond to "kernel object records" (record type 7)
       with kernel object type = ZX_OBJ_TYPE_PROCESS in the Fuchsia spec. *)
    | Process_name_change of
        { name : String_index.t
        ; pid : int
        }
    (* [Thread_name_change] records correspond to "kernel object records" (record type 7)
       with kernel object type = ZX_OBJ_TYPE_THREAD in the Fuchsia spec. *)
    | Thread_name_change of
        { name : String_index.t
        ; pid : int
        ; tid : int
        }
    (* [Tick_initialization] records correspond to "initialization records" (record type 1)
       in the Fuchsia spec. *)
    | Tick_initialization of
        { ticks_per_second : int
        ; base_time : Time_ns.Option.t
        }
  [@@deriving sexp_of, compare]
end

type t

val create : (read, Iobuf.seek) Iobuf.t -> t

(** Advance through the trace until we find a Fuchsia record matching one of the record
    types defined above.

    When [Parse_error.No_more_words] is returned, the buffer is left to point to the
    beginning of the incomplete record.  Therefore, the next call to [parse_next] will
    attempt to parse the incomplete record again and return the error again.

    When any other parse error is returned, the buffer is left to point to the beginning
    of the next record, having advanced past the record containing the error.  Since we
    look at the record size to know how many words to skip, if the record size is
    incorrect then the parser may enter an invalid state and skip over records/read
    garbage values in the next call to [parse_next].
*)
val parse_next : t -> (Record.t, Parse_error.t) Result.t

val warnings : t -> Warnings.t

exception String_not_found
exception Thread_not_found

(* The functions below should only be called immediately after obtaining a record from
   [parse_next]. A new call to [parse_next] may invalidate any string indices/thread
   indices or tick rates stored on a previous record and the functions below would return
   the wrong values.*)
val ticks_per_second : t -> int
val base_time : t -> Time_ns.Option.t

(* Returns the string stored at [index] in the parser's string table. Index 0 will always
   return an empty string. May raise [String_not_found] if a [String_index.t] from another
   parser instance is passed as an argument and that index is unassigned in [t]'s string
   table. *)
val lookup_string_exn : t -> index:String_index.t -> string

(* Returns the thread stored at [index] in the parser's thread table. May raise
   [Thread_not_found] if a [Thread_index.t] from another parser instance is passed as an
   argument and that index is unassigned in [t]'s thread table. *)
val lookup_thread_exn : t -> index:Thread_index.t -> Thread.t
