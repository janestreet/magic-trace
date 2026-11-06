(** Writes aggregated trace data in Brendan Gregg's collapsed-stack format, suitable for
    use with FlameGraph tools (https://github.com/brendangregg/FlameGraph) and speedscope
    (https://www.speedscope.app/).

    Collapsed format is one line per unique stack: [frame1;frame2;frame3 count\n]. *)

open! Core

(** Write collapsed-stack format to an [Out_channel]. Each line is a semicolon-separated
    stack (root to leaf) followed by a space and the sample count / time value. *)
val write_collapsed : Out_channel.t -> Stack_aggregator.Result.t -> unit

(** Write a self-contained HTML file with an interactive flame graph using the d3-flame-graph
    library. *)
val write_html : Out_channel.t -> Stack_aggregator.Result.t -> title:string -> unit

(** Write speedscope JSON format (https://www.speedscope.app/file-format-spec.html). *)
val write_speedscope_json : Out_channel.t -> Stack_aggregator.Result.t -> title:string -> unit
