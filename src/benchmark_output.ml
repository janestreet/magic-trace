open! Core

module Output_format = struct
  type t =
    | Text
    | Json
    | Csv
end

let format_duration_ns ns =
  let f = Int63.to_float ns in
  if Float.(f < 1_000.0)
  then sprintf "%.0fns" f
  else if Float.(f < 1_000_000.0)
  then sprintf "%.1fus" (f /. 1_000.0)
  else if Float.(f < 1_000_000_000.0)
  then sprintf "%.2fms" (f /. 1_000_000.0)
  else sprintf "%.3fs" (f /. 1_000_000_000.0)
;;

let percentile durations_ns p =
  match durations_ns with
  | [] -> Int63.zero
  | _ ->
    let sorted = List.sort durations_ns ~compare:Int63.compare in
    let n = List.length sorted in
    let idx = Float.to_int (Float.round_nearest (Float.of_int (n - 1) *. p)) in
    let idx = Int.max 0 (Int.min idx (n - 1)) in
    List.nth_exn sorted idx
;;

let write_text out_channel (result : Stack_aggregator.Result.t) =
  let total_ns = result.total_trace_time_ns in
  Out_channel.fprintf out_channel "magic-trace benchmark report\n";
  Out_channel.fprintf out_channel "============================\n\n";
  Out_channel.fprintf
    out_channel
    "Total trace time: %s | Events processed: %d | Functions observed: %d\n\n"
    (format_duration_ns total_ns)
    result.event_count
    (List.length result.function_stats);
  (* Header *)
  Out_channel.fprintf
    out_channel
    "%-6s  %-12s  %-12s  %-8s  %-10s  %-10s  %-10s  %-10s  %s\n"
    "Self%"
    "Self"
    "Total"
    "Calls"
    "Mean"
    "p50"
    "p95"
    "p99"
    "Function";
  Out_channel.fprintf
    out_channel
    "%s\n"
    (String.make 120 '-');
  List.iter result.function_stats ~f:(fun stats ->
    let self_pct =
      if Int63.(total_ns > zero)
      then Float.(Int63.to_float stats.self_time_ns /. Int63.to_float total_ns *. 100.0)
      else 0.0
    in
    let p50 = percentile stats.durations_ns 0.50 in
    let p95 = percentile stats.durations_ns 0.95 in
    let p99 = percentile stats.durations_ns 0.99 in
    let mean =
      if stats.call_count > 0
      then Int63.(stats.total_time_ns / of_int stats.call_count)
      else Int63.zero
    in
    Out_channel.fprintf
      out_channel
      "%5.1f%%  %-12s  %-12s  %-8d  %-10s  %-10s  %-10s  %-10s  %s\n"
      self_pct
      (format_duration_ns stats.self_time_ns)
      (format_duration_ns stats.total_time_ns)
      stats.call_count
      (format_duration_ns mean)
      (format_duration_ns p50)
      (format_duration_ns p95)
      (format_duration_ns p99)
      stats.name)
;;

(** Escape a string for safe embedding in JSON. *)
let json_escape_string s =
  let buf = Buffer.create (String.length s + 8) in
  Buffer.add_char buf '"';
  String.iter s ~f:(fun c ->
    match c with
    | '"' -> Buffer.add_string buf {|\"|}
    | '\\' -> Buffer.add_string buf {|\\|}
    | '\n' -> Buffer.add_string buf {|\n|}
    | '\r' -> Buffer.add_string buf {|\r|}
    | '\t' -> Buffer.add_string buf {|\t|}
    | c when Char.( < ) c ' ' ->
      Buffer.add_string buf (sprintf {|\u%04x|} (Char.to_int c))
    | c -> Buffer.add_char buf c);
  Buffer.add_char buf '"';
  Buffer.contents buf
;;

let write_json out_channel (result : Stack_aggregator.Result.t) =
  let total_ns = result.total_trace_time_ns in
  Out_channel.fprintf out_channel {|{"total_trace_time_ns":%s|} (Int63.to_string total_ns);
  Out_channel.fprintf out_channel {|,"event_count":%d|} result.event_count;
  Out_channel.fprintf
    out_channel
    {|,"function_count":%d|}
    (List.length result.function_stats);
  Out_channel.fprintf out_channel {|,"functions":[|};
  List.iteri result.function_stats ~f:(fun i stats ->
    if i > 0 then Out_channel.output_char out_channel ',';
    let p50 = percentile stats.durations_ns 0.50 in
    let p95 = percentile stats.durations_ns 0.95 in
    let p99 = percentile stats.durations_ns 0.99 in
    let mean =
      if stats.call_count > 0
      then Int63.(stats.total_time_ns / of_int stats.call_count)
      else Int63.zero
    in
    let self_pct =
      if Int63.(total_ns > zero)
      then Int63.to_float stats.self_time_ns /. Int63.to_float total_ns *. 100.0
      else 0.0
    in
    Out_channel.fprintf
      out_channel
      {|{"name":%s,"self_pct":%.2f,"self_time_ns":%s,"total_time_ns":%s,"call_count":%d,"mean_ns":%s,"min_ns":%s,"max_ns":%s,"p50_ns":%s,"p95_ns":%s,"p99_ns":%s}|}
      (json_escape_string stats.name)
      self_pct
      (Int63.to_string stats.self_time_ns)
      (Int63.to_string stats.total_time_ns)
      stats.call_count
      (Int63.to_string mean)
      (Int63.to_string stats.min_duration_ns)
      (Int63.to_string stats.max_duration_ns)
      (Int63.to_string p50)
      (Int63.to_string p95)
      (Int63.to_string p99));
  Out_channel.fprintf out_channel "]}\n"
;;

let write_csv out_channel (result : Stack_aggregator.Result.t) =
  let total_ns = result.total_trace_time_ns in
  Out_channel.fprintf
    out_channel
    "function,self_pct,self_time_ns,total_time_ns,call_count,mean_ns,min_ns,max_ns,p50_ns,p95_ns,p99_ns\n";
  List.iter result.function_stats ~f:(fun stats ->
    let self_pct =
      if Int63.(total_ns > zero)
      then Int63.to_float stats.self_time_ns /. Int63.to_float total_ns *. 100.0
      else 0.0
    in
    let p50 = percentile stats.durations_ns 0.50 in
    let p95 = percentile stats.durations_ns 0.95 in
    let p99 = percentile stats.durations_ns 0.99 in
    let mean =
      if stats.call_count > 0
      then Int63.(stats.total_time_ns / of_int stats.call_count)
      else Int63.zero
    in
    (* CSV-escape the function name: wrap in quotes if it contains comma or quote *)
    let escaped_name =
      if String.exists stats.name ~f:(fun c -> Char.(c = ',' || c = '"'))
      then sprintf {|"%s"|} (String.concat_map stats.name ~f:(fun c ->
        if Char.(c = '"') then "\"\"" else String.of_char c))
      else stats.name
    in
    Out_channel.fprintf
      out_channel
      "%s,%.2f,%s,%s,%d,%s,%s,%s,%s,%s,%s\n"
      escaped_name
      self_pct
      (Int63.to_string stats.self_time_ns)
      (Int63.to_string stats.total_time_ns)
      stats.call_count
      (Int63.to_string mean)
      (Int63.to_string stats.min_duration_ns)
      (Int63.to_string stats.max_duration_ns)
      (Int63.to_string p50)
      (Int63.to_string p95)
      (Int63.to_string p99))
;;

let write out_channel result ~format =
  match format with
  | Output_format.Text -> write_text out_channel result
  | Json -> write_json out_channel result
  | Csv -> write_csv out_channel result
;;
