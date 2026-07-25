exception Error of string

let failf format = Printf.ksprintf (fun message -> raise (Error message)) format

type frame =
  { name : string
  ; binary_name : string
  ; binary_path : string
  ; address : string
  }

type sample =
  { time_ns : int64
  ; weight_ns : int64
  ; pid : int
  ; process_name : string
  ; tid : int
  ; thread_name : string
  ; frames_leaf_first : frame list
  }

type interval =
  { start_ns : int64
  ; end_ns : int64
  ; pid : int
  ; tid : int
  ; depth : int
  ; frame : frame
  }

type trace_document =
  { sample_count : int
  ; sampling_period_ns : int64
  ; intervals : interval list
  ; processes : (int * string) list
  ; threads : ((int * int) * string) list
  }

type target =
  | Pid of int
  | Command of string list

module Xml = struct
  type element =
    { tag : string
    ; attributes : (string * string) list
    ; text : string
    ; children : element list
    }

  type parser =
    { input : string
    ; length : int
    ; mutable position : int
    }

  let is_space = function
    | ' ' | '\t' | '\r' | '\n' -> true
    | _ -> false

  let starts_with parser prefix =
    let prefix_length = String.length prefix in
    parser.position + prefix_length <= parser.length
    && String.sub parser.input parser.position prefix_length = prefix

  let skip_spaces parser =
    while
      parser.position < parser.length && is_space parser.input.[parser.position]
    do
      parser.position <- parser.position + 1
    done

  let expect_char parser expected =
    if
      parser.position >= parser.length
      || not (Char.equal parser.input.[parser.position] expected)
    then
      failf "invalid XML at byte %d: expected %C" parser.position expected;
    parser.position <- parser.position + 1

  let consume parser text =
    if not (starts_with parser text) then
      failf "invalid XML at byte %d: expected %s" parser.position text;
    parser.position <- parser.position + String.length text

  let substring_until parser delimiter =
    let delimiter_length = String.length delimiter in
    let rec search index =
      if index + delimiter_length > parser.length then
        failf "unterminated XML construct beginning at byte %d" parser.position
      else if String.sub parser.input index delimiter_length = delimiter then
        index
      else
        search (index + 1)
    in
    let finish = search parser.position in
    let result = String.sub parser.input parser.position (finish - parser.position) in
    parser.position <- finish + delimiter_length;
    result

  let add_utf8 buffer codepoint =
    if codepoint <= 0x7f then
      Buffer.add_char buffer (Char.chr codepoint)
    else if codepoint <= 0x7ff then (
      Buffer.add_char buffer (Char.chr (0xc0 lor (codepoint lsr 6)));
      Buffer.add_char buffer (Char.chr (0x80 lor (codepoint land 0x3f))))
    else if codepoint <= 0xffff then (
      Buffer.add_char buffer (Char.chr (0xe0 lor (codepoint lsr 12)));
      Buffer.add_char buffer (Char.chr (0x80 lor ((codepoint lsr 6) land 0x3f)));
      Buffer.add_char buffer (Char.chr (0x80 lor (codepoint land 0x3f))))
    else if codepoint <= 0x10ffff then (
      Buffer.add_char buffer (Char.chr (0xf0 lor (codepoint lsr 18)));
      Buffer.add_char buffer (Char.chr (0x80 lor ((codepoint lsr 12) land 0x3f)));
      Buffer.add_char buffer (Char.chr (0x80 lor ((codepoint lsr 6) land 0x3f)));
      Buffer.add_char buffer (Char.chr (0x80 lor (codepoint land 0x3f))))
    else
      failf "invalid Unicode code point in XML entity: %d" codepoint

  let decode_entities text =
    let buffer = Buffer.create (String.length text) in
    let length = String.length text in
    let rec loop position =
      if position >= length then
        Buffer.contents buffer
      else if not (Char.equal text.[position] '&') then (
        Buffer.add_char buffer text.[position];
        loop (position + 1))
      else (
        let rec find_semicolon index =
          if index >= length then failf "unterminated XML entity";
          if Char.equal text.[index] ';' then index else find_semicolon (index + 1)
        in
        let finish = find_semicolon (position + 1) in
        let entity = String.sub text (position + 1) (finish - position - 1) in
        (match entity with
         | "amp" -> Buffer.add_char buffer '&'
         | "lt" -> Buffer.add_char buffer '<'
         | "gt" -> Buffer.add_char buffer '>'
         | "quot" -> Buffer.add_char buffer '"'
         | "apos" -> Buffer.add_char buffer '\''
         | _ when String.length entity > 1 && Char.equal entity.[0] '#' ->
           let codepoint =
             try
               if
                 String.length entity > 2
                 && (Char.equal entity.[1] 'x' || Char.equal entity.[1] 'X')
               then
                 int_of_string ("0x" ^ String.sub entity 2 (String.length entity - 2))
               else
                 int_of_string (String.sub entity 1 (String.length entity - 1))
             with
             | Failure _ -> failf "invalid numeric XML entity: &%s;" entity
           in
           add_utf8 buffer codepoint
         | _ -> failf "unsupported XML entity: &%s;" entity);
        loop (finish + 1))
    in
    loop 0

  let parse_name parser =
    let start = parser.position in
    while
      parser.position < parser.length
      &&
      match parser.input.[parser.position] with
      | ' ' | '\t' | '\r' | '\n' | '/' | '>' | '=' | '?' -> false
      | _ -> true
    do
      parser.position <- parser.position + 1
    done;
    if parser.position = start then failf "expected XML name at byte %d" start;
    String.sub parser.input start (parser.position - start)

  let parse_attribute_value parser =
    if parser.position >= parser.length then failf "missing XML attribute value";
    let quote = parser.input.[parser.position] in
    if not (Char.equal quote '"' || Char.equal quote '\'') then
      failf "expected quoted XML attribute at byte %d" parser.position;
    parser.position <- parser.position + 1;
    let start = parser.position in
    while
      parser.position < parser.length
      && not (Char.equal parser.input.[parser.position] quote)
    do
      parser.position <- parser.position + 1
    done;
    if parser.position >= parser.length then failf "unterminated XML attribute value";
    let encoded = String.sub parser.input start (parser.position - start) in
    parser.position <- parser.position + 1;
    decode_entities encoded

  let rec skip_misc parser =
    skip_spaces parser;
    if starts_with parser "<?" then (
      consume parser "<?";
      ignore (substring_until parser "?>");
      skip_misc parser)
    else if starts_with parser "<!--" then (
      consume parser "<!--";
      ignore (substring_until parser "-->");
      skip_misc parser)
    else if starts_with parser "<!" then (
      consume parser "<!";
      ignore (substring_until parser ">");
      skip_misc parser)

  let rec parse_element parser =
    expect_char parser '<';
    if starts_with parser "/" then failf "unexpected XML closing tag";
    let tag = parse_name parser in
    let rec parse_attributes reversed =
      skip_spaces parser;
      if starts_with parser "/>" then (
        consume parser "/>";
        `Closed (List.rev reversed))
      else if starts_with parser ">" then (
        consume parser ">";
        `Open (List.rev reversed))
      else
        let name = parse_name parser in
        skip_spaces parser;
        expect_char parser '=';
        skip_spaces parser;
        let value = parse_attribute_value parser in
        parse_attributes ((name, value) :: reversed)
    in
    match parse_attributes [] with
    | `Closed attributes -> { tag; attributes; text = ""; children = [] }
    | `Open attributes ->
      let text = Buffer.create 32 in
      let rec parse_contents reversed_children =
        if parser.position >= parser.length then
          failf "unterminated XML element <%s>" tag
        else if starts_with parser "</" then (
          consume parser "</";
          let closing_tag = parse_name parser in
          if not (String.equal tag closing_tag) then
            failf "mismatched XML closing tag: expected </%s>, found </%s>" tag closing_tag;
          skip_spaces parser;
          expect_char parser '>';
          { tag
          ; attributes
          ; text = decode_entities (Buffer.contents text)
          ; children = List.rev reversed_children
          })
        else if starts_with parser "<!--" then (
          consume parser "<!--";
          ignore (substring_until parser "-->");
          parse_contents reversed_children)
        else if starts_with parser "<![CDATA[" then (
          consume parser "<![CDATA[";
          Buffer.add_string text (substring_until parser "]]>");
          parse_contents reversed_children)
        else if starts_with parser "<?" then (
          consume parser "<?";
          ignore (substring_until parser "?>");
          parse_contents reversed_children)
        else if starts_with parser "<" then
          let child = parse_element parser in
          parse_contents (child :: reversed_children)
        else (
          Buffer.add_char text parser.input.[parser.position];
          parser.position <- parser.position + 1;
          parse_contents reversed_children)
      in
      parse_contents []

  let parse_string input =
    let parser = { input; length = String.length input; position = 0 } in
    skip_misc parser;
    let root = parse_element parser in
    skip_misc parser;
    if parser.position <> parser.length then
      failf "unexpected XML content at byte %d" parser.position;
    root

  let read_file path =
    let channel = open_in_bin path in
    Fun.protect
      ~finally:(fun () -> close_in_noerr channel)
      (fun () ->
        let length = in_channel_length channel in
        really_input_string channel length)

  let parse_file path = parse_string (read_file path)
  let attribute element name = List.assoc_opt name element.attributes
