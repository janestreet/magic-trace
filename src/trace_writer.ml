open! Core

let debug = ref false
let is_kernel_address addr = Int64.(addr < 0L)

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

module Pending_event = struct
  module Kind = struct
    type t =
      | Call of
          { addr : Int64.Hex.t
          ; offset : Int.Hex.t
          ; from_untraced : bool
          }
      | Ret
      | Ret_from_untraced of { reset_time : Mapped_time.t }
    [@@deriving sexp]
  end

  type t =
    { symbol : Symbol.t
    ; kind : Kind.t
    }
  [@@deriving sexp]

  let create_call location ~from_untraced =
    let { Event.Location.instruction_pointer; symbol; symbol_offset } = location in
    { symbol
    ; kind = Call { addr = instruction_pointer; offset = symbol_offset; from_untraced }
    }
  ;;
end

module Callstack = struct
  type t =
    { stack : Event.Location.t Stack.t
    ; mutable create_time : Mapped_time.t
    }
  [@@deriving sexp, bin_io]

  let create ~create_time = { stack = Stack.create (); create_time }
  let push t v = Stack.push t.stack v
  let pop t = Stack.pop t.stack
  let top t = Stack.top t.stack
  let is_empty t = Stack.is_empty t.stack
  let depth t = Stack.length t.stack

  let how_many_match { stack; create_time = _ } (future_callstack : Event.Location.t list)
    =
    let zipped_stacks, _ =
      List.zip_with_remainder (Stack.to_list stack |> List.rev) future_callstack
    in
    let ans =
      List.take_while zipped_stacks ~f:(fun (current_location, future_location) ->
        Int64.(current_location.instruction_pointer = future_location.instruction_pointer))
      |> List.length
    in
    ans
  ;;
end

module Event_and_callstack = struct
  type t =
    { event : Event.t
    ; callstack : Callstack_compression.compression_event
    }
  [@@deriving sexp, bin_io]
end

