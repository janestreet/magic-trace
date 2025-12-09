open! Core
module Nonempty_vec = Nonempty_vec.Valuex2

let debug = ref false

(* Time spans from perf start whenever the machine booted. Perfetto uses floats to represent time
   spans, which struggles with large spans when we care about small differences in them. To
   compensate, the trace writer subtracts the time of the first event from all time spans, producing
   what we call a "mapped time". Only mapped times may be written to the trace file. *)
module Mapped_time : sig
  type t = private Time_ns.Span.t [@@deriving sexp, compare, bin_io]

  include Comparable with type t := t

  val start_of_trace : t
  val create : Time_ns.Span.t -> base_time:Time_ns.Span.t -> t
  val is_base_time : t -> bool
  val add : t -> Time_ns.Span.t -> t
  val diff : t -> t -> Time_ns.Span.t
end = struct
  module T = struct
    type t = Time_ns.Span.t [@@deriving sexp, compare, bin_io]
  end

  let start_of_trace = Time_ns.Span.zero
  let create t ~base_time = Time_ns.Span.( - ) t base_time
  let is_base_time = Time_ns.Span.( = ) Time_ns.Span.zero
  let add = Time_ns.Span.( + )
  let diff = Time_ns.Span.( - )

  include T
  include Comparable.Make (T)
end

module Event_and_callstack = struct
  type t =
    { event : Event.t
    ; callstack : Callstack_compression.compression_event
    }
  [@@deriving sexp, bin_io]
end

