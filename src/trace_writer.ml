open! Core
open! Import

let debug = ref false
let is_kernel_address addr = Int64.(addr < 0L)

(* Time spans from perf start whenever the machine booted. Perfetto uses floats to represent time
   spans, which struggles with large spans when we care about small differences in them. To
   compensate, the trace writer subtracts the time of the first event from all time spans, producing
   what we call a "mapped time". Only mapped times may be written to the trace file. *)
module Mapped_time : sig
  type t = private Time_ns.Span.t [@@deriving sexp_of, compare]

  include Comparable with type t := t

  val start_of_trace : t
  val create : Time_ns.Span.t -> base_time:Time_ns.Span.t -> t
  val is_base_time : t -> bool
  val add : t -> Time_ns.Span.t -> t
  val diff : t -> t -> Time_ns.Span.t
  val sub_one_ns : t -> t
end = struct
  module T = struct
    type t = Time_ns.Span.t [@@deriving sexp, compare]
  end

  let start_of_trace = Time_ns.Span.zero
  let create t ~base_time = Time_ns.Span.( - ) t base_time
  let is_base_time = Time_ns.Span.( = ) Time_ns.Span.zero
  let add = Time_ns.Span.( + )
  let diff = Time_ns.Span.( - )
  let sub_one_ns t = add (Time_ns.Span.of_int_ns (-1)) t

  include T
  include Comparable.Make (T)
end

module Pending_event = struct
  module Kind = struct
    type t =
      | Call of
          { addr : int64
          ; offset : int
          ; from_untraced : bool
          }
      | Ret
      | Ret_from_untraced of { reset_time : Mapped_time.t }
    [@@deriving sexp_of]
  end

  type t =
    { symbol : Symbol.t
    ; kind : Kind.t
    }
  [@@deriving sexp_of]

  let create_call location ~from_untraced =
    let { Event.Location.instruction_pointer; symbol; symbol_offset } = location in
    { symbol
    ; kind = Call { addr = instruction_pointer; offset = symbol_offset; from_untraced }
    }
  ;;
end

module Callstack = struct
  type t =
    { stack : Symbol.t Stack.t
    ; create_time : Mapped_time.t
    }
  [@@deriving sexp_of]

  let create ~create_time = { stack = Stack.create (); create_time }
  let push t v = Stack.push t.stack v
  let pop t = Stack.pop t.stack
  let top t = Stack.top t.stack
  let is_empty t = Stack.is_empty t.stack
end

