open! Core
include Parser_intf

(* Stores thread kernel objects as a tuple of (pid, tid) *)
module Thread_kernel_object = struct
  include Tuple.Make (Int) (Int)
  include Tuple.Hashable (Int) (Int)
end

module String_index = Int
module Thread_index = Int

module Event_arg = struct
  type value =
    | String of String_index.t
    | Int of int
    | Int64 of int64
    | Pointer of Int64.Hex.t
    | Float of float
  [@@deriving sexp_of, compare]

  type t = String_index.t * value [@@deriving sexp_of, compare]
end

module Event = struct
  type t =
    { timestamp : Time_ns.Span.t
    ; thread : Thread_index.t
    ; category : String_index.t
    ; name : String_index.t
    ; arguments : Event_arg.t list
    ; event_type : Event_type.t
    }
  [@@deriving sexp_of, compare]
end

module Record = struct
  type t =
    | Event of Event.t
    | Interned_string of
        { index : String_index.t
        ; value : string
        }
    | Interned_thread of
        { index : Thread_index.t
        ; value : Thread.t
        }
    | Process_name_change of
        { name : String_index.t
        ; pid : int
        }
    | Thread_name_change of
        { name : String_index.t
        ; pid : int
        ; tid : int
        }
    | Tick_initialization of
        { ticks_per_second : int
        ; base_time : Time_ns.Option.t
        }
  [@@deriving sexp_of, compare]
end

type t =
  { iobuf : (read, Iobuf.seek) Iobuf.t
  ; cur_record : (read, Iobuf.seek) Iobuf.t
  ; mutable current_provider : int option
  ; provider_name_by_id : string Int.Table.t
  ; mutable ticks_per_second : int
  ; mutable base_tick : int
  ; mutable base_time : Time_ns.Option.t
  ; thread_table : Thread.t Int.Table.t
  ; string_table : string Int.Table.t
  ; process_names : string Int.Table.t
  ; thread_names : string Thread_kernel_object.Table.t
  ; warnings : Warnings.t
  }
[@@deriving fields]

let create iobuf =
  { iobuf
  ; cur_record = Iobuf.create ~len:0
  ; current_provider = None
  ; provider_name_by_id = Int.Table.create ()
  ; ticks_per_second = 1_000_000_000
  ; base_tick = 0
  ; base_time = Time_ns.Option.none
  ; thread_table = Int.Table.create ()
  ; string_table = Int.Table.create ()
  ; process_names = Int.Table.create ()
  ; thread_names = Thread_kernel_object.Table.create ()
  ; warnings = { num_unparsed_records = 0; num_unparsed_args = 0 }
  }
;;

exception Ticks_too_large
exception Invalid_tick_rate
exception Invalid_record
exception String_not_found
exception Thread_not_found

let consume_int32_exn iobuf =
  if Iobuf.length iobuf < 4 then raise Invalid_record else Iobuf.Consume.int32_le iobuf
;;

(* Many things don't use the most significant bit of their word so we can safely use a
   normal OCaml 63 bit int to parse them. *)
let consume_int64_trunc_exn iobuf =
  if Iobuf.length iobuf < 8
  then raise Invalid_record
  else Iobuf.Consume.int64_le_trunc iobuf
;;

let consume_int64_t_exn iobuf =
  if Iobuf.length iobuf < 8 then raise Invalid_record else Iobuf.Consume.int64_t_le iobuf
;;

let consume_tail_padded_string_exn iobuf ~len =
  if Iobuf.length iobuf < len
  then raise Invalid_record
  else Iobuf.Consume.tail_padded_fixed_string ~padding:Char.min_value ~len iobuf
;;

let advance_iobuf_exn iobuf ~by:len =
  if Iobuf.length iobuf < len then raise Invalid_record else Iobuf.advance iobuf len
;;

let[@inline] extract_field word ~pos ~size = (word lsr pos) land ((1 lsl size) - 1)

(* Because the format guarantees aligned 64-bit words, some things need to be padded to
   8 bytes. This is an efficient expression for doing that. *)