module Thread_info = struct
  type ocaml_exception_state =
    | Without_exception_info of { frames_to_unwind : int ref }
    | With_exception_info of
        { ocaml_exception_info : (Ocaml_exception_info.t[@sexp.opaque])
        ; last_known_instruction_pointer : int64 option ref
        }
  [@@deriving sexp_of]

  type 'thread t =
    { thread : ('thread[@sexp.opaque])
    ; (* This isn't a canonical callstack, but represents all of the information that we
         know about the callstack at the point in the events up to the current event being
         processed, and is reflected in the trace at that point. *)
      mutable callstack : Callstack.t
    ; inactive_callstacks : Callstack.t Stack.t
    ; mutable last_decode_error_time : Mapped_time.t
    ; ocaml_exception_state : ocaml_exception_state
    ; mutable pending_events : Pending_event.t list
    ; mutable pending_time : Mapped_time.t
    ; start_events : (Mapped_time.t * Pending_event.t) Deque.t
        (* When the last event arrived. Used to give timestamps to events lacking them. *)
    ; mutable last_event_time : Mapped_time.t
    ; track_group_id : int
    ; extra_event_tracks : ('thread[@sexp.opaque]) Hashtbl.M(Collection_mode.Event.Name).t
    }
  [@@deriving sexp_of]

  let set_callstack t ~is_kernel_address ~time =
    let create_time = if is_kernel_address then time else t.last_decode_error_time in
    t.callstack <- Callstack.create ~create_time
  ;;

  let set_callstack_from_addr t ~addr ~time =
    set_callstack t ~is_kernel_address:(is_kernel_address addr) ~time
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
  ; suppressed_errors : Hash_set.M(Source_code_position).t
  ; mutable transaction_events : Event.With_write_info.t Deque.t
  }

type t = T : 'thread inner -> t

let sexp_of_inner inner =
  [%sexp_of: _ Thread_info.t Hashtbl.M(Event.Thread).t] inner.thread_info
;;

let sexp_of_t (T inner) = sexp_of_inner inner

let eprint_s_once t here sexp =
  if not (Hash_set.mem t.suppressed_errors here)
  then (
    Hash_set.add t.suppressed_errors here;
    eprint_s sexp)
;;

let allocate_pid (type thread) (t : thread inner) ~name : int =
  let module T = (val t.trace) in
  T.allocate_pid ~name
;;

let allocate_thread (type thread) (t : thread inner) ~pid ~name : thread =
  let module T = (val t.trace) in
  T.allocate_thread ~pid ~name
;;

let write_duration_begin
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
  then T.write_duration_begin ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
;;

let write_duration_end
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
  then T.write_duration_end ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
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
      ; suppressed_errors = Hash_set.create (module Source_code_position)
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

let write_pending_event'
  (type thread)
  (t : thread inner)
  (thread : thread Thread_info.t)
  time
  { Pending_event.symbol; kind }
  =
  let display_name = Symbol.display_name symbol in
  match kind with
  | Call { addr; offset; from_untraced } ->
    (* Adding a call is always the result of seeing something new on the top of the
       stack, so the base address is just the current base address. *)
    let base_address = Int64.(addr - of_int offset) in
    let open Tracing.Trace.Arg in
    let symbol_args =
      (* Using [Interned] may cause some issues with the 32k interned string limit, on
         sufficiently large programs if the trace goes through a lot of different code,
         but that'll also be a problem with the span names. This will just make it
         happen around twice as fast. It does make the traces noticeably smaller.

         The real solution is to get around to improving the interning table management
         in the trace writer library.

         ---

         [base_address] might be lie in the kernel, in which case [to_int] will fail (but
         that's alright, because we wouldn't have a symbol for it in the executable's
         [debug_info] anyway). *)
      let address = [ "address", Pointer addr ] in
      match symbol with
      | From_perf_map { start_addr = _; size = _; function_ = _ } ->
        address @ [ "symbol", Interned display_name ]
      | _ ->
        (match Option.bind (Int64.to_int base_address) ~f:(Hashtbl.find t.debug_info) with
         | None -> address @ [ "symbol", Interned display_name ]
         | Some (info : Elf.Location.t) ->
           address
           @ [ "line", Int info.line
             ; "col", Int info.col
             ; "symbol", Interned display_name
             ]
           @
             (match info.filename with
             | Some x -> [ "file", Interned x ]
             | None -> []))
    in
    let inferred_start_time_arg =
      if from_untraced then [ "inferred_start_time", Interned "true" ] else []
    in
    let args = symbol_args @ inferred_start_time_arg in
    let name =
      if t.annotate_inferred_start_times && from_untraced
      then display_name ^ " [inferred start time]"
      else display_name
    in
    write_duration_begin t ~thread:thread.thread ~name ~time ~args
  | Ret -> write_duration_end t ~name:display_name ~time ~thread:thread.thread ~args:[]
  | Ret_from_untraced { reset_time } ->
    write_duration_complete
      t
      ~time:reset_time
      ~time_end:time
      ~name:(Symbol.display_name Unknown)
      ~thread:thread.thread
      ~args:[]
;;

(* It would be reasonable to also have returns consume time, but making them not
   consume time substantially reduces the frequency where we need to use zero-duration
   events. In general the traces are easier to read if returns aren't counted as consuming
   time. *)
let consumes_time { Pending_event.symbol = _; kind } =
  match kind with
  | Call _ -> true
  | Ret | Ret_from_untraced _ -> false
;;

let write_pending_event
  (t : _ inner)
  (thread : _ Thread_info.t)
  time
  (ev : Pending_event.t)
  =
  match ev.kind with
  | Ret_from_untraced _ | Call { from_untraced = true; _ } ->
    Deque.enqueue_front thread.start_events (time, ev)
  | Call _ when Mapped_time.is_base_time time ->
    Deque.enqueue_back thread.start_events (time, ev)
  | _ -> write_pending_event' t thread time ev
;;

let flush (t : _ inner) ~to_time (thread : _ Thread_info.t) =
  (* Try to evenly distribute the time between timestamp updates between all the
     time-consuming events in the batch. *)
  let count = List.count thread.pending_events ~f:consumes_time in
  let total_ns = Mapped_time.diff to_time thread.pending_time |> Time_ns.Span.to_int_ns in
  let ns_offset = ref 0 in
  let shares_consumed = ref 0 in
  List.iter (List.rev thread.pending_events) ~f:(fun ev ->
    let ns_share =
      if consumes_time ev
      then (
        incr shares_consumed;
        (total_ns - !ns_offset) / (count - !shares_consumed + 1))
      else 0
    in
    let time = Mapped_time.add thread.pending_time (Time_ns.Span.of_int_ns !ns_offset) in
    ns_offset := !ns_offset + ns_share;
    write_pending_event t thread time ev);
  thread.pending_time <- to_time;
  thread.pending_events <- []
;;

let add_event (t : _ inner) (thread : _ Thread_info.t) time ev =
  if Mapped_time.( <> ) time thread.pending_time then flush t ~to_time:time thread;
  thread.pending_events <- ev :: thread.pending_events
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
  ; callstack = Callstack.create ~create_time:effective_time
  ; inactive_callstacks = Stack.create ()
  ; last_decode_error_time = effective_time
  ; ocaml_exception_state =
      (match t.ocaml_exception_info with
       | None -> Without_exception_info { frames_to_unwind = ref 0 }
       | Some ocaml_exception_info ->
         With_exception_info
           { ocaml_exception_info; last_known_instruction_pointer = ref None })
  ; pending_events = []
  ; pending_time = Mapped_time.start_of_trace
  ; start_events = Deque.create ()
  ; last_event_time = effective_time
  ; track_group_id
  ; extra_event_tracks = Hashtbl.create (module Collection_mode.Event.Name)
  }
