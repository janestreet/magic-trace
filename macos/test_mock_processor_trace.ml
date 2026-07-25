open Mock_processor_trace

let check condition format =
  Printf.ksprintf (fun message -> if not condition then failwith message) format

let check_int expected actual label =
  check (expected = actual) "%s: expected %d, got %d" label expected actual

let check_int64 expected actual label =
  check
    (Int64.equal expected actual)
    "%s: expected %Ld, got %Ld"
    label
    expected
    actual

let test_exact_reconstruction () =
  let trace = generate ~resolution_ns:40L ~anchor_every:4 ~cycles:2 () in
  let intervals = ref [] in
  let stats = decode ~on_interval:(fun interval -> intervals := interval :: !intervals) trace in
  check_int 20 stats.event_count "event count";
  check_int 10 stats.call_count "call count";
  check_int 10 stats.return_count "return count";
  check_int 5 stats.anchor_count "anchor count";
  check_int 3 stats.max_depth "maximum depth";
  check_int64 800L stats.virtual_duration_ns "virtual duration";
  let repeated_stats = decode trace in
  check_int64 stats.checksum repeated_stats.checksum "deterministic checksum";
  let intervals = List.rev !intervals in
  let first_named name =
    match List.find_opt (fun interval -> String.equal interval.function_name name) intervals with
    | Some interval -> interval
    | None -> failwith ("missing interval " ^ name)
  in
  let main = first_named "main" in
  check_int64 0L main.start_ns "main start";
  check_int64 360L main.end_ns "main end";
  check_int 0 main.depth "main depth";
  let work_a = first_named "work_a" in
  check_int64 40L work_a.start_ns "work_a start";
  check_int64 160L work_a.end_ns "work_a end";
  let scramble = first_named "scramble" in
  check_int64 80L scramble.start_ns "scramble start";
  check_int64 120L scramble.end_ns "scramble end"

let file_contains path needle =
  let channel = open_in_bin path in
  let contents =
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () -> really_input_string channel (in_channel_length channel))
  in
  let needle_length = String.length needle in
  let rec search index =
    index + needle_length <= String.length contents
    && (String.sub contents index needle_length = needle || search (index + 1))
  in
  search 0

let test_json_output () =
  let trace = generate ~cycles:1 () in
  let path = Filename.temp_file "magic-trace-mock-" ".json" in
  Sys.remove path;
  Fun.protect
    ~finally:(fun () -> if Sys.file_exists path then Sys.remove path)
    (fun () ->
      let stats = write_trace_json ~force:false trace path in
      check_int 10 stats.event_count "JSON event count";
      check (file_contains path {|"simulated":true|}) "simulated marker missing";
      check (file_contains path {|"resolutionNs":40|}) "40 ns resolution missing";
      check (file_contains path {|"name":"work_a"|}) "work_a interval missing";
      match write_trace_json ~force:false trace path with
      | _ -> failwith "existing output was replaced without --force"
      | exception Decode_error _ -> ())

let tests =
  [ "exact 40 ns reconstruction", test_exact_reconstruction
  ; "Perfetto JSON output", test_json_output
  ]

let () =
  List.iter
    (fun (name, test) ->
      try
        test ();
        Printf.printf "ok - %s\n%!" name
      with
      | error ->
        Printf.eprintf "not ok - %s: %s\n%!" name (Printexc.to_string error);
        exit 1)
    tests
