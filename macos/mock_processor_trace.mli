exception Decode_error of string

type trace

type interval =
  { function_id : int
  ; function_name : string
  ; start_ns : int64
  ; end_ns : int64
  ; depth : int
  }

type stats =
  { event_count : int
  ; call_count : int
  ; return_count : int
  ; anchor_count : int
  ; packet_bytes : int
  ; virtual_duration_ns : int64
  ; resolution_ns : int64
  ; max_depth : int
  ; checksum : int64
  }

(** Generate a deterministic, balanced call trace.

    Two call/return events are packed into every byte. A full 64-bit timing
    anchor is inserted every [anchor_every] events, modelling the sparse
    timestamp packets used by hardware processor tracing. *)
val generate
  :  ?resolution_ns:int64
  -> ?anchor_every:int
  -> cycles:int
  -> unit
  -> trace

val event_count : trace -> int
val packet_bytes : trace -> int
val resolution_ns : trace -> int64

(** Decode the packet stream and reconstruct exact function intervals.
    [on_interval] is called when a return closes a function. *)
val decode : ?on_interval:(interval -> unit) -> trace -> stats

(** Write a small synthetic trace that can be opened by Perfetto or
    magic-trace.org. Large performance tests should use [decode] instead so
    JSON serialization does not dominate the benchmark. *)
val write_trace_json : force:bool -> trace -> string -> stats