end

module Resolver = struct
  type t =
    { ids : (string, Xml.element) Hashtbl.t
    ; mutable previous_columns : Xml.element option list
    }

  let create () = { ids = Hashtbl.create 1024; previous_columns = [] }

  let rec register_subtree resolver element =
    (match Xml.attribute element "id" with
     | Some identifier -> Hashtbl.replace resolver.ids identifier element
     | None -> ());
    List.iter (register_subtree resolver) element.Xml.children

  let resolve resolver element =
    let rec loop seen current =
      match Xml.attribute current "ref" with
      | None -> current
      | Some reference ->
        if List.mem reference seen then failf "cycle in xctrace XML references";
        let referenced =
          match Hashtbl.find_opt resolver.ids reference with
          | Some element -> element
          | None -> failf "xctrace XML refers to unknown id %s" reference
        in
        loop (reference :: seen) referenced
    in
    loop [] element

  let row_columns resolver row =
    let rec loop index previous reversed = function
      | [] ->
        let columns = List.rev reversed in
        resolver.previous_columns <- columns;
        columns
      | encoded :: rest ->
        let value =
          if String.equal encoded.Xml.tag "sentinel" then
            (match List.nth_opt previous index with
             | Some value -> value
             | None -> None)
          else (
            register_subtree resolver encoded;
            Some (resolve resolver encoded))
        in
        loop (index + 1) previous (value :: reversed) rest
    in
    loop 0 resolver.previous_columns [] row.Xml.children

  let child resolver element tags =
    match element with
    | None -> None
    | Some element ->
      let parent = resolve resolver element in
      List.find_map
        (fun child ->
          let child = resolve resolver child in
          if List.mem child.Xml.tag tags then Some child else None)
        parent.Xml.children

  let children resolver element tag =
    match element with
    | None -> []
    | Some element ->
      let parent = resolve resolver element in
      List.filter_map
        (fun child ->
          let child = resolve resolver child in
          if String.equal child.Xml.tag tag then Some child else None)
        parent.Xml.children
