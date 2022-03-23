open! Core
module Time_ns = Time_ns_unix
module Writer = Tracing_zero.Writer

type t =
  { writer : Writer.t
  (* We store mappings from parser string/thread slots to writer string/thread slots. *)
  ; string_ids : Writer.String_id.t Hashtbl.M(Parser.String_index).t
  ; thread_ids : Writer.Thread_id.t Hashtbl.M(Parser.Thread_index).t
  }

(* Can raise if a string index is used before being seen in an [Interned_string] record. *)
let writer_string_id t index =
  if Parser.String_index.equal index Parser.String_index.zero
  then Writer.String_id.empty
  else Hashtbl.find_exn t.string_ids index
;;

(* Can raise if a thread index is used before being seen in an [Interned_thread] record. *)
let writer_thread_id t index = Hashtbl.find_exn t.thread_ids index

let create writer =
  { writer
  ; string_ids = Hashtbl.create (module Parser.String_index)
  ; thread_ids = Hashtbl.create (module Parser.Thread_index)
  }
;;

let create_arg_types event_args =
  let strings = ref 0 in
  let int32s = ref 0 in
  let int64s = ref 0 in
  let floats = ref 0 in
  List.iter event_args ~f:(fun (_, value) ->
    match (value : Parser.Event_arg.value) with
    | String _ -> incr strings
    | Int i -> if Util.int_fits_in_int32 i then incr int32s else incr int64s
    | Float _ -> incr floats);
  Writer.Arg_types.create
    ~int32s:!int32s
    ~int64s:!int64s
    ~floats:!floats
    ~strings:!strings
    ()
;;

let process_event t (event : Parser.Event.t) =
  let arg_types = create_arg_types event.arguments in
  let thread = writer_thread_id t event.thread in
  let category = writer_string_id t event.category in
  let name = writer_string_id t event.name in
  let ticks = Time_ns.Span.to_int_ns event.timestamp in
  (* Write event *)
  (match event.event_type with
   | Instant -> Writer.write_instant t.writer ~arg_types ~thread ~category ~name ~ticks
   | Counter { id = counter_id } ->
     Writer.write_counter t.writer ~arg_types ~thread ~category ~name ~ticks ~counter_id
   | Duration_begin ->
     Writer.write_duration_begin t.writer ~arg_types ~thread ~category ~name ~ticks
   | Duration_end ->
     Writer.write_duration_end t.writer ~arg_types ~thread ~category ~name ~ticks
   | Duration_complete { end_time } ->
     let ticks_end = Time_ns.Span.to_int_ns end_time in
     Writer.write_duration_complete
       t.writer
       ~arg_types
       ~thread
       ~category
       ~name
       ~ticks
       ~ticks_end
   | Flow_begin { flow_correlation_id = flow_id } ->
     Writer.write_flow_begin t.writer ~thread ~ticks ~flow_id
   | Flow_step { flow_correlation_id = flow_id } ->
     Writer.write_flow_step t.writer ~thread ~ticks ~flow_id
   | Flow_end { flow_correlation_id = flow_id } ->
     Writer.write_flow_end t.writer ~thread ~ticks ~flow_id);
  (* Write arguments *)
  List.iter event.arguments ~f:(fun (name, value) ->
    let name = writer_string_id t name in
    match value with
    | String str ->
      let string_id = writer_string_id t str in
      Writer.Write_arg.string t.writer ~name string_id
    | Float i -> Writer.Write_arg.float t.writer ~name i
    | Int i ->
      if Util.int_fits_in_int32 i
      then Writer.Write_arg.int32 t.writer ~name i
      else Writer.Write_arg.int64 t.writer ~name i)
;;

let process_string_record t ~index ~value =
  let slot = Parser.String_index.to_int index in
  let string_id = Writer.Expert.set_string_slot t.writer ~slot value in
  Hashtbl.set t.string_ids ~key:index ~data:string_id
;;

let process_thread_record t ~index ~value:thread =
  let { Parser.Thread.pid; tid; _ } = thread in
  (* We have to pass 0-indexed slots to the writer but the slots are 1-indexed when
     written to the trace. *)
  let slot = Parser.Thread_index.to_int index - 1 in
  let thread_id = Writer.set_thread_slot t.writer ~slot ~pid ~tid in
  Hashtbl.set t.thread_ids ~key:index ~data:thread_id
;;

let process_pid_name_change t ~name ~pid =
  let name = writer_string_id t name in
  Writer.set_process_name t.writer ~pid ~name
;;

let process_tid_name_change t ~name ~pid ~tid =
  let name = writer_string_id t name in
  Writer.set_thread_name t.writer ~pid ~tid ~name
;;

let process_tick_initialization t ~base_time =
  match%optional.Time_ns.Option base_time with
  | Some base_time ->
    (* We want to preserve the base time of the records that follow in the trace, but we
       will always write with a nanosecond tick rate and a base tick of 0. *)
    let tick_translation =
      { Writer.Tick_translation.ticks_per_second = 1_000_000_000
      ; base_ticks = 0
      ; base_time
      }
    in
    Writer.write_tick_initialization t.writer tick_translation
  | None ->
    (* This record must have come from an external trace since the [base_time] field is
       mandatory for our writers. It's okay to ignore this record since the writer will
       default to a nanosecond tick rate. *)
    ()
;;

let write_record t ~(record : Parser.Record.t) =
  match record with
  | Event event -> process_event t event
  | Interned_string { index; value } -> process_string_record t ~index ~value
  | Interned_thread { index; value } -> process_thread_record t ~index ~value
  | Process_name_change { name; pid } -> process_pid_name_change t ~name ~pid
  | Thread_name_change { name; pid; tid } -> process_tid_name_change t ~name ~pid ~tid
  | Tick_initialization { ticks_per_second = _; base_time } ->
    process_tick_initialization t ~base_time
;;
