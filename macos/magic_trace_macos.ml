open Magic_trace_macos_lib

type recording_options =
  { duration : string
  ; output : string
  ; keep_recording : string option
  ; force : bool
  }

let default_recording_options =
  { duration = "5s"
  ; output = "trace.json.gz"
  ; keep_recording = None
  ; force = false
  }

let usage () =
  Printf.printf
    {|Experimental magic-trace backend for Apple Silicon Macs.

Usage:
  magic_trace_macos run [OPTIONS] -- COMMAND [ARGUMENTS...]
  magic_trace_macos attach -pid PID [OPTIONS]
  magic_trace_macos convert PROFILE.xml [-output TRACE.json.gz] [--force]

Recording options:
  -duration, --duration TIME        Recording duration (default: 5s)
  -output, --output FILE           Output trace (default: trace.json.gz)
  --keep-recording FILE.trace      Keep the Instruments recording
  --force                          Replace an existing output trace

This backend uses Xcode's 1 ms Time Profiler samples. Function boundaries in
the resulting trace are estimates; short calls may not appear.
|};
  exit 0

let option_value name = function
  | value :: rest -> value, rest
  | [] -> failf "missing value for %s" name

let rec parse_recording_options options = function
  | ("-duration" | "--duration") as name :: rest ->
    let value, rest = option_value name rest in
    parse_recording_options { options with duration = value } rest
  | ("-output" | "--output") as name :: rest ->
    let value, rest = option_value name rest in
    parse_recording_options { options with output = value } rest
  | "--keep-recording" as name :: rest ->
    let value, rest = option_value name rest in
    parse_recording_options { options with keep_recording = Some value } rest
  | "--force" :: rest -> parse_recording_options { options with force = true } rest
  | rest -> options, rest

let run arguments =
  let options, rest = parse_recording_options default_recording_options arguments in
  let command =
    match rest with
    | "--" :: command -> command
    | command -> command
  in
  if command = [] then failf "missing command after --";
  record_and_convert
    ~duration:options.duration
    ~output:options.output
    ~keep_recording:options.keep_recording
    ~force:options.force
    ~target:(Command command)

let attach arguments =
  let rec parse pid options arguments =
    match arguments with
    | ("-pid" | "--pid") as name :: rest ->
      let value, rest = option_value name rest in
      let pid =
        match int_of_string_opt value with
        | Some pid when pid > 0 -> pid
        | _ -> failf "invalid pid: %s" value
      in
      parse (Some pid) options rest
    | ("-duration" | "--duration") as name :: rest ->
      let value, rest = option_value name rest in
      parse pid { options with duration = value } rest
    | ("-output" | "--output") as name :: rest ->
      let value, rest = option_value name rest in
      parse pid { options with output = value } rest
    | "--keep-recording" as name :: rest ->
      let value, rest = option_value name rest in
      parse pid { options with keep_recording = Some value } rest
    | "--force" :: rest -> parse pid { options with force = true } rest
    | [] -> pid, options
    | option :: _ -> failf "unknown attach option: %s" option
  in
  let pid, options = parse None default_recording_options arguments in
  let pid =
    match pid with
    | Some pid -> pid
    | None -> failf "attach requires -pid PID"
  in
  record_and_convert
    ~duration:options.duration
    ~output:options.output
    ~keep_recording:options.keep_recording
    ~force:options.force
    ~target:(Pid pid)

let convert arguments =
  let rec parse profile_xml output force = function
    | ("-output" | "--output") as name :: rest ->
      let value, rest = option_value name rest in
      parse profile_xml value force rest
    | "--force" :: rest -> parse profile_xml output true rest
    | value :: rest when not (String.starts_with ~prefix:"-" value) ->
      (match profile_xml with
       | None -> parse (Some value) output force rest
       | Some _ -> failf "unexpected convert argument: %s" value)
    | option :: _ -> failf "unknown convert option: %s" option
    | [] -> profile_xml, output, force
  in
  let profile_xml, output, force = parse None "trace.json.gz" false arguments in
  let profile_xml =
    match profile_xml with
    | Some path -> path
    | None -> failf "convert requires an exported time-profile XML file"
  in
  convert_export ~profile_xml ~output ~force

let main () =
  match Array.to_list Sys.argv with
  | _ :: ("-help" | "--help" | "help") :: _ -> usage ()
  | _ :: "run" :: arguments -> run arguments
  | _ :: "attach" :: arguments -> attach arguments
  | _ :: "convert" :: arguments -> convert arguments
  | _ -> failf "expected run, attach, or convert; pass --help for usage"

let () =
  try main () with
  | Error message ->
    Printf.eprintf "magic-trace-macos: error: %s\n%!" message;
    exit 1
  | Unix.Unix_error (error, function_name, argument) ->
    Printf.eprintf
      "magic-trace-macos: error: %s(%s): %s\n%!"
      function_name
      argument
      (Unix.error_message error);
    exit 1
