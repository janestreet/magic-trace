open Mock_processor_trace

let fail format = Printf.ksprintf (fun message -> raise (Invalid_argument message)) format

let usage () =
  Printf.printf
    {|Synthetic 40 ns Processor Trace model, implemented in OCaml.

Usage:
  mock_processor_trace_cli [OPTIONS]

Options:
  --cycles N           Nested demo cycles (default: 1000)
  --resolution-ns N    Virtual event spacing (default: 40)
  --anchor-every N     Events between timing anchors (default: 4096)
  --output FILE        Perfetto JSON output (default: mock-40ns-trace.json)
  --force              Replace an existing output
  --help                Show this help

The output can be opened at https://ui.perfetto.dev or
https://magic-trace.org. This is a performance model, not a claim that an M1
can capture real programs at 40 ns.
|};
  exit 0

let positive_int name value =
  match int_of_string_opt value with
  | Some value when value > 0 -> value
  | _ -> fail "%s must be a positive integer" name

let positive_int64 name value =
  match Int64.of_string_opt value with
  | Some value when Int64.compare value 1L >= 0 -> value
  | _ -> fail "%s must be a positive integer" name

let option_value name = function
  | value :: rest -> value, rest
  | [] -> fail "missing value for %s" name

let rec parse cycles resolution_ns anchor_every output force = function
  | "--cycles" :: rest ->
    let value, rest = option_value "--cycles" rest in
    parse (positive_int "--cycles" value) resolution_ns anchor_every output force rest
  | "--resolution-ns" :: rest ->
    let value, rest = option_value "--resolution-ns" rest in
    parse
      cycles
      (positive_int64 "--resolution-ns" value)
      anchor_every
      output
      force
      rest
  | "--anchor-every" :: rest ->
    let value, rest = option_value "--anchor-every" rest in
    parse
      cycles
      resolution_ns
      (positive_int "--anchor-every" value)
      output
      force
      rest
  | "--output" :: rest ->
    let value, rest = option_value "--output" rest in
    parse cycles resolution_ns anchor_every value force rest
  | "--force" :: rest -> parse cycles resolution_ns anchor_every output true rest
  | ("--help" | "-help" | "-h") :: _ -> usage ()
  | option :: _ -> fail "unknown option: %s" option
  | [] -> cycles, resolution_ns, anchor_every, output, force

let run () =
  let arguments =
    match Array.to_list Sys.argv with
    | _ :: arguments -> arguments
    | [] -> []
  in
  let cycles, resolution_ns, anchor_every, output, force =
    parse 1_000 40L 4_096 "mock-40ns-trace.json" false arguments
  in
  let trace = generate ~resolution_ns ~anchor_every ~cycles () in
  let stats = write_trace_json ~force trace output in
  Printf.printf
    "wrote=%s events=%d calls=%d resolution=%Ldns virtual_duration=%.3fms \
     packet_bytes=%d bytes_per_event=%.4f checksum=%Lx\n"
    output
    stats.event_count
    stats.call_count
    stats.resolution_ns
    (Int64.to_float stats.virtual_duration_ns /. 1_000_000.)
    stats.packet_bytes
    (float_of_int stats.packet_bytes /. float_of_int stats.event_count)
    stats.checksum

let () =
  try run () with
  | Invalid_argument message | Decode_error message ->
    Printf.eprintf "mock-processor-trace: error: %s\n%!" message;
    exit 1
  | Sys_error message ->
    Printf.eprintf "mock-processor-trace: error: %s\n%!" message;
    exit 1
