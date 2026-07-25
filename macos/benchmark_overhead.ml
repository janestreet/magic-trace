open Magic_trace_macos_lib

type measurement =
  { elapsed_seconds : float
  ; checksum : string
  }

let parse_measurement line =
  match String.split_on_char ' ' (String.trim line) with
  | [ elapsed; checksum ] ->
    let elapsed_seconds =
      match float_of_string_opt elapsed with
      | Some value when value > 0. -> value
      | _ -> failf "invalid benchmark elapsed time: %s" elapsed
    in
    { elapsed_seconds; checksum }
  | _ -> failf "invalid benchmark output: %S" line

let read_first_line path =
  let channel = open_in path in
  Fun.protect
    ~finally:(fun () -> close_in_noerr channel)
    (fun () ->
      try input_line channel with
      | End_of_file -> failf "benchmark produced no output")

let baseline demo iterations =
  let arguments = [| demo; "--iterations"; string_of_int iterations |] in
  let channel = Unix.open_process_args_in demo arguments in
  let line =
    try input_line channel with
    | End_of_file ->
      ignore (Unix.close_process_in channel);
      failf "baseline benchmark produced no output"
  in
  (match Unix.close_process_in channel with
   | Unix.WEXITED 0 -> parse_measurement line
   | Unix.WEXITED code -> failf "baseline benchmark failed with exit code %d" code
   | Unix.WSIGNALED signal -> failf "baseline benchmark was killed by signal %d" signal
   | Unix.WSTOPPED signal -> failf "baseline benchmark stopped on signal %d" signal)

let traced xctrace demo iterations =
  let rec attempt retries =
    try
      with_temporary_directory (fun directory ->
        let recording = Filename.concat directory "benchmark.trace" in
        let target_output = Filename.concat directory "target-output.txt" in
        record
          ~timeout_seconds:(Some 20.)
          ~target_stdout:(Some target_output)
          ~xctrace
          ~recording
          ~duration:"10s"
          ~target:(Command [ demo; "--iterations"; string_of_int iterations ]);
        read_first_line target_output |> parse_measurement)
    with
    | Error message when retries > 0 ->
      Printf.eprintf "xctrace retry after error: %s\n%!" message;
      ignore (Unix.select [] [] [] 0.5);
      attempt (retries - 1)
  in
  attempt 1

let mean values =
  List.fold_left ( +. ) 0. values /. float_of_int (List.length values)

let standard_deviation values =
  match values with
  | [] | [ _ ] -> 0.
  | _ ->
    let average = mean values in
    let squared_error =
      List.fold_left
        (fun total value ->
          let difference = value -. average in
          total +. (difference *. difference))
        0.
        values
    in
    sqrt (squared_error /. float_of_int (List.length values - 1))

let rec parse_options runs iterations demo = function
  | "--runs" :: value :: rest ->
    let runs =
      match int_of_string_opt value with
      | Some value when value >= 4 -> value
      | _ -> failf "--runs must be an integer of at least 4"
    in
    parse_options runs iterations demo rest
  | "--iterations" :: value :: rest ->
    let iterations =
      match int_of_string_opt value with
      | Some value when value > 0 -> value
      | _ -> failf "--iterations must be a positive integer"
    in
    parse_options runs iterations demo rest
  | [ value ] -> runs, iterations, value
  | [] -> failf "missing path to the compiled demo"
  | option :: _ -> failf "unknown benchmark option: %s" option

let run () =
  let arguments =
    match Array.to_list Sys.argv with
    | _ :: arguments -> arguments
    | [] -> []
  in
  let runs, iterations, demo = parse_options 10 5_000 "" arguments in
  let demo =
    match find_on_path demo with
    | Some path -> path
    | None -> failf "demo executable was not found: %s" demo
  in
  let xctrace = find_xctrace () in
  Printf.printf
    "Benchmarking %s with %d fixed iterations across %d balanced pairs.\n%!"
    demo
    iterations
    runs;
  ignore (baseline demo (max 1 (iterations / 10)));
  let pairs = ref [] in
  for index = 0 to runs - 1 do
    let baseline_result, traced_result =
      if index mod 2 = 0 then
        baseline demo iterations, traced xctrace demo iterations
      else
        let traced_result = traced xctrace demo iterations in
        let baseline_result = baseline demo iterations in
        baseline_result, traced_result
    in
    if not (String.equal baseline_result.checksum traced_result.checksum) then
      failf
        "checksum mismatch in run %d: baseline=%s traced=%s"
        (index + 1)
        baseline_result.checksum
        traced_result.checksum;
    let overhead =
      ((traced_result.elapsed_seconds /. baseline_result.elapsed_seconds) -. 1.) *. 100.
    in
    pairs := overhead :: !pairs;
    Printf.printf
      "run=%02d baseline=%.9fs traced=%.9fs overhead=%+.3f%%\n%!"
      (index + 1)
      baseline_result.elapsed_seconds
      traced_result.elapsed_seconds
      overhead
  done;
  let overheads = List.rev !pairs in
  let average = mean overheads in
  let deviation = standard_deviation overheads in
  let standard_error = deviation /. sqrt (float_of_int runs) in
  let lower = average -. (1.96 *. standard_error) in
  let upper = average +. (1.96 *. standard_error) in
  Printf.printf
    "summary runs=%d mean_overhead=%+.3f%% stdev=%.3f%% approximate_95%%_ci=[%+.3f%%,%+.3f%%]\n"
    runs
    average
    deviation
    lower
    upper;
  if upper <= 10. then
    Printf.printf "overhead_gate=PASS target=<=10%%\n"
  else (
    Printf.printf "overhead_gate=FAIL target=<=10%%\n";
    exit 1)

let () =
  try run () with
  | Error message ->
    Printf.eprintf "magic-trace-macos-benchmark: error: %s\n%!" message;
    exit 1
  | Unix.Unix_error (error, function_name, argument) ->
    Printf.eprintf
      "magic-trace-macos-benchmark: error: %s(%s): %s\n%!"
      function_name
      argument
      (Unix.error_message error);
    exit 1
