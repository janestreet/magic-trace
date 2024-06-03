open! Core
open! Async

val decode_events_and_annotate
  :  decode_events:(unit -> Decode_result.t Deferred.Or_error.t)
  -> range_symbols:Trace_filter.t
  -> (Event.With_write_info.t Async.Pipe.Reader.t list * unit Deferred.Or_error.t)
       Deferred.Or_error.t