;;

let call t thread_info ~time ~location =
  let ev = Pending_event.create_call location ~from_untraced:false in
  add_event t thread_info time ev;
  Callstack.push thread_info.callstack location
;;

let ret_without_checking_for_go_hacks t (thread_info : _ Thread_info.t) ~time =
  match Callstack.pop thread_info.callstack with
  | Some { symbol; _ } -> add_event t thread_info time { symbol; kind = Ret }
  | None ->
    (* No known stackframe was popped --- could occur if the start of the snapshot
       started in the middle of a tracing region *)
    add_event
      t
      thread_info
      time
      { symbol = From_perf "[unknown]"
      ; kind = Ret_from_untraced { reset_time = thread_info.callstack.create_time }
      }
;;

let rec clear_callstack t (thread_info : _ Thread_info.t) ~time =
  let ret = ret_without_checking_for_go_hacks in
  match Callstack.top thread_info.callstack with
  | None -> ()
  | Some _ ->
    ret t thread_info ~time;
    clear_callstack t thread_info ~time
;;

(* Unlike [clear_callstack], [clear_all_callstacks] also returns from all inactive
   callstacks. *)
let rec clear_all_callstacks t thread_info ~time =
  clear_callstack t thread_info ~time;
  match Stack.pop thread_info.inactive_callstacks with
  | None -> ()
  | Some callstack ->
    thread_info.callstack <- callstack;
    clear_all_callstacks t thread_info ~time
;;

let end_of_thread t (thread_info : _ Thread_info.t) ~time ~is_kernel_address : unit =
  let to_time = thread_info.pending_time in
  Deque.iter' thread_info.start_events `front_to_back ~f:(fun (time, ev) ->
    write_pending_event' t thread_info time ev);
  Deque.clear thread_info.start_events;
  clear_all_callstacks t thread_info ~time;
  flush t ~to_time thread_info;
  thread_info.last_decode_error_time <- time;
  Thread_info.set_callstack thread_info ~is_kernel_address ~time
;;

(* Go (the programming language) has coroutines known as goroutines. The function [gogo] jumps
   from one goroutine to the next. Since [gogo] can jump anywhere, it's a shining example of what
   magic-trace can't handle out of the box. So, we hack it.

   Most of the time, control flow returns parallel to (i.e. as if jumped from) the previous caller
   of [runtime.mcall] or [runtime.morestack.abi0].

   At startup (and maybe other situations?), gogo clears all callstacks and executes [main]. *)
module Go_hacks : sig
  val ret_track_gogo
    :  'a inner
    -> 'a Thread_info.t
    -> time:Mapped_time.t
    -> returned_from:Symbol.t option
    -> unit
