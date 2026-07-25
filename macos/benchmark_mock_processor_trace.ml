open Mock_processor_trace

let fail format = Printf.ksprintf (fun message -> raise (Invalid_argument message)) format

let positive_int name value =
  match int_of_string_opt value with
  | Some value when value > 0 -> value
  | _ -> fail "%s must be a positive integer" name

let option_value name = function
  | value :: rest -> value, rest
  | [] -> fail "missing value for %s" name

let usage () =
  Printf.printf
    {|Benchmark the OCaml synthetic Processor Trace decoder.

Usage:
  benchmark_mock_processor_trace [--events N] [--runs N] [--no-gate]

The default stream contains 10,000,000 virtual events at 40 ns spacing. The
gate requires decoding at least 25,000,000 events/second, the rate represented
by one 40 ns event slot. Decoding happens after capture on real hardware.
|};
  exit 0

let rec parse events runs gate = function
  | "--events" :: rest ->
    let value, rest = option_value "--events" rest in
    parse (positive_int "--events" value) runs gate rest
  | "--runs" :: rest ->
    let value, rest = option_value "--runs" rest in
    parse events (positive_int "--runs" value) gate rest
  | "--no-gate" :: rest -> parse events runs false rest
  | ("--help" | "-help" | "-h") :: _ -> usage ()
  | option :: _ -> fail "unknown option: %s" option
  | [] -> events, runs, gate

let median values =
  let sorted = List.sort Float.compare values in
  List.nth sorted (List.length sorted / 2)

let run () =
  let arguments =
    match Array.to_list Sys.argv with
    | _ :: arguments -> arguments
    | [] -> []
  in
  let requested_events, runs, gate = parse 10_000_000 5 true arguments in
  let cycles = max 1 ((requested_events + 9) / 10) in
  let trace = generate ~resolution_ns:40L ~anchor_every:4_096 ~cycles () in
  let events = event_count trace in
  let bytes = packet_bytes trace in
  let required_rate = 1_000_000_000. /. Int64.to_float (resolution_ns trace) in
  Printf.printf
    "model events=%d packet_bytes=%d bytes_per_event=%.4f \
     virtual_duration=%.3fs required_rate=%.3fM_events/s\n%!"
    events
    bytes
    (float_of_int bytes /. float_of_int events)
    (float_of_int events /. required_rate)
    (required_rate /. 1_000_000.);
  ignore (decode trace);
  let rates = ref [] in
  let expected_checksum = ref None in
  for index = 1 to runs do
    let started = Unix.gettimeofday () in
    let stats = decode trace in
    let elapsed = Unix.gettimeofday () -. started in
    let rate = float_of_int stats.event_count /. elapsed in
    (match !expected_checksum with
     | None -> expected_checksum := Some stats.checksum
     | Some expected when not (Int64.equal expected stats.checksum) ->
       fail "decoder checksum changed between runs"
     | Some _ -> ());
    rates := rate :: !rates;
    Printf.printf
      "run=%02d elapsed=%.6fs decode_rate=%.3fM_events/s realtime=%.2fx \
       checksum=%Lx\n%!"
      index
      elapsed
      (rate /. 1_000_000.)
      (rate /. required_rate)
      stats.checksum
  done;
  let median_rate = median !rates in
  let stream_rate_bytes = required_rate *. (float_of_int bytes /. float_of_int events) in
  Printf.printf
    "summary median_decode_rate=%.3fM_events/s required_stream_rate=%.3fMB/s \
     decoder_realtime_gate=%s target=>=%.3fM_events/s\n"
    (median_rate /. 1_000_000.)
    (stream_rate_bytes /. 1_000_000.)
    (if median_rate >= required_rate then "PASS" else "FAIL")
    (required_rate /. 1_000_000.);
  if gate && median_rate < required_rate then exit 1

let () =
  try run () with
  | Invalid_argument message | Decode_error message ->
    Printf.eprintf "mock-processor-trace-benchmark: error: %s\n%!" message;
    exit 1
