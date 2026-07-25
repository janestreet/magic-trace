exception Decode_error of string

let decode_fail format =
  Printf.ksprintf (fun message -> raise (Decode_error message)) format

type trace =
  { packets : bytes
  ; event_count : int
  ; resolution_ns : int64
  ; anchor_every : int
  }

type interval =
  { function_id : int
  ; function_name : string
  ; start_ns : int64
  ; end_ns : int64
  ; depth : int
  }

type stats =
  { event_count : int
  ; call_count : int
  ; return_count : int
  ; anchor_count : int
  ; packet_bytes : int
  ; virtual_duration_ns : int64
  ; resolution_ns : int64
  ; max_depth : int
  ; checksum : int64
  }

let event_count (trace : trace) = trace.event_count
let packet_bytes (trace : trace) = Bytes.length trace.packets
let resolution_ns (trace : trace) = trace.resolution_ns

let function_name = function
  | 1 -> "main"
  | 2 -> "work_a"
  | 3 -> "work_b"
  | 4 -> "scramble"
  | identifier -> Printf.sprintf "function_%d" identifier

let add_int64_little_endian buffer value =
  for shift = 0 to 7 do
    let byte =
      Int64.(to_int (logand (shift_right_logical value (shift * 8)) 0xffL))
    in
    Buffer.add_char buffer (Char.chr byte)
  done

let read_int64_little_endian bytes position =
  if position < 0 || position + 8 > Bytes.length bytes then
    decode_fail "truncated 64-bit timing anchor at byte %d" position;
  let result = ref 0L in
  for shift = 0 to 7 do
    let byte = Int64.of_int (Char.code (Bytes.get bytes (position + shift))) in
    result := Int64.logor !result (Int64.shift_left byte (shift * 8))
  done;
  !result

(* Each cycle is a tiny, known program:

     main
       work_a
         scramble
       work_b
         scramble

   Function identifiers 1..14 are call packets and 0 is a return packet.
   Two packets fit in one byte. 0xff is reserved for a timing anchor. *)
let cycle_events = [| 1; 2; 4; 0; 0; 3; 4; 0; 0; 0 |]

let generate ?(resolution_ns = 40L) ?(anchor_every = 4096) ~cycles () =
  if cycles <= 0 then invalid_arg "Mock_processor_trace.generate: cycles must be positive";
  if Int64.compare resolution_ns 1L < 0 then
    invalid_arg "Mock_processor_trace.generate: resolution_ns must be positive";
  if anchor_every <= 0 || anchor_every mod 2 <> 0 then
    invalid_arg
      "Mock_processor_trace.generate: anchor_every must be a positive even integer";
  if cycles > max_int / Array.length cycle_events then
    invalid_arg "Mock_processor_trace.generate: event count is too large";
  let event_count = cycles * Array.length cycle_events in
  let anchor_count = ((event_count - 1) / anchor_every) + 1 in
  let capacity = (event_count / 2) + (anchor_count * 9) in
  let buffer = Buffer.create capacity in
  let event_at index = cycle_events.(index mod Array.length cycle_events) in
  let index = ref 0 in
  while !index < event_count do
    if !index mod anchor_every = 0 then (
      Buffer.add_char buffer '\xff';
      add_int64_little_endian buffer (Int64.mul (Int64.of_int !index) resolution_ns));
    let high = event_at !index in
    let low = event_at (!index + 1) in
    Buffer.add_char buffer (Char.chr ((high lsl 4) lor low));
    index := !index + 2
  done;
  { packets = Bytes.of_string (Buffer.contents buffer)
  ; event_count
  ; resolution_ns
  ; anchor_every
  }

let mix_checksum checksum function_id time_ns depth =
  let open Int64 in
  let value =
    logxor
      time_ns
      (logor (shift_left (of_int function_id) 48) (shift_left (of_int depth) 40))
  in
  add (mul checksum 0x100000001b3L) value

