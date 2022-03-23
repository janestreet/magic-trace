open! Core
module TW = Tracing_zero.Writer

module Thread = struct
  type t =
    { pid : int
    ; tid : int
    ; mutable id : TW.Thread_id.t option
    }
end

type t =
  { writer : TW.t
  ; interned_strings : TW.String_id.t String.Table.t
  ; counter_ids : int String.Table.t
  ; thread_slots : Thread.t Int.Table.t
  ; base_time : Time_ns.t
  ; mutable next_thread_slot : int
  ; mutable flow_id_counter : int
  ; mutable counter_id_counter : int
  ; mutable koid_counter : int
  }

let create ~base_time writer =
  let base_time =
    match base_time with
    | None -> Time_ns.epoch
    | Some base_time ->
      let tick_translation = { TW.Tick_translation.epoch_ns with base_time } in
      TW.write_tick_initialization writer tick_translation;
      base_time
  in
  { writer
  ; interned_strings = String.Table.create ()
  ; counter_ids = String.Table.create ()
  ; thread_slots = Int.Table.create ()
  ; base_time
  ; next_thread_slot = 0
  ; flow_id_counter = 0
  ; counter_id_counter = 0
  ; koid_counter = 0
  }
;;

let create_for_file ~base_time ~filename =
  let writer = TW.create_for_file ~filename () in
  create ~base_time writer
;;

module Expert = struct
  let create = create
end

let close t = TW.close t.writer

let translate_time t time =
  assert (Time_ns.(time >= t.base_time));
  Time_ns.diff time t.base_time
;;

let intern_string_cached t s =
  Hashtbl.find_or_add t.interned_strings s ~default:(fun () ->
    TW.intern_string t.writer s)
;;

let span_to_ticks span = Time_ns.Span.to_int_ns span

let allocate_pid t ~name =
  t.koid_counter <- t.koid_counter + 1;
  TW.set_process_name t.writer ~pid:t.koid_counter ~name:(intern_string_cached t name);
  t.koid_counter
;;

let allocate_thread t ~pid ~name =
  t.koid_counter <- t.koid_counter + 1;
  let tid = t.koid_counter in
  TW.set_thread_name t.writer ~pid ~tid ~name:(intern_string_cached t name);
  { Thread.pid; tid; id = None }
;;

module Arg = Trace_intf.Event_arg

module Baked_args = struct
  type baked_value =
    | String of TW.String_id.t
    | Int32 of int
    | Int64 of int
    | Float of float

  type t = (TW.String_id.t * baked_value) list

  let bake temp_slot trace (v : Arg.value) : baked_value =
    match v with
    | Interned s -> String (intern_string_cached trace s)
    | String s ->
      incr temp_slot;
      String (TW.set_temp_string_slot trace.writer ~slot:!temp_slot s)
    | Int i -> if Util.int_fits_in_int32 i then Int32 i else Int64 i
    | Float f -> Float f
  ;;

  let create trace (args : Arg.t list) : t =
    let temp_slot = ref 0 in
    List.map args ~f:(fun (name, v) ->
      intern_string_cached trace name, bake temp_slot trace v)
  ;;

  let types t =
    let strings = ref 0 in
    let int32s = ref 0 in
    let int64s = ref 0 in
    let floats = ref 0 in
    List.iter t ~f:(fun (_, v) ->
      match v with
      | String _ -> incr strings
      | Int32 _ -> incr int32s
      | Int64 _ -> incr int64s
      | Float _ -> incr floats);
    TW.Arg_types.create
      ~int32s:!int32s
      ~int64s:!int64s
      ~floats:!floats
      ~strings:!strings
      ()
  ;;

  let write (t : t) w =
    List.iter t ~f:(function
      | name, String s -> TW.Write_arg.string w ~name s
      | name, Int32 i -> TW.Write_arg.int32 w ~name i
      | name, Int64 i -> TW.Write_arg.int64 w ~name i
      | name, Float f -> TW.Write_arg.float w ~name f)
  ;;
end

(* This type is duplicated here mostly because if it was deduplicated with an intf it then
   it would take a lot of hopping to figure out what arguments you need to pass to the
   writer functions. *)
type 'a event_writer =
  t
  -> args:Arg.t list
  -> thread:Thread.t
  -> category:string
  -> name:string
  -> time:Time_ns.Span.t
  -> 'a

let id_for_thread t thread =
  match thread.Thread.id with
  | Some id -> id
  | None ->
    let slot = t.next_thread_slot in
    t.next_thread_slot <- (t.next_thread_slot + 1) % 255;
    let id = TW.set_thread_slot t.writer ~slot ~pid:thread.pid ~tid:thread.tid in
    thread.id <- Some id;
    Hashtbl.update t.thread_slots slot ~f:(fun old ->
      Option.iter old ~f:(fun kicked_thread -> kicked_thread.id <- None);
      thread);
    id
;;

let writer_adapter raw_writer complete_fn t ~args ~thread ~category ~name ~time =
  let thread_id = id_for_thread t thread in
  let baked_args = Baked_args.create t args in
  let writer =
    raw_writer
      t.writer
      ~arg_types:(Baked_args.types baked_args)
      ~thread:thread_id
      ~category:(intern_string_cached t category)
      ~name:(intern_string_cached t name)
      ~ticks:(span_to_ticks time)
  in
  let write_args () = Baked_args.write baked_args t.writer in
  complete_fn write_args writer
;;

let write_instant = writer_adapter TW.write_instant (fun write_args () -> write_args ())

let write_counter t ~args ~thread ~category ~name ~time =
  List.iter args ~f:(fun (_, v) ->
    match v with
    | Trace_intf.Event_arg.Int _ | Float _ -> ()
    | Interned _ | String _ -> failwith "counter events only accept numeric arguments.");
  (* Unlike the other types of IDs where we expose allocation to the user, counter IDs
     both don't have a separate creation step and we have a name to automatically
     associate them with. In fact Perfetto completely ignores these IDs and just uses the
     name to associate counters, so doing the interning ourselves by name means that any
     tool which does look at counter IDs will match Perfetto. *)
  let counter_id =
    Hashtbl.find_or_add t.counter_ids name ~default:(fun () ->
      t.counter_id_counter <- t.counter_id_counter + 1;
      t.counter_id_counter)
  in
  let handler write_args writer =
    writer ~counter_id;
    write_args ()
  in
  writer_adapter TW.write_counter handler t ~args ~thread ~category ~name ~time
;;

let write_duration_begin =
  writer_adapter TW.write_duration_begin (fun write_args () -> write_args ())
;;

let write_duration_end =
  writer_adapter TW.write_duration_end (fun write_args () -> write_args ())
;;

let write_duration_complete =
  writer_adapter TW.write_duration_complete (fun write_args writer ~time_end ->
    writer ~ticks_end:(span_to_ticks time_end);
    write_args ())
;;

let write_duration_instant t ~args ~thread ~category ~name ~time =
  write_duration_complete t ~args ~thread ~category ~name ~time ~time_end:time
;;

let create_flow t =
  t.flow_id_counter <- t.flow_id_counter + 1;
  Flow.create ~flow_id:t.flow_id_counter
;;

let write_flow_step t flow ~thread ~time =
  let thread = id_for_thread t thread in
  Flow.write_step flow t.writer ~thread ~ticks:(span_to_ticks time)
;;

let finish_flow t flow = Flow.finish flow t.writer
