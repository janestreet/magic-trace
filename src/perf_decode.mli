(** Module used for parsing / decoding [perf script] output. *)

open! Core
open! Async

val to_events
  :  ?perf_maps:Perf_map.Table.t
  -> string Pipe.Reader.t
  -> Event.t Pipe.Reader.t

module For_testing : sig
  val to_event : ?perf_maps:Perf_map.Table.t -> string list -> Event.t option
  val split_line_pipe : string Pipe.Reader.t -> string list Pipe.Reader.t
end
