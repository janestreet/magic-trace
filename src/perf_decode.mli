open! Core
open! Import

val to_event : ?perf_maps:Perf_map.Table.t -> string -> Event.t option