module Thread_info = struct
  type 'thread t =
    { thread : ('thread[@sexp.opaque])
    ; (* This isn't a canonical callstack, but represents all of the information that we
       know about the callstack at the point in the events up to the current event being
       processed, and is reflected in the trace at that point. *)
      mutable callstack : Callstack.t
    ; inactive_callstacks : Callstack.t Stack.t
    ; mutable last_decode_error_time : Mapped_time.t
    ; (* Currently keeping track of the number of frames to unwind during an exception by
       counting the number of calls to next_frame_descriptor (called during backtrace
       collection) since the last raise. This fails on raise_notrace but that can be fixed
       soon. *)
      frames_to_unwind : int ref
    ; mutable pending_events : Pending_event.t list
    ; mutable pending_time : Mapped_time.t
    ; start_events : (Mapped_time.t * Pending_event.t) Deque.t
          (* When the last event arrived. Used to give timestamps to events lacking them. *)
    ; mutable last_event_time : Mapped_time.t
    }
  [@@deriving sexp_of]

  let set_callstack t ~addr ~time =
    let create_time = if is_kernel_address addr then time else t.last_decode_error_time in
    t.callstack <- Callstack.create ~create_time
  ;;
end

module type Trace = Trace_writer_intf.S_trace

type 'thread inner =
  { debug_info : Elf.Addr_table.t
  ; thread_info : 'thread Thread_info.t Hashtbl.M(Event.Thread).t
  ; base_time : Time_ns.Span.t
  ; trace_mode : Trace_mode.t
  ; trace : (module Trace with type thread = 'thread)
  ; annotate_inferred_start_times : bool
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
  T.write_duration_begin ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
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
  T.write_duration_end ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
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
  T.write_duration_instant ~args ~thread ~name ~time:(time :> Time_ns.Span.t)
;;

let real_trace (trace : Tracing.Trace.t) =
  let module T = struct
    type thread = Tracing.Trace.Thread.t

    let allocate_pid = Tracing.Trace.allocate_pid trace
    let allocate_thread = Tracing.Trace.allocate_thread trace
    let write_duration_begin = Tracing.Trace.write_duration_begin trace ~category:""
    let write_duration_end = Tracing.Trace.write_duration_end trace ~category:""
    let write_duration_complete = Tracing.Trace.write_duration_complete trace ~category:""
    let write_duration_instant = Tracing.Trace.write_duration_instant trace ~category:""
  end
  in
  (module T : Trace with type thread = Tracing.Trace.Thread.t)
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
    ~trace_mode
    ~debug_info
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
      ; thread_info = Hashtbl.create (module Event.Thread)
      ; base_time
      ; trace_mode
      ; trace
      ; annotate_inferred_start_times
      }
  in
  write_hits t hits;
  t
;;

let create
    ~trace_mode
    ~debug_info
    ~earliest_time
    ~hits
    ~annotate_inferred_start_times
    trace
  =
  create_expert
    ~trace_mode
    ~debug_info
    ~earliest_time
    ~hits
    ~annotate_inferred_start_times
    (real_trace trace)
;;

let write_pending_event'
    (type thread)
    (t : thread inner)
    (thread : thread Thread_info.t)
    time
    { Pending_event.symbol; kind }
  =
  let symbol = Symbol.demangle symbol in
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
      let time =
        Mapped_time.add thread.pending_time (Time_ns.Span.of_int_ns !ns_offset)
      in
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

let event_time t (event : Event.t) (thread_info : _ Thread_info.t) =
  let event_time = Event.time event in
  match%optional.Time_ns_unix.Span.Option event_time with
  | None ->
    (* Decode errors sometimes do not have a timestamp, so we pretend they happen at the
       same time as the last event. *)
    thread_info.last_event_time
  | Some time ->
    let time = map_time t time in
    thread_info.last_event_time <- time;
    time
;;

let create_thread t event =
  let thread = Event.thread event in
  let effective_time =
    match%optional.Time_ns_unix.Span.Option Event.time event with
    | None -> Mapped_time.start_of_trace
    | Some time -> map_time t time
  in
  let trace_pid =
    allocate_pid
      t
      ~name:[%string "%{opt_pid_to_string thread.pid}/%{opt_pid_to_string thread.tid}"]
  in
  let thread = allocate_thread t ~pid:trace_pid ~name:"main" in
  { Thread_info.thread
  ; callstack = Callstack.create ~create_time:effective_time
  ; inactive_callstacks = Stack.create ()
  ; last_decode_error_time = effective_time
  ; frames_to_unwind = ref 0
  ; pending_events = []
  ; pending_time = Mapped_time.start_of_trace
  ; start_events = Deque.create ()
  ; last_event_time = effective_time
  }
;;

let call t thread_info ~time ~location =
  let ev = Pending_event.create_call location ~from_untraced:false in
  add_event t thread_info time ev;
  Callstack.push thread_info.callstack location.symbol
;;

let ret t (thread_info : _ Thread_info.t) ~time =
  match Callstack.pop thread_info.callstack with
  | Some symbol -> add_event t thread_info time { symbol; kind = Ret }
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
  | Some known when not ([%compare.equal: Symbol.t] known location.symbol) ->
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
    Callstack.push thread_info.callstack location.symbol
;;

let unwind_stack t (thread_info : _ Thread_info.t) ~time diff =
  let frames_to_unwind = thread_info.frames_to_unwind in
  for _ = 0 to !frames_to_unwind + diff do
    ret t thread_info ~time
  done;
  frames_to_unwind := 0
;;

let ret_track_exn_data t thread_info ~time =
  let { Thread_info.callstack; frames_to_unwind; _ } = thread_info in
  (match Callstack.top callstack with
  | Some (From_perf symbol) ->
    (match symbol with
    | "caml_next_frame_descriptor" -> incr frames_to_unwind
    | "caml_raise_exn" -> unwind_stack t thread_info ~time (-2)
    | "caml_raise_exception" -> unwind_stack t thread_info ~time 1
    | _ -> ())
  | _ -> ());
  ret t thread_info ~time
;;

let rec clear_callstack t (thread_info : _ Thread_info.t) ~time =
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

let assert_trace_mode t event trace_modes =
  if List.find trace_modes ~f:(Trace_mode.equal t.trace_mode) |> Option.is_none
  then
    (* CR-someday cgaebel: Should this raise? *)
    Core.eprint_s
      [%message
        "BUG: assumptions violated, saw an unexpected event for this trace mode"
          ~trace_mode:(t.trace_mode : Trace_mode.t)
          (event : Event.t)]
;;

let end_of_thread t (thread_info : _ Thread_info.t) ~time : unit =
  let to_time = thread_info.pending_time in
  Deque.iter' thread_info.start_events `front_to_back ~f:(fun (time, ev) ->
      write_pending_event' t thread_info time ev);
  Deque.clear thread_info.start_events;
  clear_all_callstacks t thread_info ~time;
  flush t ~to_time thread_info
;;

let end_of_trace (T t) =
  (* CR-someday cgaebel: I wish this iteration had a defined order; it'd make magic-trace
     a little bit more deterministic. *)
  Hashtbl.iter t.thread_info ~f:(fun thread_info ->
      end_of_thread t thread_info ~time:thread_info.last_event_time)
;;

(* Write perf_events into a file as a Fuschia trace (stack events). Events should be
   collected with --itrace=be or cre, and -F pid,tid,time,flags,addr,sym,symoff as per
   the constants defined above. *)
let write_event (T t) event =
  let thread = Event.thread event in
  let thread_info =
    Hashtbl.find_or_add t.thread_info thread ~default:(fun () -> create_thread t event)
  in
  let thread = thread_info.thread in
  let last_event_time = thread_info.last_event_time in
  let time = event_time t event thread_info in
  let outer_event = event in
  match event with
  | Error { thread = _; instruction_pointer; message; time = _ } ->
    let name = sprintf !"[decode error: %s]" message in
    (* A practical, but not perfect, fix for #155: If events happen with the exact same timestamp
       as a decode error, stacks break. We implement a hack to prevent that:

       If and only if it doesn't reorder events, we pretend the decode error happened 1ns sooner
       than it actually did. That makes it have a distinct timestamp from any following events
       that have the same timestamp.

       This hack fails, and the user will see broken stacks, when the previous event has the same
       timestamp as the overflow error. I haven't seen that happen before and I imagine it's quite
       rare -- it would imply Intel PT was in an overflow state for an exceedingly small amount of
       time. *)
    let time =
      if Mapped_time.( > ) time last_event_time then Mapped_time.sub_one_ns time else time
    in
    write_duration_instant t ~thread ~name ~time ~args:[];
    end_of_thread t thread_info ~time;
    thread_info.last_decode_error_time <- time;
    Thread_info.set_callstack thread_info ~addr:instruction_pointer ~time
  | Ok event ->
    let { Event.Ok.thread = _ (* Already used this to look up thread info. *)
        ; time = _ (* Already in scope. Also, this time hasn't been [map_time]'d. *)
        ; kind
        ; trace_state_change
          (* [src] is useful, but we don't use it for mostly historical reasons. It's not
           semantically important that we ignore it here. *)
        ; src = _
        ; dst
        }
      =
      event
    in
    (match kind, trace_state_change with
    | Some Call, (None | Some End) -> call t thread_info ~time ~location:dst
    | ( Some (Call | Syscall | Return | Hardware_interrupt | Iret | Sysret | Jump)
      , Some Start )
    | Some (Hardware_interrupt | Jump), Some End ->
      raise_s
        [%message
          "BUG: magic-trace devs thought this event was impossible, but you just proved \
           them wrong. Please report this to \
           https://github.com/janestreet/magic-trace/issues/"
            (event : Event.Ok.t)]
    | None, Some End -> call t thread_info ~time ~location:Event.Location.untraced
    | Some Syscall, Some End ->
      (* We should only be getting these under /u *)
      assert_trace_mode t outer_event [ Userspace ];
      call t thread_info ~time ~location:Event.Location.syscall
    | Some Return, Some End -> call t thread_info ~time ~location:Event.Location.returned
    | Some Return, None ->
      ret_track_exn_data t thread_info ~time;
      check_current_symbol t thread_info ~time dst
    | None, Some Start ->
      (* Might get this under /u, /k, and /uk, but we need to handle them all
       differently. *)
      if Trace_mode.equal t.trace_mode Kernel
      then (
        (* We're back in the kernel after having been in userspace. We have a
         brand new stack to work with. [clear_callstack] here should only be
         clearing the [untraced] frame here pushed by [End (Iret | Sysret)]. *)
        clear_callstack t thread_info ~time;
        Thread_info.set_callstack thread_info ~addr:dst.instruction_pointer ~time)
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
        ret_track_exn_data t thread_info ~time
    | Some ((Syscall | Hardware_interrupt) as kind), None ->
      (* We should only be getting [Syscall] these under /uk, but we can get
       [Hardware_interrupt] under /uk, /k. *)
      [ [ Trace_mode.Userspace_and_kernel ]
      ; (if [%compare.equal: Event.Kind.t] kind Hardware_interrupt
        then [ Kernel ]
        else [])
      ]
      |> List.concat
      |> assert_trace_mode t outer_event;
      (* A syscall or hardware interrupt can be modelled as operating on a new
       stack, and shouldn't be allowed to modify the previous stack.

       Also, hardware interrupts can occur during syscalls, so we maintain a
       "stack of callstacks" here. *)
      Stack.push thread_info.inactive_callstacks thread_info.callstack;
      Thread_info.set_callstack thread_info ~addr:dst.instruction_pointer ~time;
      call t thread_info ~time ~location:dst
    | Some (Iret | Sysret), Some End ->
      (* We should only be getting these under /k *)
      assert_trace_mode t outer_event [ Kernel ];
      clear_callstack t thread_info ~time;
      call t thread_info ~time ~location:Event.Location.untraced
    | Some ((Iret | Sysret) as kind), None ->
      (* We should only get [Sysret] under /uk, but might get [Iret] under /k as
       well (because the kernel can be interrupted). *)
      [ [ Trace_mode.Userspace_and_kernel ]
      ; (if [%compare.equal: Event.Kind.t] kind Iret then [ Kernel ] else [])
      ]
      |> List.concat
      |> assert_trace_mode t outer_event;
      clear_callstack t thread_info ~time;
      (match Stack.pop thread_info.inactive_callstacks with
      | Some callstack -> thread_info.callstack <- callstack
      | None ->
        Thread_info.set_callstack thread_info ~addr:dst.instruction_pointer ~time;
        check_current_symbol t thread_info ~time dst)
    | Some Jump, None -> check_current_symbol t thread_info ~time dst
    (* (None, _) comes up when perf spews something magic-trace doesn't recognize. Instead
     of crashing, we ignore it and keep going. *)
    | None, _ -> ());
    if !debug then print_s (sexp_of_inner t)
;;
