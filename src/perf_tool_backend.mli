(** A backend that uses the [perf] command line tool for recording and decoding *)
open! Import

include Backend_intf.S

module Perf_line : sig
  val to_event : ?perf_maps:Perf_map.Table.t -> string -> Event.t
end