end

let trim = String.trim

let integer64 ?(default = 0L) = function
  | None -> default
  | Some element ->
    (match Int64.of_string_opt (trim element.Xml.text) with
     | Some value -> value
     | None -> default)

let integer ?(default = 0) element =
  let value = integer64 ~default:(Int64.of_int default) element in
  if
    Int64.compare value (Int64.of_int max_int) > 0
    || Int64.compare value (Int64.of_int min_int) < 0
  then
    default
  else
    Int64.to_int value

let formatted = function
  | None -> ""
  | Some element ->
    (match Xml.attribute element "fmt" with
     | Some value -> value
     | None -> trim element.Xml.text)

let all_digits value =
  String.length value > 0
  &&
  let rec loop index =
    index = String.length value
    || (Char.code value.[index] >= Char.code '0'
        && Char.code value.[index] <= Char.code '9'
        && loop (index + 1))
  in
  loop 0

let drop_process_pid_suffix value =
  let value = trim value in
  match String.rindex_opt value '(' with
  | None -> value
  | Some opening ->
    let length = String.length value in
    if
      opening > 0
      && Char.equal value.[opening - 1] ' '
      && Char.equal value.[length - 1] ')'
    then
      let inside = String.sub value (opening + 1) (length - opening - 2) in
      if all_digits inside then trim (String.sub value 0 (opening - 1)) else value
    else
      value

