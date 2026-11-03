(** Writes aggregated trace data as per-function performance statistics, similar to
    [perf report]. Provides call counts, total/self time, and percentile breakdowns. *)

open! Core

module Output_format : sig
  type t =
    | Text
    | Json
    | Csv
end

(** Write benchmark statistics to an [Out_channel] in the specified format.
    Functions are sorted by self-time descending (hottest first). *)
val write : Out_channel.t -> Stack_aggregator.Result.t -> format:Output_format.t -> unit
