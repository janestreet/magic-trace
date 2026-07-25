open Magic_trace_macos_lib

let time_profile_xml =
  {|<?xml version="1.0"?>
<trace-query-result>
  <node>
    <schema name="time-profile"/>
    <row>
      <sample-time id="1">1000000</sample-time>
      <thread id="2" fmt="Main Thread (0x123) (target, pid: 42)">
        <tid id="3">291</tid>
        <process id="4" fmt="target (42)"><pid id="5">42</pid></process>
      </thread>
      <process ref="4"/>
      <core id="6">1</core>
      <thread-state id="7">Running</thread-state>
      <weight id="8">1000000</weight>
      <tagged-backtrace id="9">
        <backtrace id="10">
          <frame id="11" name="leaf_a&lt;T&gt;" addr="0x1010">
            <binary id="12" name="target" path="/tmp/target"/>
          </frame>
          <frame id="13" name="root" addr="0x1000"><binary ref="12"/></frame>
        </backtrace>
      </tagged-backtrace>
    </row>
    <row>
      <sample-time id="14">2000000</sample-time>
      <thread ref="2"/>
      <process ref="4"/>
      <core ref="6"/>
      <thread-state ref="7"/>
      <weight ref="8"/>
      <tagged-backtrace id="15">
        <backtrace id="16">
          <frame id="17" name="leaf_b" addr="0x1020"><binary ref="12"/></frame>
          <frame ref="13"/>
        </backtrace>
      </tagged-backtrace>
    </row>
    <row>
      <sample-time id="18">10000000</sample-time>
      <thread ref="2"/>
      <process ref="4"/>
      <sentinel/>
      <thread-state ref="7"/>
      <weight ref="8"/>
      <tagged-backtrace ref="15"/>
    </row>
  </node>
</trace-query-result>
|}

let fail format = Printf.ksprintf (fun message -> failwith message) format

let check condition format =
  Printf.ksprintf (fun message -> if not condition then failwith message) format

let check_equal_int expected actual label =
  check (expected = actual) "%s: expected %d, got %d" label expected actual

let check_equal_int64 expected actual label =
  check
    (Int64.equal expected actual)
    "%s: expected %Ld, got %Ld"
    label
    expected
    actual

let with_temp_file contents action =
  let path = Filename.temp_file "magic-trace-macos-test-" ".xml" in
  let channel = open_out_bin path in
  output_string channel contents;
  close_out channel;
  Fun.protect ~finally:(fun () -> Sys.remove path) (fun () -> action path)

let parsed_samples () = with_temp_file time_profile_xml parse_time_profile_xml

let test_duration () =
  check
    (String.equal (normalize_duration "5") "5s")
    "bare duration was not normalized";
  check
    (String.equal (normalize_duration "500ms") "500ms")
    "explicit duration unit changed";
  match normalize_duration "soon" with
  | _ -> fail "invalid duration was accepted"
  | exception Error _ -> ()

let test_parser () =
  let samples = parsed_samples () in
  check_equal_int 3 (List.length samples) "sample count";
  let first = List.hd samples in
  check_equal_int 42 first.pid "pid";
  check_equal_int 291 first.tid "tid";
  check (String.equal first.process_name "target") "unexpected process name";
  check
    (String.equal first.thread_name "Main Thread (0x123)")
    "unexpected thread name";
  check
    (String.equal (List.hd first.frames_leaf_first).name "leaf_a<T>")
    "XML entities were not decoded";
  let second = List.nth samples 1 in
  check
    (List.map (fun frame -> frame.name) second.frames_leaf_first = [ "leaf_b"; "root" ])
    "frame references were not resolved"

let test_intervals () =
  let intervals = parsed_samples () |> samples_to_intervals in
  let named name = List.filter (fun interval -> String.equal interval.frame.name name) intervals in
  let root = named "root" in
  check_equal_int 2 (List.length root) "root interval count";
  let first_root = List.hd root in
  check_equal_int64 1_000_000L first_root.start_ns "root start";
  check_equal_int64 3_000_000L first_root.end_ns "root end";
  check_equal_int 1 (List.length (named "leaf_a<T>")) "leaf_a interval count";
  check_equal_int 2 (List.length (named "leaf_b")) "leaf_b interval count"

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

let test_json () =
  let document = parsed_samples () |> build_trace_document in
  check_equal_int 3 document.sample_count "document sample count";
  check_equal_int64
    1_000_000L
    document.sampling_period_ns
    "document sampling period";
  let output = Filename.temp_file "magic-trace-macos-test-" ".json" in
  Fun.protect
    ~finally:(fun () -> Sys.remove output)
    (fun () ->
      write_trace_document document output;
      check (file_contains output {|"implementation":"OCaml"|}) "OCaml metadata missing";
      check (file_contains output {|"name":"leaf_a<T>"|}) "duration event missing";
      check
        (not (file_contains output {|true}}}|}))
        "duration event contains an extra closing brace")

let tests =
  [ "duration", test_duration
  ; "xctrace XML parser", test_parser
  ; "sample interval reconstruction", test_intervals
  ; "Chrome trace JSON writer", test_json
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