let drop_thread_process_suffix value =
  let value = trim value in
  match String.rindex_opt value '(' with
  | None -> value
  | Some opening ->
    let length = String.length value in
    let suffix = String.sub value opening (length - opening) in
    let contains_pid =
      let needle = ", pid: " in
      let needle_length = String.length needle in
      let rec search index =
        index + needle_length <= String.length suffix
        && (String.sub suffix index needle_length = needle || search (index + 1))
      in
      search 0
    in
    if opening > 0 && contains_pid && Char.equal value.[opening - 1] ' ' then
      trim (String.sub value 0 (opening - 1))
    else
      value

let rec elements_named tag element =
  let descendants = List.concat_map (elements_named tag) element.Xml.children in
  if String.equal element.Xml.tag tag then element :: descendants else descendants

let parse_time_profile_xml path =
  let root = Xml.parse_file path in
  let resolver = Resolver.create () in
  let samples = ref [] in
  List.iter
    (fun row ->
      let columns = Resolver.row_columns resolver row in
      let by_tag = Hashtbl.create (List.length columns) in
      List.iter
        (function
          | None -> ()
          | Some element -> Hashtbl.replace by_tag element.Xml.tag element)
        columns;
      let get tag = Hashtbl.find_opt by_tag tag in
      let sample_time = get "sample-time" in
      let thread = get "thread" in
      let process = get "process" in
      let weight = get "weight" in
      let tagged_backtrace = get "tagged-backtrace" in
      match thread, tagged_backtrace with
      | Some thread, Some tagged_backtrace ->
        let process =
          match process with
          | Some _ -> process
          | None -> Resolver.child resolver (Some thread) [ "process" ]
        in
        let tid = Resolver.child resolver (Some thread) [ "tid" ] in
        let pid = Resolver.child resolver process [ "pid" ] in
        let backtrace =
          Resolver.child resolver (Some tagged_backtrace) [ "backtrace" ]
        in
        (match backtrace with
         | None -> ()
         | Some backtrace ->
           let frames =
             Resolver.children resolver (Some backtrace) "frame"
             |> List.map (fun frame ->
               let binary = Resolver.child resolver (Some frame) [ "binary" ] in
               let attribute element name =
                 match element with
                 | None -> ""
                 | Some element -> Option.value ~default:"" (Xml.attribute element name)
               in
               let address = Option.value ~default:"" (Xml.attribute frame "addr") in
               let name =
                 match Xml.attribute frame "name" with
                 | Some name when not (String.equal name "") -> name
                 | _ when not (String.equal address "") -> address
                 | _ -> "[unknown]"
               in
               { name
               ; binary_name = attribute binary "name"
               ; binary_path = attribute binary "path"
               ; address
               })
           in
           if frames <> [] then
             let weight_ns = integer64 ~default:1_000_000L weight in
             samples :=
               { time_ns = integer64 sample_time
               ; weight_ns = if Int64.compare weight_ns 1L < 0 then 1L else weight_ns
               ; pid = integer pid
               ; process_name =
                   (let name = drop_process_pid_suffix (formatted process) in
                    if String.equal name "" then "process" else name)
               ; tid = integer tid
               ; thread_name =
                   (let name = drop_thread_process_suffix (formatted (Some thread)) in
                    if String.equal name "" then "thread" else name)
               ; frames_leaf_first = frames
               }
               :: !samples)
      | _ -> ())
    (elements_named "row" root);
  List.rev !samples

let rec take count values =
  if count <= 0 then
    []
  else
    match values with
    | [] -> []
    | value :: rest -> value :: take (count - 1) rest

let rec drop count values =
  if count <= 0 then
    values
  else
    match values with
    | [] -> []
    | _ :: rest -> drop (count - 1) rest

let common_prefix_length active stack =
  let rec loop count active stack =
    match active, stack with
    | (active_frame, _) :: active_rest, stack_frame :: stack_rest
      when active_frame = stack_frame -> loop (count + 1) active_rest stack_rest
    | _ -> count
  in
  loop 0 active stack