module Thread_info = struct
  type 'thread t =
    { thread : ('thread[@sexp.opaque])
    ; mutable last_decode_error_time : Mapped_time.t
    ; ocaml_exception_info : (Ocaml_exception_info.t[@sexp.opaque]) option
        (* When the last event arrived. Used to give timestamps to events lacking them. *)
    ; mutable last_event_time : Mapped_time.t
    ; track_group_id : int
    ; extra_event_tracks : ('thread[@sexp.opaque]) Hashtbl.M(Collection_mode.Event.Name).t
    ; trace_segments :
        (#(Trace_segment.t * in_filtered_region:bool) Nonempty_vec.t[@sexp.opaque])
    }
  [@@deriving sexp_of]

  let add_event_to_trace_segment t event_data time =
    let #(trace_segment, ~in_filtered_region:_) = Nonempty_vec.last t.trace_segments in
    Trace_segment.add_event trace_segment event_data (Timestamp.create time)
  ;;

  module New_trace_segment_kind = struct
    type t =
      | Independent
      | Continuing_from_current
  end

  let start_new_trace_segment t ~in_filtered_region ~(kind : New_trace_segment_kind.t) =
    let new_trace_segment =
      match kind with
      | Independent -> Trace_segment.create t.ocaml_exception_info
      | Continuing_from_current ->
        let #(current, ~in_filtered_region:_) = Nonempty_vec.last t.trace_segments in
        Trace_segment.create_continuing_from current
    in
    Nonempty_vec.push_back t.trace_segments #(new_trace_segment, ~in_filtered_region)
  ;;
end

module type Trace = Trace_writer_intf.S_trace

type 'thread inner =
  { debug_info : Elf.Addr_table.t
  ; ocaml_exception_info : Ocaml_exception_info.t option
  ; thread_info : 'thread Thread_info.t Hashtbl.M(Event.Thread).t
  ; base_time : Time_ns.Span.t
  ; trace_scope : Trace_scope.t
  ; trace : (module Trace with type thread = 'thread)
  ; annotate_inferred_start_times : bool
  ; mutable in_filtered_region : bool
  ; mutable transaction_events : Event.With_write_info.t Deque.t
  }

type t = T : 'thread inner -> t

let sexp_of_inner inner =
  [%sexp_of: _ Thread_info.t Hashtbl.M(Event.Thread).t] inner.thread_info
;;

let sexp_of_t (T inner) = sexp_of_inner inner

let allocate_pid (type thread) (t : thread inner) ~name : int =
  let module T = (val t.trace) in
  T.allocate_pid ~name
;;

let allocate_thread (type thread) (t : thread inner) ~pid ~name : thread =
  let module T = (val t.trace) in
  T.allocate_thread ~pid ~name
;;

let write_duration_complete
  (type thread)
  (t : thread inner)
  ~args
  ~thread
  ~name
  ~(time : Mapped_time.t)
  ~(time_end : Mapped_time.t)
  : unit
  =
  let module T = (val t.trace) in
  if t.in_filtered_region
  then
    T.write_duration_complete
      ~args
      ~thread
      ~name
      ~time:(time :> Time_ns.Span.t)
      ~time_end:(time_end :> Time_ns.Span.t)
;;

let write_duration_instant
  (type thread)
  (t : thread inner)
  ~args
  ~thread
  ~name
  ~(time : Mapped_time.t)
  : unit
  =
  let module T = (val t.trace) in
  if t.in_filtered_region
  then T.write_duration_instant ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
;;

let write_counter
  (type thread)
  (t : thread inner)
  ~args
  ~thread
  ~name
  ~(time : Mapped_time.t)
  : unit
  =
  let module T = (val t.trace) in
  if t.in_filtered_region
  then T.write_counter ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
;;

let map_time t time = Mapped_time.create time ~base_time:t.base_time

let write_hits (T t) hits =
  if not (List.is_empty hits)
  then (
    let pid = allocate_pid t ~name:"Snapshot symbol hits" in
    let thread = allocate_thread t ~pid ~name:"hits" in
    List.iter hits ~f:(fun (sym, (hit : Breakpoint.Hit.t)) ->
      let is_default_symbol = String.( = ) sym Magic_trace.Private.stop_symbol in
      let name = [%string "hit %{sym}"] in
      let time = map_time t hit.timestamp in
      let args =
        Tracing.Trace.Arg.
          [ "timestamp", Int (Time_ns.Span.to_int_ns hit.timestamp)
          ; "tid", Int (Pid.to_int hit.tid)
          ; "ip", Pointer hit.ip
          ]
      in
      (* Args that are computed from captured registers are only meaningful on our
         special stop symbol, we still capture them regardless, but on other symbols
         they'll just have confusing broken values. *)
      let args =
        if is_default_symbol
        then
          Tracing.Trace.Arg.
            [ "timestamp_passed", Int (Time_ns.Span.to_int_ns hit.passed_timestamp)
            ; "arg", Int hit.passed_val
            ]
          @ args
        else args
      in
      (* For the special symbol, if present the passed timestamp comes from
         Magic_trace.mark_start and marks the start of a region of interest.

         We check it for validity since it's possible someone uses an older version of
         [Magic_trace.take_snapshot] and that should at least produce a valid trace. *)
      let valid_timestamp =
        Time_ns.Span.(
          hit.passed_timestamp > t.base_time && hit.passed_timestamp < hit.timestamp)
      in
      let start =
        if is_default_symbol && valid_timestamp
        then map_time t hit.passed_timestamp
        else time
      in
      write_duration_complete t ~thread ~args ~name ~time:start ~time_end:time))
;;

let create_expert
  ~trace_scope
  ~debug_info
  ~ocaml_exception_info
  ~earliest_time
  ~hits
  ~annotate_inferred_start_times
  trace
  =
  let base_time =
    List.fold hits ~init:earliest_time ~f:(fun acc (_, (hit : Breakpoint.Hit.t)) ->
      Time_ns.Span.min acc hit.timestamp)
  in
  let t =
    T
      { debug_info = Option.value debug_info ~default:(Int.Table.create ())
      ; ocaml_exception_info
      ; thread_info = Hashtbl.create (module Event.Thread)
      ; base_time
      ; trace_scope
      ; trace
      ; annotate_inferred_start_times
      ; in_filtered_region = true
      ; transaction_events = Deque.create ()
      }
  in
  write_hits t hits;
  t
;;

let create
  ~trace_scope
  ~debug_info
  ~ocaml_exception_info
  ~earliest_time
  ~hits
  ~annotate_inferred_start_times
  trace
  =
  create_expert
    ~trace_scope
    ~debug_info
    ~ocaml_exception_info
    ~earliest_time
    ~hits
    ~annotate_inferred_start_times
    (Real_trace.create trace)
;;

let opt_pid_to_string opt_pid =
  match opt_pid with
  | None -> "?"
  | Some pid -> Pid.to_string pid
;;

(* A practical, but not perfect, fix for #155: If events happen with the exact same timestamp
   as a decode error, stacks break. We implement this "#155 hack" to prevent that:

   If an event happens at exactly the same time as the previous decode error, slide it forward
   by one nanosecond. Maintain the invariant that no event which follows a decode error has the
   same timestamp as that decode error.

   This should have minimal impact on the timestamps displayed to the user, they're precise to at
   most ~40ns anyhow. But it does make sure our stacks always come out in the right order.

   Also worth noting is that despite the fact that we're changing timestamps, this can't reorder
   events. 1ns is the minimum amount of time by which timestamps can differ. So even if there were
   more events exactly 1ns after the decode error, they'll be seen as having the exact same
   timestamp as the events that happened during the decode error. *)
let hack_155 (thread_info : _ Thread_info.t) time =
  let last_decode_error_time = thread_info.last_decode_error_time in
  if Mapped_time.( = ) time last_decode_error_time
     && Mapped_time.( <> ) last_decode_error_time Mapped_time.start_of_trace
  then Mapped_time.add time (Time_ns.Span.of_int_ns 1)
  else time
;;

let event_time t (event : Event.t) (thread_info : _ Thread_info.t) =
  let event_time = Event.time event in
  let unadjusted_time =
    match%optional.Time_ns_unix.Span.Option event_time with
    | None ->
      (* Decode errors sometimes do not have a timestamp, so we pretend they happen at the
         same time as the last event. *)
      thread_info.last_event_time
    | Some time ->
      let time = map_time t time in
      thread_info.last_event_time <- time;
      time
  in
  hack_155 thread_info unadjusted_time
;;

let create_thread t event =
  let thread = Event.thread event in
  let effective_time =
    match%optional.Time_ns_unix.Span.Option Event.time event with
    | None -> Mapped_time.start_of_trace
    | Some time -> map_time t time
  in
  let pid = opt_pid_to_string thread.pid in
  let tid = opt_pid_to_string thread.tid in
  let default_name =
    if String.(pid = tid)
    then [%string "[pid=%{pid}]"]
    else [%string "[pid=%{pid}] [tid=%{tid}]"]
  in
  let name =
    match thread.pid with
    | None -> default_name
    | Some pid ->
      (match Process_info.cmdline_of_pid pid with
       | None -> default_name
       | Some cmdline ->
         let concat_cmdline = String.concat ~sep:" " cmdline in
         let name = [%string "%{concat_cmdline} %{default_name}"] in
         if String.length name > Tracing_zero.Writer.max_interned_string_length
         then default_name
         else name)
  in
  let track_group_id = allocate_pid t ~name in
  let thread = allocate_thread t ~pid:track_group_id ~name:"main" in
  { Thread_info.thread
  ; last_decode_error_time = effective_time
  ; ocaml_exception_info = t.ocaml_exception_info
  ; last_event_time = effective_time
  ; track_group_id
  ; extra_event_tracks = Hashtbl.create (module Collection_mode.Event.Name)
  ; trace_segments =
      Nonempty_vec.create
        #( Trace_segment.create t.ocaml_exception_info
         , ~in_filtered_region:t.in_filtered_region )
  }
;;

let end_of_thread _ (thread_info : _ Thread_info.t) ~time : unit =
  thread_info.last_decode_error_time <- time
;;

let write_trace_segments (type thread) (t : thread inner) =
  Hashtbl.iter t.thread_info ~f:(fun thread_info ->
    Nonempty_vec.iter
      thread_info.trace_segments
      ~f:(fun #(trace_segment, ~in_filtered_region) ->
        if in_filtered_region
        then Trace_segment.write_trace trace_segment t.trace thread_info.thread))
;;

let end_of_trace ?to_time (T t) =
  (* CR-someday cgaebel: I wish this iteration had a defined order; it'd make magic-trace
     a little bit more deterministic. *)
  Hashtbl.iter t.thread_info ~f:(fun thread_info ->
    end_of_thread t thread_info ~time:thread_info.last_event_time;
    match to_time with
    | Some time ->
      let mapped_time = map_time t time in
      thread_info.last_event_time <- mapped_time
    | None -> ())
;;

let finalize t =
  end_of_trace t;
  let (T t) = t in
  write_trace_segments t
;;

let maybe_start_filtered_region t ~should_write ~time:_ =
  if (not t.in_filtered_region) && should_write
  then (
    Hashtbl.iter t.thread_info ~f:(fun thread_info ->
      Thread_info.start_new_trace_segment
        thread_info
        ~in_filtered_region:true
        ~kind:Continuing_from_current);
    t.in_filtered_region <- true)
;;

let maybe_stop_filtered_region t ~should_write =
  if t.in_filtered_region && not should_write
  then (
    end_of_trace (T t);
    t.in_filtered_region <- false;
    Hashtbl.iter t.thread_info ~f:(fun thread_info ->
      Thread_info.start_new_trace_segment
        thread_info
        ~in_filtered_region:false
        ~kind:Continuing_from_current))
;;

let write_event_and_callstack (events_writer : Tracing_tool_output.events_writer) event =
  let event_and_callstack =
    (* TODO Actually populate [callstack] *)
    Event_and_callstack.{ event; callstack = { new_symbols = []; callstack = [] } }
  in
  match events_writer.format with
  | Sexp ->
    Async.Writer.write_sexp
      ~terminate_with:Newline
      events_writer.writer
      [%sexp (event_and_callstack : Event_and_callstack.t)]
  | Binio ->
    Async.Writer.write_bin_prot
      events_writer.writer
      Event_and_callstack.bin_writer_t
      event_and_callstack
;;

let print_error_disclaimer_once =
  lazy
    (let #(color_start, color_end) =
       if Core_unix.isatty Core_unix.stderr then #("\x1b[31m", "\x1b[0m") else #("", "")
     in
     eprintf
       {|%s
WARNING: You are using the new trace-writer, which currently HAS NO ERROR RECOVERY.
An error has just been encountered. YOUR TRACE IS LIKELY TO BE HORRIFICALLY BROKEN.
%s%!
|}
       color_start
       color_end)
;;

let warn_decode_error ~instruction_pointer ~message =
  force print_error_disclaimer_once;
  eprintf
    "Warning: perf reported an error decoding the trace: %s\n%!"
    (match instruction_pointer with
     | None -> [%string "'%{message}'"]
     | Some instruction_pointer ->
       [%string "'%{message}' @ IP %{instruction_pointer#Int64.Hex}."])
;;

(* Write perf_events into a file as a Fuchsia trace (stack events). Events should be
   collected with --itrace=bep or cre, and -F pid,tid,time,flags,addr,sym,symoff as per
   the constants defined above. *)
let rec write_event (T t) ?events_writer original_event =
  if Env_vars.skip_transaction_handling
  then write_event' (T t) ?events_writer original_event
  else (
    let { Event.With_write_info.event; should_write = _ } = original_event in
    (* 1. If this event is within a transaction, queue it.
       2. If this event ends a transaction, deliver all queued events (then deliver it)
       3. If this event is a transaction abort, clear all queued events and discard
       the [Tx_abort]. *)
    match event with
    | Ok { Event.Ok.thread = _; time = _; data; in_transaction } ->
      let is_abort =
        match data with
        | Trace { kind = Some Tx_abort; _ } -> true
        | _ -> false
      in
      if is_abort
      then (
        Deque.clear t.transaction_events;
        write_event' (T t) ?events_writer original_event)
      else if in_transaction
      then Deque.enqueue_back t.transaction_events original_event
      else (
        if not (Deque.is_empty t.transaction_events)
        then (
          Deque.iter' t.transaction_events `front_to_back ~f:(fun ev ->
            write_event' (T t) ?events_writer ev);
          Deque.clear t.transaction_events);
        write_event' (T t) ?events_writer original_event)
    | Error _ ->
      (* Unsure how to best handle errors during a transaction. *)
      if not (Deque.is_empty t.transaction_events)
      then (
        eprintf
          "Warning: error received during transaction, dropping all transaction events\n\
           %!";
        Deque.clear t.transaction_events);
      write_event' (T t) ?events_writer original_event)

and write_event' (T t) ?events_writer event =
  let { Event.With_write_info.event; should_write } = event in
  let thread = Event.thread event in
  let thread_info =
    Hashtbl.find_or_add t.thread_info thread ~default:(fun () -> create_thread t event)
  in
  let thread = thread_info.thread in
  let time = event_time t event thread_info in
  let outer_event = event in
  maybe_start_filtered_region t ~should_write ~time;
  maybe_stop_filtered_region t ~should_write;
  match event with
  | Error { thread = _; instruction_pointer; message; time = _ } ->
    warn_decode_error ~instruction_pointer ~message;
    let name = sprintf !"[decode error: %s]" message in
    write_duration_instant t ~thread ~name ~time ~args:[];
    end_of_thread t thread_info ~time;
    Thread_info.start_new_trace_segment
      thread_info
      ~in_filtered_region:t.in_filtered_region
      ~kind:Independent
  | Ok event_value ->
    if should_write
    then
      Option.iter events_writer ~f:(fun events_writer ->
        write_event_and_callstack events_writer event);
    (match event_value with
     | { Event.Ok.thread = _; time = _; data = Trace _ as data; in_transaction = _ } ->
       (* TODO Re-add the assertion from the old trace-writer on impossible [kind, trace_state_change] combinations *)
       Thread_info.add_event_to_trace_segment thread_info data (time :> Time_ns.Span.t)
     | { Event.Ok.thread = _
       ; time = _
       ; data = Event_sample { location; count; name }
       ; in_transaction = _
       } ->
       let track_name = Collection_mode.Event.Name.to_string name in
       let track_thread =
         Hashtbl.find_or_add thread_info.extra_event_tracks name ~default:(fun () ->
           allocate_thread t ~pid:thread_info.track_group_id ~name:track_name)
       in
       let args =
         Tracing.Trace.Arg.(
           List.concat
             [ [ "timestamp", Int (Time_ns.Span.to_int_ns (time :> Time_ns.Span.t)) ]
             ; [ "symbol", String (Symbol.display_name location.symbol) ]
             ; [ "addr", Pointer location.instruction_pointer ]
             ; [ "count", Int count ]
             ; Option.value_map
                 (Event.thread outer_event).pid
                 ~f:(fun pid -> [ "pid", Int (Pid.to_int pid) ])
                 ~default:[]
             ; Option.value_map
                 (Event.thread outer_event).pid
                 ~f:(fun pid -> [ "tid", Int (Pid.to_int pid) ])
                 ~default:[]
             ])
       in
       write_duration_complete
         t
         ~thread:track_thread
         ~args
         ~name:track_name
         ~time
         ~time_end:time
     | { Event.Ok.thread = _ (* Already used this to look up thread info. *)
       ; time = _ (* Already in scope. Also, this time hasn't been [map_time]'d. *)
       ; data = Power { freq }
       ; in_transaction = _
       } ->
       write_counter
         t
         ~thread
         ~name:"CPU"
         ~time
         ~args:Tracing.Trace.Arg.[ "freq (MHz)", Int freq ]
     | { Event.Ok.data = Stacktrace_sample _; _ } ->
       (* This should be unreachable, we currently delegate support for sampling to the old trace-writer. *)
       assert false)
;;
