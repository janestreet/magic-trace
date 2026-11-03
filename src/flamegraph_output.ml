open! Core

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

let write_collapsed out_channel (result : Stack_aggregator.Result.t) =
  List.iter result.collapsed_stacks ~f:(fun { frames; time_ns } ->
    let stack_str = String.concat ~sep:";" frames in
    Out_channel.fprintf out_channel "%s %s\n" stack_str (Int63.to_string time_ns))
;;

let write_speedscope_json out_channel (result : Stack_aggregator.Result.t) ~title =
  (* Speedscope "sampled" profile format:
     https://www.speedscope.app/file-format-spec.html *)
  let all_frames = String.Table.create () in
  let next_frame_id = ref 0 in
  let get_frame_id name =
    Hashtbl.find_or_add all_frames name ~default:(fun () ->
      let id = !next_frame_id in
      incr next_frame_id;
      id)
  in
  (* Pre-scan to assign frame IDs *)
  List.iter result.collapsed_stacks ~f:(fun { frames; _ } ->
    List.iter frames ~f:(fun name -> ignore (get_frame_id name : int)));
  (* Build the shared frames array *)
  let frames_array =
    Hashtbl.to_alist all_frames
    |> List.sort ~compare:(fun (_, a) (_, b) -> Int.compare a b)
    |> List.map ~f:(fun (name, _) ->
      sprintf {|{"name":%s}|} (json_escape_string name))
    |> String.concat ~sep:","
  in
  (* Build the samples and weights arrays *)
  let samples_buf = Buffer.create 1024 in
  let weights_buf = Buffer.create 256 in
  let first = ref true in
  List.iter result.collapsed_stacks ~f:(fun { frames; time_ns } ->
    if not !first
    then (
      Buffer.add_char samples_buf ',';
      Buffer.add_char weights_buf ',');
    first := false;
    let frame_ids = List.map frames ~f:get_frame_id in
    Buffer.add_char samples_buf '[';
    Buffer.add_string samples_buf
      (String.concat ~sep:"," (List.map frame_ids ~f:Int.to_string));
    Buffer.add_char samples_buf ']';
    Buffer.add_string weights_buf (Int63.to_string time_ns));
  Out_channel.fprintf
    out_channel
    {|{"$schema":"https://www.speedscope.app/file-format-schema.json","version":"0.0.1","shared":{"frames":[%s]},"profiles":[{"type":"sampled","name":%s,"unit":"nanoseconds","startValue":"0","endValue":"%s","samples":[%s],"weights":[%s]}],"name":%s,"activeProfileIndex":0}|}
    frames_array
    (json_escape_string title)
    (Int63.to_string result.total_trace_time_ns)
    (Buffer.contents samples_buf)
    (Buffer.contents weights_buf)
    (json_escape_string title);
  Out_channel.newline out_channel
;;

let write_html out_channel (result : Stack_aggregator.Result.t) ~title =
  (* Self-contained HTML flame graph using d3-flame-graph from CDN.
     We build a nested JSON tree from the collapsed stacks. *)
  let module Node = struct
    type t =
      { name : string
      ; mutable value : Int63.t
      ; children : t String.Table.t
      }

    let create name = { name; value = Int63.zero; children = String.Table.create () }

    let rec to_json t =
      let children_json =
        Hashtbl.data t.children
        |> List.sort ~compare:(fun a b -> Int63.compare b.value a.value)
        |> List.map ~f:to_json
        |> String.concat ~sep:","
      in
      sprintf
        {|{"name":%s,"value":%s,"children":[%s]}|}
        (json_escape_string t.name)
        (Int63.to_string t.value)
        children_json
    ;;
  end
  in
  let root = Node.create "root" in
  List.iter result.collapsed_stacks ~f:(fun { frames; time_ns } ->
    let node = ref root in
    List.iter frames ~f:(fun frame_name ->
      let child =
        Hashtbl.find_or_add !node.children frame_name ~default:(fun () ->
          Node.create frame_name)
      in
      child.value <- Int63.(child.value + time_ns);
      node := child);
    root.value <- Int63.(root.value + time_ns));
  let data_json = Node.to_json root in
  let escaped_title =
    String.concat_map title ~f:(fun c ->
      match c with
      | '<' -> "&lt;"
      | '>' -> "&gt;"
      | '&' -> "&amp;"
      | '"' -> "&quot;"
      | c -> String.of_char c)
  in
  Out_channel.fprintf
    out_channel
    {|<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>%s - magic-trace flamegraph</title>
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/d3-flame-graph@4/dist/d3-flamegraph.css">
<style>
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 0; padding: 20px; background: #fff; color: #333; }
@media (prefers-color-scheme: dark) { body { background: #1a1a2e; color: #e0e0e0; } }
h1 { font-size: 1.4em; margin: 0 0 4px 0; }
.subtitle { color: #666; font-size: 0.85em; margin-bottom: 16px; }
@media (prefers-color-scheme: dark) { .subtitle { color: #999; } }
#chart { min-height: 400px; }
</style>
</head>
<body>
<h1>%s</h1>
<p class="subtitle">Generated by magic-trace analyze</p>
<div id="chart"></div>
<script src="https://cdn.jsdelivr.net/npm/d3@7/dist/d3.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/d3-flame-graph@4/dist/d3-flamegraph.min.js"></script>
<script>
var data = %s;
var chart = flamegraph().width(document.body.clientWidth - 40).cellHeight(18).transitionDuration(300).tooltip(true);
d3.select("#chart").datum(data).call(chart);
window.addEventListener("resize", function() { chart.width(document.body.clientWidth - 40); d3.select("#chart").datum(data).call(chart); });
</script>
</body>
</html>
|}
    escaped_title
    escaped_title
    data_json
;;