let samples_to_intervals (samples : sample list) =
  let groups : ((int * int), sample list) Hashtbl.t = Hashtbl.create 16 in
  List.iter
    (fun (sample : sample) ->
      let key = sample.pid, sample.tid in
      let previous = Option.value ~default:[] (Hashtbl.find_opt groups key) in
      Hashtbl.replace groups key (sample :: previous))
    samples;
  let intervals = ref [] in
  Hashtbl.iter
    (fun (pid, tid) thread_samples ->
      let thread_samples =
        List.sort (fun left right -> Int64.compare left.time_ns right.time_ns) thread_samples
      in
      let active = ref [] in
      let active_until_ns = ref 0L in
      let close_active keep_prefix end_ns =
        let closing = drop keep_prefix !active in
        List.iteri
          (fun offset (frame, start_ns) ->
            if Int64.compare end_ns start_ns > 0 then
              intervals :=
                { start_ns
                ; end_ns
                ; pid
                ; tid
                ; depth = keep_prefix + offset
                ; frame
                }
                :: !intervals)
          closing;
        active := take keep_prefix !active
      in
      List.iter
        (fun sample ->
          let stack_root_first = List.rev sample.frames_leaf_first in
          let half_weight_ns = Int64.div sample.weight_ns 2L in
          let gap_tolerance_ns =
            if Int64.compare half_weight_ns 100_000L < 0
            then 100_000L
            else half_weight_ns
          in
          if
            !active <> []
            && Int64.compare sample.time_ns (Int64.add !active_until_ns gap_tolerance_ns)
               > 0
          then
            close_active 0 !active_until_ns;
          let common_prefix = common_prefix_length !active stack_root_first in
          close_active common_prefix sample.time_ns;
          let newly_active =
            drop common_prefix stack_root_first
            |> List.map (fun frame -> frame, sample.time_ns)
          in
          active := !active @ newly_active;
          let sample_end = Int64.add sample.time_ns sample.weight_ns in
          if Int64.compare sample_end !active_until_ns > 0 then
            active_until_ns := sample_end)
        thread_samples;
      if !active <> [] then close_active 0 !active_until_ns)
    groups;
  List.rev !intervals

let build_trace_document (samples : sample list) =
  if samples = [] then
    failf
      "Time Profiler produced no symbolicated samples. Try a longer recording or a \
       CPU-bound target.";
  let process_names = Hashtbl.create 8 in
  let thread_names = Hashtbl.create 16 in
  List.iter
    (fun (sample : sample) ->
      if not (Hashtbl.mem process_names sample.pid) then
        Hashtbl.add process_names sample.pid sample.process_name;
      let key = sample.pid, sample.tid in
      if not (Hashtbl.mem thread_names key) then
        Hashtbl.add thread_names key sample.thread_name)
    samples;
  let processes =
    Hashtbl.fold (fun pid name result -> (pid, name) :: result) process_names []
    |> List.sort (fun (left, _) (right, _) -> Int.compare left right)
  in
  let threads =
    Hashtbl.fold (fun key name result -> (key, name) :: result) thread_names []
    |> List.sort (fun ((left_pid, left_tid), _) ((right_pid, right_tid), _) ->
      match Int.compare left_pid right_pid with
      | 0 -> Int.compare left_tid right_tid
      | order -> order)
  in
  let intervals =
    samples_to_intervals samples
    |> List.sort (fun left right ->
      match Int64.compare left.start_ns right.start_ns with
      | 0 ->
        let left_duration = Int64.sub left.end_ns left.start_ns in
        let right_duration = Int64.sub right.end_ns right.start_ns in
        (match Int64.compare right_duration left_duration with
         | 0 -> Int.compare left.depth right.depth
         | order -> order)
      | order -> order)
  in
  let sampling_period_ns =
    let weights =
      List.map (fun (sample : sample) -> sample.weight_ns) samples
      |> List.sort Int64.compare
    in
    List.nth weights (List.length weights / 2)
  in
  { sample_count = List.length samples
  ; sampling_period_ns
  ; intervals
  ; processes
  ; threads
  }

let output_json_string channel value =
  output_char channel '"';
  String.iter
    (fun character ->
      match character with
      | '"' -> output_string channel "\\\""
      | '\\' -> output_string channel "\\\\"
      | '\b' -> output_string channel "\\b"
      | '\012' -> output_string channel "\\f"
      | '\n' -> output_string channel "\\n"
      | '\r' -> output_string channel "\\r"
      | '\t' -> output_string channel "\\t"
      | character when Char.code character < 0x20 ->
        Printf.fprintf channel "\\u%04x" (Char.code character)
      | character -> output_char channel character)
    value;
  output_char channel '"'