let padding_to_word x = -x land (8 - 1)

(* Method for converting a tick count to nanoseconds taken from the Perfetto source code.
   Raises [Ticks_too_large] if the result doesn't fit in an int63.

   This implements a kind of elementary school long multiplication to handle larger
   values without overflowing in the intermediate steps or losing precision. We do
   this complicated method instead of just using floats because it's nice if our
   tools don't lose precision if a ticks value is an absolute [Time_ns.t], even if
   those traces won't work perfectly in the Perfetto web UI. *)
let ticks_to_ns ticks ~ticks_per_sec =
  let ticks_hi = ticks lsr 32 in
  let ticks_lo = ticks land ((1 lsl 32) - 1) in
  let ns_per_sec = 1_000_000_000 in
  (* Calculating [result_hi] can overflow, so we check for that case. *)
  let result_hi = ticks_hi * ((ns_per_sec lsl 32) / ticks_per_sec) in
  if ticks_hi <> 0 && result_hi / ticks_hi <> (ns_per_sec lsl 32) / ticks_per_sec
  then raise Ticks_too_large;
  (* Calculating [result_lo] can't overflow since [ticks_lo * ns_per_sec] is less than
     2^62. *)
  let result_lo = ticks_lo * ns_per_sec / ticks_per_sec in
  (* Adding [result_lo + result_hi] can overflow. *)
  let result = result_lo + result_hi in
  if result < 0 then raise Ticks_too_large;
  result
;;

let event_tick_to_span t tick =
  let ticks_elapsed = tick - t.base_tick in
  let ticks_ns = ticks_to_ns ticks_elapsed ~ticks_per_sec:t.ticks_per_second in
  Time_ns.Span.of_int_ns ticks_ns
;;

let lookup_string_exn t ~index =
  if index = 0
  then ""
  else (
    try Hashtbl.find_exn t.string_table index with
    | _ -> raise String_not_found)
;;

let lookup_thread_exn t ~index =
  try Hashtbl.find_exn t.thread_table index with
  | _ -> raise Thread_not_found
;;

(* Extracts a 16-bit string index. Will raise if the string index isn't in the string
   table or if attempting to read an inline string reference.
   Since inline string references have their highest bit set to 1 and use the lower 15
   bits to indicate the length of the string stream, the value will always be >= 32768.
   Values >= 32768 will never be in the string table because in [parse_string_record],
   we only write strings to indices [1, 32767]. *)
let[@inline] extract_string_index t word ~pos =
  let index = extract_field word ~pos ~size:16 in
  (* raise an exception if the string is not in the string table *)
  lookup_string_exn t ~index |> (ignore : string -> unit);
  index
;;

(* Extracts an 8-bit thread index. Will raise if the thread index isn't in the
   thread table. *)
let[@inline] extract_thread_index t word ~pos =
  let index = extract_field word ~pos ~size:8 in
  (* raise an exception if the thread is not in the thread table *)
  lookup_thread_exn t ~index |> (ignore : Thread.t -> unit);
  index
;;

let[@inline] consume_tick t =
  let ticks = consume_int64_trunc_exn t.cur_record in
  (* We raise [Ticks_too_large] in case a bug (e.g. overflow) caused the ticks value to
     become negative when converted to a 63-bit OCaml int. *)
  if ticks < 0 then raise Ticks_too_large;
  ticks
;;

let parse_metadata_record t =
  let header = consume_int64_trunc_exn t.cur_record in
  let mtype = extract_field header ~pos:16 ~size:4 in
  match mtype with
  | 1 (* Provider info metadata *) ->
    let provider_id = extract_field header ~pos:20 ~size:32 in
    let name_len = extract_field header ~pos:52 ~size:8 in
    let padding = padding_to_word name_len in
    let provider_name =
      consume_tail_padded_string_exn t.cur_record ~len:(name_len + padding)
    in
    Hashtbl.set t.provider_name_by_id ~key:provider_id ~data:provider_name;
    t.current_provider <- Some provider_id
  | 2 (* Provider section metadata *) ->
    let provider_id = extract_field header ~pos:20 ~size:32 in
    t.current_provider <- Some provider_id
  | 4 (* Trace info metadata *) ->
    let trace_info_type = extract_field header ~pos:20 ~size:4 in
    let trace_info = extract_field header ~pos:24 ~size:32 in
    (* Check for magic number record *)
    if not (trace_info_type = 0 && trace_info = 0x16547846)
    then t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1
  | _ ->
    (* Unsupported metadata type *)
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1
;;

let parse_initialization_record t =
  let header = consume_int64_trunc_exn t.cur_record in
  let rsize = extract_field header ~pos:4 ~size:12 in
  let ticks_per_second = consume_int64_trunc_exn t.cur_record in
  if ticks_per_second <= 0 then raise Invalid_tick_rate;
  t.ticks_per_second <- ticks_per_second;
  (* By default, initialization records have size = 2. This checks for the extended
     initialization record that has two extra words. *)
  if rsize = 4
  then (
    let base_tick = consume_tick t in
    let base_time_in_ns = consume_int64_trunc_exn t.cur_record in
    let base_time =
      Time_ns.of_int_ns_since_epoch base_time_in_ns |> Time_ns.Option.some
    in
    t.base_tick <- base_tick;
    t.base_time <- base_time;
    Record.Tick_initialization { ticks_per_second; base_time })
  else Record.Tick_initialization { ticks_per_second; base_time = Time_ns.Option.none }
;;

(* Reads a zero-padded string and stores it at the associated 15-bit index (from 1 to
   32767) in the string table. *)
let parse_string_record t =
  let header = consume_int64_trunc_exn t.cur_record in
  let string_index = extract_field header ~pos:16 ~size:15 in
  (* Index 0 is used to denote the empty string. The spec mandates that string records
     which attempt to define it anyways be ignored. *)
  if string_index = 0
  then None
  else (
    let str_len = extract_field header ~pos:32 ~size:15 in
    let padding = padding_to_word str_len in
    let interned_string =
      consume_tail_padded_string_exn t.cur_record ~len:(str_len + padding)
    in
    Hashtbl.set t.string_table ~key:string_index ~data:interned_string;
    Some (Record.Interned_string { index = string_index; value = interned_string }))
;;

(* Reads a PID and TID and stores them at the associated 8-bit index (from 1 to 255) in
   the thread table. *)
let parse_thread_record t =
  let header = consume_int64_trunc_exn t.cur_record in
  let thread_index = extract_field header ~pos:16 ~size:8 in
  (* Index 0 is reserved for inline thread refs, sets to it must be ignored. *)
  if thread_index = 0
  then None
  else (
    let process_koid = consume_int64_trunc_exn t.cur_record in
    let thread_koid = consume_int64_trunc_exn t.cur_record in
    let thread =
      { Thread.pid = process_koid
      ; tid = thread_koid
      ; process_name = Hashtbl.find t.process_names process_koid
      ; thread_name =
          Hashtbl.find t.thread_names (process_koid, thread_koid)
      }
    in
    Hashtbl.set t.thread_table ~key:thread_index ~data:thread;
    Some (Record.Interned_thread { index = thread_index; value = thread }))
;;

let rec parse_args ?(args = []) t ~num_args =
  if num_args = 0
  then List.rev args
  else (
    let header_low_word = consume_int32_exn t.cur_record in
    let arg_type = extract_field header_low_word ~pos:0 ~size:4 in
    let rsize = extract_field header_low_word ~pos:4 ~size:12 in
    let arg_name = extract_string_index t header_low_word ~pos:16 in
    (* The Fuchsia spec says the upper 32-bits of the header are reserved for future
       extensions, and should just be ignored if they aren't used. *)
    let header_high_word = consume_int32_exn t.cur_record in
    let (args : Event_arg.t list) =
      match arg_type with
      (* arg_type 0 is a null argument with no value. We never write these so we just
         collapse them into an Int with value zero. *)
      | 0 | 1 -> (arg_name, Int header_high_word) :: args
      | 3 ->
        let value = consume_int64_t_exn t.cur_record in
        let arg =
          match Int64.to_int value with
          | Some value -> Event_arg.Int value
          | None -> Int64 value
        in
        (arg_name, arg) :: args
      | 5 ->
        let value_as_int64 = consume_int64_t_exn t.cur_record in
        let value = Int64.float_of_bits value_as_int64 in
        (arg_name, Float value) :: args
      | 6 ->
        let value = extract_string_index t header_high_word ~pos:0 in
        (arg_name, String value) :: args
      | 7 ->
        let value = consume_int64_t_exn t.cur_record in
        (arg_name, Pointer value) :: args
      | _ ->
        (* Advance [rsize - 1] words to the next argument after reading the header word. *)
        advance_iobuf_exn t.cur_record ~by:(8 * (rsize - 1));
        (* Unsupported argument types: unsigned integers, pointers, kernel IDs *)
        t.warnings.num_unparsed_args <- t.warnings.num_unparsed_args + 1;
        args
    in
    parse_args t ~num_args:(num_args - 1) ~args)
;;

let parse_kernel_object_record t =
  let header = consume_int64_trunc_exn t.cur_record in
  let obj_type = extract_field header ~pos:16 ~size:8 in
  let name = extract_string_index t header ~pos:24 in
  let name_str = lookup_string_exn t ~index:name in
  let num_args = extract_field header ~pos:40 ~size:4 in
  match obj_type with
  | 1 (* process *) ->
    let koid = consume_int64_trunc_exn t.cur_record in
    Hashtbl.set t.process_names ~key:koid ~data:name_str;
    (* Update the name of any matching process in the process table. *)
    Hashtbl.iter t.thread_table ~f:(fun thread ->
      if thread.pid = koid then thread.process_name <- Some name_str);
    if num_args > 0
    then t.warnings.num_unparsed_args <- t.warnings.num_unparsed_args + num_args;
    Some (Record.Process_name_change { name; pid = koid })
  | 2 (* thread *) ->
    let koid = consume_int64_trunc_exn t.cur_record in
    if num_args > 0
    then (
      (* We expect the first arg to be a koid argument named "process". *)
      let arg_header = consume_int32_exn t.cur_record in
      let arg_type = extract_field arg_header ~pos:0 ~size:4 in
      let arg_name_ref = extract_string_index t arg_header ~pos:16 in
      let arg_name = lookup_string_exn t ~index:arg_name_ref in
      if arg_type = 8 && String.( = ) arg_name "process"
      then (
        consume_int32_exn t.cur_record |> (ignore : int -> unit);
        let process_koid = consume_int64_trunc_exn t.cur_record in
        Hashtbl.set
          t.thread_names
          ~key:(process_koid, koid)
          ~data:name_str;
        (* Update the name of any matching thread in the thread table. *)
        Hashtbl.iter t.thread_table ~f:(fun thread ->
          if thread.pid = process_koid && thread.tid = koid
          then thread.thread_name <- Some name_str);
        (* Mark any remaining arguments as unparsed. *)
        t.warnings.num_unparsed_args <- t.warnings.num_unparsed_args + (num_args - 1);
        Some (Record.Thread_name_change { name; pid = process_koid; tid = koid }))
      else (
        t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
        None))
    else (
      t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
      None)
  | _ ->
    (* The record contains an unsupported kernel object type. *)
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    None
;;

let parse_event_record t =
  (* Parse the header in two 32-bit pieces so that we can avoid allocating despite it
     being possible the most significant bit is one. *)
  let header_lower = consume_int32_exn t.cur_record in
  let ev_type = extract_field header_lower ~pos:16 ~size:4 in
  let num_args = extract_field header_lower ~pos:20 ~size:4 in
  let thread = extract_thread_index t header_lower ~pos:24 in
  let header_upper = consume_int32_exn t.cur_record in
  let category = extract_string_index t header_upper ~pos:0 in
  let name = extract_string_index t header_upper ~pos:16 in
  let timestamp_tick = consume_tick t in
  let args = parse_args t ~num_args in
  let event_type : Event_type.t option =
    match ev_type with
    | 0 -> Some Instant
    | 1 ->
      let counter_id = consume_int64_trunc_exn t.cur_record in
      Some (Counter { id = counter_id })
    | 2 -> Some Duration_begin
    | 3 -> Some Duration_end
    | 4 ->
      let end_time_tick = consume_int64_trunc_exn t.cur_record in
      Some (Duration_complete { end_time = event_tick_to_span t end_time_tick })
    | 8 ->
      let flow_correlation_id = consume_int64_trunc_exn t.cur_record in
      Some (Flow_begin { flow_correlation_id })
    | 9 ->
      let flow_correlation_id = consume_int64_trunc_exn t.cur_record in
      Some (Flow_step { flow_correlation_id })
    | 10 ->
      let flow_correlation_id = consume_int64_trunc_exn t.cur_record in
      Some (Flow_end { flow_correlation_id })
    (* Unsupported event type: Async begin, instant or end *)
    | _ -> None
  in
  match event_type with
  | Some event_type ->
    let timestamp = event_tick_to_span t timestamp_tick in
    let event =
      { Event.timestamp; thread; category; name; arguments = args; event_type }
    in
    Some (Record.Event event)
  | None ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    None
;;

(* This function advances through the trace until it finds a Fuchsia record matching one
   of the records types defined in [Record.t]. *)
let rec parse_until_next_external_record t =
  if Iobuf.length t.iobuf < 8 then raise End_of_file;
  let header = Iobuf.Peek.int64_le_trunc t.iobuf ~pos:0 in
  let rtype = extract_field header ~pos:0 ~size:4 in
  let rsize =
    (* large blob records use a larger length field *)
    if rtype = 15
    then extract_field header ~pos:4 ~size:32
    else extract_field header ~pos:4 ~size:12
  in
  let rlen = 8 * rsize in
  (* We raise an exception if the current record is split across two iobufs. Subsequent
     calls to parse will attempt to parse this record again. *)
  if Iobuf.length t.iobuf < rlen then raise End_of_file;
  Iobuf.Expert.set_bounds_and_buffer_sub ~pos:0 ~len:rlen ~src:t.iobuf ~dst:t.cur_record;
  (* Because this happens before parsing, errors thrown when parsing will cause subsequent
     calls to parse to begin with the next record, allowing skipping invalid records. *)
  Iobuf.advance t.iobuf rlen;
  let record =
    match rtype with
    | 0 (* Metadata record *) ->
      parse_metadata_record t;
      None
    | 1 (* Initialization record *) -> Some (parse_initialization_record t)
    | 2 (* String record *) -> parse_string_record t
    | 3 (* Thread record *) -> parse_thread_record t
    | 4 (* Event record *) -> parse_event_record t
    | 7 (* Kernel object record *) -> parse_kernel_object_record t
    | _ (* Unsupported record type *) ->
      t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
      None
  in
  match record with
  | Some record -> record
  | None -> parse_until_next_external_record t
;;

let parse_next t =
  try
    let record = parse_until_next_external_record t in
    Result.return record
  with
  | End_of_file -> Result.fail Parse_error.No_more_words
  | Ticks_too_large ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    Result.fail Parse_error.Timestamp_too_large
  | Invalid_tick_rate ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    Result.fail Parse_error.Invalid_tick_initialization
  | Invalid_record ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    Result.fail Parse_error.Invalid_size_on_record
  | String_not_found ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    Result.fail Parse_error.Invalid_string_ref
  | Thread_not_found ->
    t.warnings.num_unparsed_records <- t.warnings.num_unparsed_records + 1;
    Result.fail Parse_error.Invalid_thread_ref
;;