let decode ?(on_interval = fun _ -> ()) trace =
  let packets_length = Bytes.length trace.packets in
  let stack_capacity = 16 in
  let stack_ids = ref (Array.make stack_capacity 0) in
  let stack_starts = ref (Array.make stack_capacity 0L) in
  let depth = ref 0 in
  let maximum_depth = ref 0 in
  let calls = ref 0 in
  let returns = ref 0 in
  let anchors = ref 0 in
  let checksum = ref 0xcbf29ce484222325L in
  let position = ref 0 in
  let decoded_events = ref 0 in
  let current_time_ns = ref 0L in
  let grow_stack () =
    let old_ids = !stack_ids in
    let old_starts = !stack_starts in
    let new_length = Array.length old_ids * 2 in
    let new_ids = Array.make new_length 0 in
    let new_starts = Array.make new_length 0L in
    Array.blit old_ids 0 new_ids 0 (Array.length old_ids);
    Array.blit old_starts 0 new_starts 0 (Array.length old_starts);
    stack_ids := new_ids;
    stack_starts := new_starts
  in
  let decode_event packet =
    if !decoded_events >= trace.event_count then
      decode_fail "packet stream contains more than %d events" trace.event_count;
    if packet = 0 then (
      if !depth = 0 then
        decode_fail "return with an empty call stack at event %d" !decoded_events;
      let closing_depth = !depth - 1 in
      let identifier = (!stack_ids).(closing_depth) in
      let start_ns = (!stack_starts).(closing_depth) in
      on_interval
        { function_id = identifier
        ; function_name = function_name identifier
        ; start_ns
        ; end_ns = !current_time_ns
        ; depth = closing_depth
        };
      depth := closing_depth;
      incr returns;
      checksum := mix_checksum !checksum identifier !current_time_ns closing_depth)
    else (
      if packet >= 15 then
        decode_fail "reserved function identifier %d at event %d" packet !decoded_events;
      if !depth = Array.length !stack_ids then grow_stack ();
      (!stack_ids).(!depth) <- packet;
      (!stack_starts).(!depth) <- !current_time_ns;
      checksum := mix_checksum !checksum packet !current_time_ns !depth;
      incr depth;
      if !depth > !maximum_depth then maximum_depth := !depth;
      incr calls);
    incr decoded_events;
    current_time_ns := Int64.add !current_time_ns trace.resolution_ns
  in
  while !position < packets_length do
    let byte = Char.code (Bytes.get trace.packets !position) in
    if byte = 0xff then (
      let anchor = read_int64_little_endian trace.packets (!position + 1) in
      let expected_event = !anchors * trace.anchor_every in
      if !decoded_events <> expected_event then
        decode_fail
          "timing anchor %d occurs at event %d, expected event %d"
          !anchors
          !decoded_events
          expected_event;
      let expected_time =
        Int64.mul (Int64.of_int !decoded_events) trace.resolution_ns
      in
      if not (Int64.equal anchor expected_time) then
        decode_fail
          "timing anchor at event %d is %Ld ns, expected %Ld ns"
          !decoded_events
          anchor
          expected_time;
      current_time_ns := anchor;
      incr anchors;
      position := !position + 9)
    else (
      decode_event (byte lsr 4);
      if !decoded_events < trace.event_count then decode_event (byte land 0x0f);
      incr position)
  done;
  if !decoded_events <> trace.event_count then
    decode_fail
      "packet stream ended after %d of %d events"
      !decoded_events
      trace.event_count;
  if !depth <> 0 then
    decode_fail "packet stream ended with %d unclosed calls" !depth;
  { event_count = !decoded_events
  ; call_count = !calls
  ; return_count = !returns
  ; anchor_count = !anchors
  ; packet_bytes = packets_length
  ; virtual_duration_ns = !current_time_ns
  ; resolution_ns = trace.resolution_ns
  ; max_depth = !maximum_depth
  ; checksum = !checksum
  }

let output_json_string channel value =
  output_char channel '"';
  String.iter
    (function
      | '"' -> output_string channel "\\\""
      | '\\' -> output_string channel "\\\\"
      | '\n' -> output_string channel "\\n"
      | '\r' -> output_string channel "\\r"
      | '\t' -> output_string channel "\\t"
      | character -> output_char channel character)
    value;
  output_char channel '"'

let write_trace_json ~force trace path =
  if Sys.file_exists path && not force then
    decode_fail "%s already exists; pass --force to replace it" path;
  let channel = open_out_bin path in
  Fun.protect
    ~finally:(fun () -> close_out_noerr channel)
    (fun () ->
      output_string
        channel
        {|{"displayTimeUnit":"ns","traceEvents":[{"name":"process_name","ph":"M","pid":1,"tid":0,"args":{"name":"mock-arm64-target"}},{"name":"thread_name","ph":"M","pid":1,"tid":1,"args":{"name":"main"}}|};
      let stats =
        decode
          ~on_interval:(fun interval ->
            output_string channel {|,{"name":|};
            output_json_string channel interval.function_name;
            Printf.fprintf
              channel
              {|,"cat":"Synthetic Processor Trace","ph":"X","ts":%.3f,"dur":%.3f,"pid":1,"tid":1,"args":{"functionId":%d,"stackDepth":%d}}|}
              (Int64.to_float interval.start_ns /. 1_000.)
              (Int64.to_float (Int64.sub interval.end_ns interval.start_ns)
               /. 1_000.)
              interval.function_id
              interval.depth)
          trace
      in
      Printf.fprintf
        channel
        {|],"metadata":{"source":"Synthetic Apple Processor Trace performance model","implementation":"OCaml","simulated":true,"sampling":false,"resolutionNs":%Ld,"eventCount":%d,"callCount":%d,"packetBytes":%d,"warning":"This validates decoder throughput and exact reconstruction, not real hardware capture overhead."}}|}
        stats.resolution_ns
        stats.event_count
        stats.call_count
        stats.packet_bytes;
      stats)