let output_event_separator channel first =
  if !first then first := false else output_char channel ','

let write_uncompressed_trace document path =
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      output_string channel {|{"displayTimeUnit":"ns","traceEvents":[|};
      let first = ref true in
      List.iter
        (fun (pid, name) ->
          output_event_separator channel first;
          Printf.fprintf channel {|{"name":"process_name","ph":"M","pid":%d,"tid":0,"args":{"name":|} pid;
          output_json_string channel name;
          output_string channel "}}")
        document.processes;
      List.iter
        (fun ((pid, tid), name) ->
          output_event_separator channel first;
          Printf.fprintf
            channel
            {|{"name":"thread_name","ph":"M","pid":%d,"tid":%d,"args":{"name":|}
            pid
            tid;
          output_json_string channel name;
          output_string channel "}}")
        document.threads;
      List.iter
        (fun interval ->
          output_event_separator channel first;
          output_string channel {|{"name":|};
          output_json_string channel interval.frame.name;
          Printf.fprintf
            channel
            {|,"cat":"macOS Time Profiler (sampled)","ph":"X","ts":%.3f,"dur":%.3f,"pid":%d,"tid":%d,"args":{"module":|}
            (Int64.to_float interval.start_ns /. 1_000.)
            (max
               (Int64.to_float (Int64.sub interval.end_ns interval.start_ns) /. 1_000.)
               0.001)
            interval.pid
            interval.tid;
          output_json_string channel interval.frame.binary_name;
          output_string channel {|,"binary":|};
          output_json_string channel interval.frame.binary_path;
          output_string channel {|,"address":|};
          output_json_string channel interval.frame.address;
          output_string channel {|,"stack depth":|};
          output_string channel (string_of_int interval.depth);
          output_string channel ",\"estimated from samples\":true}";
          output_char channel '}')
        document.intervals;
      output_string
        channel
        {|],"metadata":{"source":"Xcode Instruments Time Profiler","implementation":"OCaml","sampling":true,"sampleCount":|};
      output_string channel (string_of_int document.sample_count);
      output_string channel {|,"samplingPeriodNs":|};
      output_string channel (Int64.to_string document.sampling_period_ns);
      output_string channel {|,"intervalCount":|};
      output_string channel (string_of_int (List.length document.intervals));
      output_string
        channel
        {|,"warning":"Function boundaries are estimates reconstructed from periodic stack samples; short calls may not appear."}}|})

let rec make_directory path =
  if String.equal path "" || String.equal path "." || String.equal path "/" then
    ()
  else if Sys.file_exists path then (
    if not (Sys.is_directory path) then failf "%s exists and is not a directory" path)
  else (
    make_directory (Filename.dirname path);
    Unix.mkdir path 0o755)

let process_exit_code name = function
  | Unix.WEXITED code -> code
  | Unix.WSIGNALED signal -> failf "%s was terminated by signal %d" name signal
  | Unix.WSTOPPED signal -> failf "%s was stopped by signal %d" name signal

let wait_for_process ?timeout_seconds name pid =
  match timeout_seconds with
  | None -> process_exit_code name (snd (Unix.waitpid [] pid))
  | Some timeout_seconds ->
    let deadline = Unix.gettimeofday () +. timeout_seconds in
    let rec loop () =
      match Unix.waitpid [ Unix.WNOHANG ] pid with
      | 0, _ when Unix.gettimeofday () < deadline ->
        ignore (Unix.select [] [] [] 0.05);
        loop ()
      | 0, _ ->
        Unix.kill pid Sys.sigterm;
        ignore (Unix.select [] [] [] 0.5);
        (match Unix.waitpid [ Unix.WNOHANG ] pid with
         | 0, _ ->
           Unix.kill pid Sys.sigkill;
           ignore (Unix.waitpid [] pid)
         | _ -> ());
        failf "%s exceeded its %.1fs timeout" name timeout_seconds
      | _, status -> process_exit_code name status
    in
    loop ()

let gzip_file source destination =
  let output =
    Unix.openfile destination [ Unix.O_WRONLY; Unix.O_CREAT; Unix.O_TRUNC ] 0o644
  in
  Fun.protect
    ~finally:(fun () -> Unix.close output)
    (fun () ->
      let arguments = [| "/usr/bin/gzip"; "-c"; source |] in
      let pid =
        Unix.create_process arguments.(0) arguments Unix.stdin output Unix.stderr
      in
      match wait_for_process "gzip" pid with
      | 0 -> ()
      | code -> failf "gzip failed with exit code %d" code)

let write_trace_document document output =
  make_directory (Filename.dirname output);
  if Filename.check_suffix output ".gz" then (
    let temporary = Filename.temp_file "magic-trace-macos-" ".json" in
    Fun.protect
      ~finally:(fun () -> if Sys.file_exists temporary then Sys.remove temporary)
      (fun () ->
        write_uncompressed_trace document temporary;
        gzip_file temporary output))
  else
    write_uncompressed_trace document output

let normalize_duration value =
  let length = String.length value in
  let only_digits text =
    String.length text > 0
    &&
    let rec loop index =
      index = String.length text
      ||
      match text.[index] with
      | '0' .. '9' -> loop (index + 1)
      | _ -> false
    in
    loop 0
  in
  let all_digits = only_digits value in
  if all_digits then
    value ^ "s"
  else
    let unit_start =
      if Filename.check_suffix value "ms" then length - 2 else length - 1
    in
    let valid_unit =
      unit_start > 0
      &&
      match String.sub value unit_start (length - unit_start) with
      | "ms" | "s" | "m" | "h" -> true
      | _ -> false
    in
    let numeric = if unit_start > 0 then String.sub value 0 unit_start else "" in
    let valid_number =
      match String.split_on_char '.' numeric with
      | [ whole ] -> only_digits whole
      | [ whole; fraction ] -> only_digits whole && only_digits fraction
      | _ -> false
    in
    if valid_unit && valid_number then
      value
    else
      failf "invalid duration %S; use a value such as 5, 5s, 500ms, or 1m" value

let executable_file path =
  Sys.file_exists path
  && not (Sys.is_directory path)
  &&
  try
    Unix.access path [ Unix.X_OK ];
    true
  with
  | Unix.Unix_error _ -> false

let find_on_path executable =
  if String.contains executable '/' then
    if executable_file executable then Some (Unix.realpath executable) else None
  else
    let path = Option.value ~default:"" (Sys.getenv_opt "PATH") in
    String.split_on_char ':' path
    |> List.find_map (fun directory ->
      let candidate = Filename.concat directory executable in
      if executable_file candidate then Some candidate else None)

let capture_first_line program arguments =
  try
    let channel = Unix.open_process_args_in program arguments in
    let line = input_line channel |> trim in
    match Unix.close_process_in channel with
    | Unix.WEXITED 0 -> Some line
    | _ -> None
  with
  | End_of_file | Sys_error _ | Unix.Unix_error _ -> None

let find_xctrace () =
  let candidates =
    [ Sys.getenv_opt "MAGIC_TRACE_XCTRACE"
    ; Some "/Applications/Xcode.app/Contents/Developer/usr/bin/xctrace"
    ; find_on_path "xctrace"
    ]
  in
  match
    List.find_map
      (function
        | Some candidate when executable_file candidate -> Some candidate
        | _ -> None)
      candidates
  with
  | Some path -> path
  | None ->
    (match capture_first_line "/usr/bin/xcrun" [| "/usr/bin/xcrun"; "--find"; "xctrace" |] with
     | Some path when executable_file path -> path
     | _ ->
       failf
         "xctrace was not found. Install Xcode and select it in Xcode > Settings > \
          Locations > Command Line Tools.")

let run_process ?timeout_seconds arguments =
  let arguments = Array.of_list arguments in
  let pid =
    Unix.create_process arguments.(0) arguments Unix.stdin Unix.stdout Unix.stderr
  in
  wait_for_process ?timeout_seconds arguments.(0) pid

let run_checked arguments =
  match run_process arguments with
  | 0 -> ()
  | code ->
    failf
      "command failed with exit code %d: %s"
      code
      (String.concat " " arguments)

let file_contains path needle =
  let contents = Xml.read_file path in
  let needle_length = String.length needle in
  let rec search index =
    index + needle_length <= String.length contents
    && (String.sub contents index needle_length = needle || search (index + 1))
  in
  search 0

let export_time_profile ~xctrace ~recording ~destination =
  let toc = Filename.concat (Filename.dirname destination) "toc.xml" in
  run_checked
    [ xctrace
    ; "export"
    ; "--input"
    ; recording
    ; "--toc"
    ; "--output"
    ; toc
    ; "--quiet"
    ];
  if
    not
      (file_contains toc {|schema="time-profile"|}
       || file_contains toc {|schema='time-profile'|})
  then
    failf "the recording does not contain a symbolicated time-profile table";
  let xpath = {|/trace-toc/run[@number="1"]/data/table[@schema="time-profile"]|} in
  run_checked
    [ xctrace
    ; "export"
    ; "--input"
    ; recording
    ; "--xpath"
    ; xpath
    ; "--output"
    ; destination
    ; "--quiet"
    ]

let resolve_target command =
  match command with
  | [] -> failf "missing command after --"
  | executable :: arguments ->
    let executable =
      match find_on_path executable with
      | Some path -> path
      | None -> failf "target executable was not found: %s" executable
    in
    executable :: arguments

let record ~timeout_seconds ~target_stdout ~xctrace ~recording ~duration ~target =
  let common =
    [ xctrace
    ; "record"
    ; "--template"
    ; "Time Profiler"
    ; "--time-limit"
    ; normalize_duration duration
    ; "--output"
    ; recording
    ; "--no-prompt"
    ; "--quiet"
    ]
  in
  let arguments =
    match target with
    | Pid pid -> common @ [ "--attach"; string_of_int pid ]
    | Command command ->
      let output_arguments =
        match target_stdout with
        | None -> []
        | Some path -> [ "--target-stdout"; path ]
      in
      common @ output_arguments @ [ "--launch"; "--" ] @ resolve_target command
  in
  let code = run_process ?timeout_seconds arguments in
  if code <> 0 && code <> 54 then failf "xctrace failed with exit code %d" code;
  if not (Sys.file_exists recording) then failf "xctrace did not create %s" recording

let ensure_new_output path force =
  if Sys.file_exists path && not force then
    failf "%s already exists; choose another output or pass --force" path

let rec remove_tree path =
  if Sys.file_exists path then
    if Sys.is_directory path then (
      Sys.readdir path
      |> Array.iter (fun name -> remove_tree (Filename.concat path name));
      Unix.rmdir path)
    else
      Sys.remove path

let with_temporary_directory action =
  let path = Filename.temp_file "magic-trace-macos-" "" in
  Sys.remove path;
  Unix.mkdir path 0o700;
  Fun.protect ~finally:(fun () -> remove_tree path) (fun () -> action path)

let convert_export ~profile_xml ~output ~force =
  ensure_new_output output force;
  let samples = parse_time_profile_xml profile_xml in
  let document = build_trace_document samples in
  write_trace_document document output;
  Printf.eprintf
    "Converted %d samples into %d estimated intervals.\n%!"
    document.sample_count
    (List.length document.intervals);
  Printf.printf "%s\n%!" (Unix.realpath output)

let record_and_convert ~duration ~output ~keep_recording ~force ~target =
  ensure_new_output output force;
  let xctrace = find_xctrace () in
  with_temporary_directory (fun temporary ->
    let recording =
      match keep_recording with
      | Some path -> path
      | None -> Filename.concat temporary "recording.trace"
    in
    if Sys.file_exists recording then failf "%s already exists" recording;
    Printf.eprintf
      "Recording sampled stacks for %s with %s...\n%!"
      (normalize_duration duration)
      xctrace;
    record
      ~timeout_seconds:None
      ~target_stdout:(Some "-")
      ~xctrace
      ~recording
      ~duration
      ~target;
    let exported_xml = Filename.concat temporary "time-profile.xml" in
    Printf.eprintf "Exporting symbolicated samples...\n%!";
    export_time_profile ~xctrace ~recording ~destination:exported_xml;
    let samples = parse_time_profile_xml exported_xml in
    let document = build_trace_document samples in
    write_trace_document document output;
    Printf.eprintf
      "Wrote %d samples as %d estimated intervals.\n%!"
      document.sample_count
      (List.length document.intervals);
    Printf.printf "%s\n%!" (Unix.realpath output))