end = struct
  let is_gogo (symbol : Symbol.t) =
    match symbol with
    | From_perf "gogo" -> true
    | _ -> false
  ;;

  let is_known_gogo_destination (location : Event.Location.t) =
    match location with
    | { symbol = From_perf ("runtime.mcall" | "runtime.morestack.abi0"); _ } -> true
    | _ -> false
  ;;

  let current_stack_contains_known_gogo_destination (thread_info : _ Thread_info.t) =
    Stack.find thread_info.callstack.stack ~f:(fun location ->
      is_known_gogo_destination location)
    |> Option.is_some
  ;;

  let rec pop_until_gogo_destination t (thread_info : _ Thread_info.t) ~time =
    let ret = ret_without_checking_for_go_hacks in
    match Callstack.top thread_info.callstack with
    | None -> ()
    | Some location ->
      ret t thread_info ~time;
      (* Return one past the known gogo destination. This hack is necessary because:

         - all gogo-destination functions are jumped into and out of
         - magic-trace translates the jump returning from gogo-destination into a ret/call pair
         - this runs on the ret, but the call is to gogo-destination's caller and we don't
           want a second stack frame for that.

         This is a little janky because you see a stack frame momentarily end then start back
         up again on every [gogo]. I think that's a small price to pay to keep all the Go hacks
         in one place. *)
      if is_known_gogo_destination location
      then ret t thread_info ~time
      else pop_until_gogo_destination t thread_info ~time
  ;;

  let ret_track_gogo t thread_info ~time ~returned_from =
    let is_ret_from_gogo = Option.value_map ~f:is_gogo returned_from ~default:false in
    if is_ret_from_gogo
    then
      if current_stack_contains_known_gogo_destination thread_info
      then pop_until_gogo_destination t thread_info ~time
      else end_of_thread t thread_info ~time ~is_kernel_address:false
  ;;
end

let ret t (thread_info : _ Thread_info.t) ~time : unit =
  let returned_from =
    Callstack.top thread_info.callstack |> Option.map ~f:Event.Location.symbol
  in
  ret_without_checking_for_go_hacks t thread_info ~time;
  Go_hacks.ret_track_gogo t thread_info ~time ~returned_from
;;

let check_current_symbol
  t
  (thread_info : _ Thread_info.t)
  ~time
  (location : Event.Location.t)
  =
  (* After every operation, we should be in a situation where the current symbol under
     the pc matches the symbol at the top of the callstack. This can go out-of-sync
     with jumps between functions (e.g. tailcalls, PLT) or returns out of the highest
     known function, so we have to correct the top of the stack here. *)
  match Callstack.top thread_info.callstack with
  | Some { symbol; _ } when not ([%compare.equal: Symbol.t] symbol location.symbol) ->
    ret t thread_info ~time;
    call t thread_info ~time ~location
  | Some _ -> ()
  | None ->
    (* If we have no callstack left, then we just returned out of something we didn't
       see the call for. Since we're in snapshot mode, this happens with functions
       called before the perf events started, so add in a call that begins at the
       start of the trace for that pid.

       These shouldn't be buffered for spreading since we want them exactly at the reset
       time. *)
    let ev = Pending_event.create_call location ~from_untraced:true in
    write_pending_event t thread_info thread_info.callstack.create_time ev;
    Callstack.push thread_info.callstack location
;;

(* OCaml-specific hacks around tracking exception control flow. Supports two
   modes.

   With exception info provided by the compiler: read
   [core/ocaml_exception_info.mli] for details.

   Without exception info provided by the compiler: the way this works is that
   it counts the number of [caml_next_frame_descriptor] calls while an
   exception is unwinding, and knows to unwind the stack that many times (+/- a
   constant) when the next [caml_raise_exn] or [caml_raise_exception] return.

   This mode fails to account for [raise_notrace] exceptions. *)

module Ocaml_hacks : sig
  val ret_track_exn_data : 'a inner -> 'a Thread_info.t -> time:Mapped_time.t -> unit

  val track_executed_pushtraps_and_poptraps_in_range
    :  'a inner
    -> 'a Thread_info.t
    -> src:Event.Location.t
    -> dst:Event.Location.t
    -> time:Mapped_time.t
    -> unit

  val check_current_symbol_track_entertraps
    :  'a inner
    -> 'a Thread_info.t
    -> time:Mapped_time.t
    -> Event.Location.t
    -> unit
