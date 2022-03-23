(** A module that wraps a [Tracing_zero.Writer.t] and makes it easy to write parsed
    records back into a trace file while preserving the original string/thread interning. *)
open! Core

type t

(* The [Record_writer.t] calls [Tracing_zero.Expert.set_string_slot], so the writer should
   usually have [num_temp_strs] set to [String_id.max_number_of_temp_string_slots] (or
   have enough temp string slots to intern all the strings in the trace).

   Timestamps will be written in nanoseconds (relative to a base tick of 0), so the
   [Tracing_zero.Writer.t] shouldn't have a non-default tick rate or a non-zero base tick. *)
val create : Tracing_zero.Writer.t -> t

(* May raise if attempting to write strings/threads on records before writing the
   corresponding [Interned_string] or [Interned_thread] records. *)
val write_record : t -> record:Parser.Record.t -> unit