end = struct
  (* It's ocaml, not go. *)
  let ret = ret_without_checking_for_go_hacks

  let unwind_stack t (thread_info : _ Thread_info.t) ~time ~frames_to_unwind diff =
    for _ = 0 to !frames_to_unwind + diff do
      ret t thread_info ~time
    done;
    frames_to_unwind := 0
  ;;

  let ret_track_exn_data t thread_info ~time =
    let { Thread_info.callstack; ocaml_exception_state; _ } = thread_info in
    (match ocaml_exception_state with
     | With_exception_info _ -> ()
     | Without_exception_info { frames_to_unwind } ->
       (match Callstack.top callstack with
        | Some { symbol = From_perf symbol; _ } ->
          (match symbol with
           | "caml_next_frame_descriptor" -> incr frames_to_unwind
           | "caml_raise_exn" -> unwind_stack t thread_info ~time ~frames_to_unwind (-2)
           | "caml_stash_backtrace" -> incr frames_to_unwind
           | "caml_raise_exception" ->
             unwind_stack t thread_info ~time ~frames_to_unwind 1
           | _ -> ())
        | _ -> ()));
    ret t thread_info ~time
  ;;

  let clear_trap_stack t thread_info ~time =
    clear_callstack t thread_info ~time;
    match Stack.pop thread_info.inactive_callstacks with
    | Some callstack -> thread_info.callstack <- callstack
    | None -> thread_info.callstack <- Callstack.create ~create_time:time
  ;;

  let check_current_symbol_track_entertraps
    t
    (thread_info : 'a Thread_info.t)
    ~time
    (dst : Event.Location.t)
    =
    match thread_info.ocaml_exception_state with
    | With_exception_info { ocaml_exception_info; _ }
      when Ocaml_exception_info.is_entertrap
             ocaml_exception_info
             ~addr:dst.instruction_pointer ->
      (* CR-someday tbrindus: unwind this hack. This recreates the callstack but with the
         first (synthetic) frame missing. A more principled approach would be the one
         outlined in another CR-someday below, where we teach [Callstack] about traps
         directly. *)
      let s = thread_info.callstack.stack |> Stack.to_list in
      let s = List.take s (List.length s - 1) in
      Stack.clear thread_info.callstack.stack;
      List.iter (List.rev s) ~f:(fun x -> Stack.push thread_info.callstack.stack x);
      clear_trap_stack t thread_info ~time
    | _ -> check_current_symbol t thread_info ~time dst
  ;;

  let track_executed_pushtraps_and_poptraps_in_range
    t
    (thread_info : _ Thread_info.t)
    ~(src : Event.Location.t)
    ~(dst : Event.Location.t)
    ~time
    =
    match thread_info.ocaml_exception_state with
    | Without_exception_info _ -> ()
    | With_exception_info { ocaml_exception_info; last_known_instruction_pointer } ->
      (match !last_known_instruction_pointer with
       | None -> ()
       | Some last_known_instruction_pointer ->
         Ocaml_exception_info.iter_pushtraps_and_poptraps_in_range
           ocaml_exception_info
           ~from:last_known_instruction_pointer
           ~to_:src.instruction_pointer
           ~f:(fun (_addr, kind) ->
             match kind with
             | Pushtrap ->
               (* CR-someday tbrindus: maybe we should have [Callstack.t] know about the
                  concept of trap handlers, and have e.g. [Callstack.{pushtrap,poptrap}]
                  insert markers into an auxiliary data structure.

                  Then we could have operations like "close all frames until the last
                  trap", and enforce invariants like "you can't [ret] past a trap without
                  calling [poptrap] first" there rather than here. *)
               (* Push a synthetic frame equal to the top of the existing stack, to avoid
                  erroneously inferring frames that shouldn't exist when execution happens
                  within a [try ... with] block that doesn't involve calls (and thus
                  generation of new frames). *)
               let top = Callstack.top thread_info.callstack |> Option.value_exn in
               Stack.push thread_info.inactive_callstacks thread_info.callstack;
               thread_info.callstack <- Callstack.create ~create_time:time;
               Callstack.push thread_info.callstack top
             | Poptrap ->
               (* Assuming we didn't drop anything, we should only have the synthetic
                  frame we created at this point. If we have more than that, we either got
                  confused in our state tracking somewhere, or more likely, IPT dropped
                  some data. *)
               if Callstack.depth thread_info.callstack <> 1
               then
                 (* Conditional on happening once, this is likely to happen again... don't
                    spam the user's terminal. *)
                 eprint_s_once
                   t
                   [%here]
                   [%message
                     "WARNING: expected callstack depth to be the same going into a \
                      [try] block as when leaving it, but it wasn't. Did Intel Processor \
                      Trace drop some data? Will attempt to recover. Further errors will \
                      be suppressed.\n"
                       ~depth:(Callstack.depth thread_info.callstack - 1 : int)
                       (src : Event.Location.t)
                       (dst : Event.Location.t)
                       (last_known_instruction_pointer : Int64.Hex.t)]
               else (
                 (* Only pop the exception callstack if we're at the same callstack
                    depth as we were when we saw [Pushtrap]. This should let us recover
                    from situations like:

                    - Pushtrap 1
                    - Pushtrap 2
                    - Poptrap 2
                    - Poptrap 1

                    where "Pushtrap 2" gets dropped. *)
                 ignore (Callstack.pop thread_info.callstack : _);
                 clear_trap_stack t thread_info ~time)));
      last_known_instruction_pointer := Some dst.instruction_pointer
  ;;
end

let assert_trace_scope t event trace_scopes =
  if List.find trace_scopes ~f:(Trace_scope.equal t.trace_scope) |> Option.is_none
  then
    (* CR-someday cgaebel: Should this raise? *)
    eprint_s
      [%message
        "BUG: assumptions violated, saw an unexpected event for this trace mode"
          ~trace_scope:(t.trace_scope : Trace_scope.t)
          (event : Event.t)]
;;

let end_of_trace ?to_time (T t) =
  (* CR-someday cgaebel: I wish this iteration had a defined order; it'd make magic-trace
     a little bit more deterministic. *)
  Hashtbl.iter t.thread_info ~f:(fun thread_info ->
    end_of_thread t thread_info ~time:thread_info.last_event_time ~is_kernel_address:false;
    match to_time with
    | Some time ->
      let mapped_time = map_time t time in
      thread_info.pending_time <- mapped_time;
      thread_info.last_event_time <- mapped_time;
      thread_info.callstack.create_time <- mapped_time
    | None -> ())
;;

let rewrite_callstack t ~(callstack : Callstack.t) ~thread_info ~time =
  let called_locations = callstack.stack |> Stack.to_list |> List.rev in
  List.iter called_locations ~f:(fun location ->
    write_pending_event'
      t
      thread_info
      time
      (Pending_event.create_call location ~from_untraced:true)
    (* Not necessarily true, but setting [~from_untraced:true] causes the timestamp to be annotated as inferred *));
  callstack.create_time
  <- Mapped_time.add
       time
       (Time_ns.Span.of_ns
          (-1.)
          (* Set the reset time of future untraced returns to before the rewritten callstack *))
;;

let rewrite_all_callstacks t ~(thread_info : _ Thread_info.t) ~time =
  let inactive_callstacks =
    thread_info.inactive_callstacks |> Stack.to_list |> List.rev
  in
  List.iter inactive_callstacks ~f:(fun callstack ->
    rewrite_callstack t ~callstack ~thread_info ~time);
  rewrite_callstack t ~callstack:thread_info.callstack ~thread_info ~time
;;

let maybe_start_filtered_region t ~should_write ~time =
  if (not t.in_filtered_region) && should_write
  then (
    Hashtbl.iter t.thread_info ~f:(fun thread_info ->
      flush t ~to_time:time thread_info;
      Deque.clear thread_info.start_events);
    t.in_filtered_region <- true;
    Hashtbl.iter t.thread_info ~f:(fun thread_info ->
      rewrite_all_callstacks t ~thread_info ~time))
;;

let maybe_stop_filtered_region t ~should_write =
  if t.in_filtered_region && not should_write
  then (
    end_of_trace (T t);
    t.in_filtered_region <- false)
;;

let write_event_and_callstack
  (events_writer : Tracing_tool_output.events_writer)
  event
  callstack
  =
  let compression_event =
    Callstack_compression.compress_callstack
      events_writer.callstack_compression_state
      (Callstack.(callstack.stack)
       |> Stack.to_list
       |> List.map ~f:(fun Event.Location.{ symbol; _ } -> symbol))
  in
  let event_and_callstack =
    Event_and_callstack.{ event; callstack = compression_event }
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

let warn_decode_error ~instruction_pointer ~message =
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
    let is_kernel_address =
      match instruction_pointer with
      | None -> false
      | Some ip -> is_kernel_address ip
    in
    end_of_thread t thread_info ~time ~is_kernel_address
  | Ok event_value ->
    if should_write
    then
      Option.iter events_writer ~f:(fun events_writer ->
        write_event_and_callstack events_writer event thread_info.callstack);
    (match event_value with
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
                 (Event.thread outer_event).tid
                 ~f:(fun tid -> [ "tid", Int (Pid.to_int tid) ])
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
       ; time = _
       ; data = Ptwrite { location; data }
       ; in_transaction = _
       } ->
       let args =
         Tracing.Trace.Arg.(
           List.concat
             [ [ "timestamp", Int (Time_ns.Span.to_int_ns (time :> Time_ns.Span.t)) ]
             ; [ "symbol", String (Symbol.display_name location.symbol) ]
             ; [ "addr", Pointer location.instruction_pointer ]
             ; [ "data", String data ]
             ; Option.value_map
                 (Event.thread outer_event).pid
                 ~f:(fun pid -> [ "pid", Int (Pid.to_int pid) ])
                 ~default:[]
             ; Option.value_map
                 (Event.thread outer_event).tid
                 ~f:(fun tid -> [ "tid", Int (Pid.to_int tid) ])
                 ~default:[]
             ])
       in
       write_duration_complete t ~thread ~args ~name:"PTWRITE" ~time ~time_end:time
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
     | { Event.Ok.thread = _ (* Already used this to look up thread info. *)
       ; time = _ (* Already in scope. Also, this time hasn't been [map_time]'d. *)
       ; data = Stacktrace_sample { callstack }
       ; in_transaction = _
       } ->
       let how_many_ret =
         Stack.length thread_info.callstack.stack
         - Callstack.how_many_match thread_info.callstack callstack
       in
       List.init how_many_ret ~f:Fn.id |> List.iter ~f:(fun _ -> ret t thread_info ~time);
       let calls = List.drop callstack (Stack.length thread_info.callstack.stack) in
       List.iter calls ~f:(fun location -> call t thread_info ~time ~location)
     | { Event.Ok.thread = _ (* Already used this to look up thread info. *)
       ; time = _ (* Already in scope. Also, this time hasn't been [map_time]'d. *)
       ; data = Trace { kind; trace_state_change; src; dst }
       ; in_transaction = _
       } ->
       Ocaml_hacks.track_executed_pushtraps_and_poptraps_in_range
         t
         thread_info
         ~src
         ~dst
         ~time;
       (match kind, trace_state_change with
        | Some Call, (None | Some End) -> call t thread_info ~time ~location:dst
        | ( Some
              ( Async
              | Call
              | Syscall
              | Return
              | Hardware_interrupt
              | Iret
              | Interrupt
              | Sysret
              | Jump
              | Tx_abort )
          , Some Start )
        | Some Async, None
        | Some (Hardware_interrupt | Jump | Interrupt | Tx_abort), Some End ->
          raise_s
            [%message
              "BUG: magic-trace devs thought this event was impossible, but you just \
               proved them wrong. Please report this to \
               https://github.com/janestreet/magic-trace/issues/"
                (event : Event.t)]
        | (None | Some Async), Some End ->
          call t thread_info ~time ~location:Event.Location.untraced
        | Some Syscall, Some End ->
          (* We should only be getting these under /u *)
          assert_trace_scope t outer_event [ Userspace ];
          call t thread_info ~time ~location:Event.Location.syscall
        | Some Return, Some End ->
          call t thread_info ~time ~location:Event.Location.returned
        | Some Return, None ->
          Ocaml_hacks.ret_track_exn_data t thread_info ~time;
          (* [caml_raise_exn], at least at the time of writing, modifies the stack
             and then [ret]s when raising. The OCaml compiler's codegen uses indirect
             [jmp]s instead. *)
          Ocaml_hacks.check_current_symbol_track_entertraps t thread_info ~time dst
        | None, Some Start ->
          (* Might get this under /u, /k, and /uk, but we need to handle them all
             differently. *)
          if Trace_scope.equal t.trace_scope Kernel
          then (
            (* We're back in the kernel after having been in userspace. We have a
               brand new stack to work with. [clear_callstack] here should only be
               clearing the [untraced] frame here pushed by [End (Iret | Sysret)]. *)
            clear_callstack t thread_info ~time;
            Thread_info.set_callstack_from_addr
              thread_info
              ~addr:dst.instruction_pointer
              ~time)
          else if Callstack.is_empty thread_info.callstack
          then
            (* View stopping tracing always as a call (typically the result of a call
               into a special library / linker), with starting tracing again as
               exiting it. The one exception is the initial start of the trace for
               that process, when there is no stack and a prior end won't have pushed
               a synthetic stack frame. *)
            call t thread_info ~time ~location:dst
          else
            (* We don't call [check_current_symbol] here because stops don't change
               the program location in most cases, and when a call to a symbol page
               faults, the restart after the page fault at the new location would get
               treated as a tail call if we did call [check_current_symbol]. *)
            Ocaml_hacks.ret_track_exn_data t thread_info ~time
        | Some ((Syscall | Hardware_interrupt) as kind), None ->
          (* We should only be getting [Syscall] these under /uk, but we can get
             [Hardware_interrupt] under /uk, /k. *)
          [ [ Trace_scope.Userspace_and_kernel ]
          ; (if [%compare.equal: Event.Kind.t] kind Hardware_interrupt
             then [ Kernel ]
             else [])
          ]
          |> List.concat
          |> assert_trace_scope t outer_event;
          (* A syscall or hardware interrupt can be modelled as operating on a new
             stack, and shouldn't be allowed to modify the previous stack.

             Also, hardware interrupts can occur during syscalls, so we maintain a
             "stack of callstacks" here. *)
          Stack.push thread_info.inactive_callstacks thread_info.callstack;
          Thread_info.set_callstack_from_addr
            thread_info
            ~addr:dst.instruction_pointer
            ~time;
          call t thread_info ~time ~location:dst
        | Some (Iret | Sysret), Some End ->
          (* We should only be getting these under /k *)
          assert_trace_scope t outer_event [ Kernel ];
          clear_callstack t thread_info ~time;
          call t thread_info ~time ~location:Event.Location.untraced
        | Some ((Iret | Sysret) as kind), None ->
          (* We should only get [Sysret] under /uk, but might get [Iret] under /k as
             well (because the kernel can be interrupted). *)
          [ [ Trace_scope.Userspace_and_kernel ]
          ; (if [%compare.equal: Event.Kind.t] kind Iret then [ Kernel ] else [])
          ]
          |> List.concat
          |> assert_trace_scope t outer_event;
          clear_callstack t thread_info ~time;
          (match Stack.pop thread_info.inactive_callstacks with
           | Some callstack -> thread_info.callstack <- callstack
           | None ->
             Thread_info.set_callstack_from_addr
               thread_info
               ~addr:dst.instruction_pointer
               ~time;
             check_current_symbol t thread_info ~time dst)
        | Some Tx_abort, None -> check_current_symbol t thread_info ~time dst
        | Some (Jump | Interrupt), None ->
          Ocaml_hacks.check_current_symbol_track_entertraps t thread_info ~time dst
        (* (None, _) comes up when perf spews something magic-trace doesn't recognize.
           Instead of crashing, ignore it and keep going. *)
        | None, _ -> ());
       if !debug then print_s (sexp_of_inner t))
;;
