open! Core
open! Import
module Event = Backend_intf.Event

type pending_kind =
  | Call of
      { addr : int
      ; offset : int
      ; from_untraced : bool
      }
  | Ret
  | Ret_from_untraced of { reset_time : Time_ns.Span.t }

type pending_event =
  { name : string
  ; kind : pending_kind
  }

type thread_info =
  { thread : Tracing.Trace.Thread.t
  ; (* This isn't a canonical callstack, but represents all of the information that we
       know about the callstack at the point in the events up to the current event being
       processed, and is reflected in the trace at that point. *)
    callstack : string Stack.t
  ; mutable reset_time : Time_ns.Span.t
  ; (* Currently keeping track of the number of frames to unwind during an exception by
       counting the number of calls to next_frame_descriptor (called during backtrace
       collection) since the last raise. This fails on raise_notrace but that can be fixed
       soon. *)
    frames_to_unwind : int ref
  ; mutable pending_events : pending_event list
  ; mutable pending_time : Time_ns.Span.t
  ; start_events : (Time_ns.Span.t * pending_event) Deque.t
  }

type t =
  { debug_info : Elf.Addr_table.t
  ; trace : Tracing.Trace.t
  ; thread_info : thread_info Hashtbl.M(Event.Thread).t
  ; base_time : Time_ns.Span.t
  }

let map_time t time = Time_ns.Span.( - ) time t.base_time

let write_hits t hits =
  if not (List.is_empty hits)
  then (
    let pid = Tracing.Trace.allocate_pid t.trace ~name:"Snapshot symbol hits" in
    let thread = Tracing.Trace.allocate_thread t.trace ~pid ~name:"hits" in
    List.iter hits ~f:(fun (sym, (hit : Breakpoint.Hit.t)) ->
        let is_default_symbol = String.( = ) sym Magic_trace.Private.stop_symbol in
        let name = [%string "hit %{sym}"] in
        let time = map_time t (Time_ns.Span.of_int_ns hit.timestamp) in
        let args =
          Tracing.Trace.Arg.
            [ "timestamp", Int hit.timestamp; "tid", Int hit.tid; "ip", Int hit.ip ]
        in
        (* Args that are computed from captured registers are only meaningful on our
         special stop symbol, we still capture them regardless, but on other symbols
         they'll just have confusing broken values. *)
        let args =
          if is_default_symbol
          then
            Tracing.Trace.Arg.
              [ "timestamp_passed", Int hit.passed_timestamp; "arg", Int hit.passed_val ]
            @ args
          else args
        in
        (* For the special symbol, if present the passed timestamp comes from
         Magic_trace.mark_start and marks the start of a region of interest.

         We check it for validity since it's possible someone uses an older version of
         [Magic_trace.take_snapshot] and that should at least produce a valid trace. *)
        let valid_timestamp =
          hit.passed_timestamp > Time_ns.Span.to_int_ns t.base_time
          && hit.passed_timestamp < hit.timestamp
        in
        let start =
          if is_default_symbol && valid_timestamp
          then map_time t (Time_ns.Span.of_int_ns hit.passed_timestamp)
          else time
        in
        Tracing.Trace.write_duration_complete
          t.trace
          ~thread
          ~args
          ~category:""
          ~name
          ~time:start
          ~time_end:time))
;;

let create ~debug_info ~earliest_time ~hits trace =
  let base_time =
    List.fold hits ~init:earliest_time ~f:(fun acc (_, (hit : Breakpoint.Hit.t)) ->
        Time_ns.Span.min acc (Time_ns.Span.of_int_ns hit.timestamp))
  in
  let t =
    { debug_info = Option.value debug_info ~default:(Int.Table.create ())
    ; trace
    ; thread_info = Hashtbl.create (module Event.Thread)
    ; base_time
    }
  in
  write_hits t hits;
  t
;;

let write_pending_event' t thread time { name; kind } =
  match kind with
  | Call { addr; offset; from_untraced = _ } ->
    (* Adding a call is always the result of seeing something new on the top of the
       stack, so the base address is just the current base address. *)
    let demangled_name =
      if String.is_prefix name ~prefix:"caml_"
      then name
      else Owee_location.demangled_symbol name
    in
    let base_address = addr - offset in
    let args =
      let open Tracing.Trace.Arg in
      (* Using [Interned] may cause some issues with the 32k interned string limit, on
         sufficiently large programs if the trace goes through a lot of different code,
         but that'll also be a problem with the span names. This will just make it
         happen around twice as fast. It does make the traces noticeably smaller.

         The real solution is to get around to improving the interning table management
         in the trace writer library. *)
      match Hashtbl.find t.debug_info base_address with
      | None -> [ "address", Int addr; "symbol", Interned name ]
      | Some (info : Elf.Location.t) ->
        [ "address", Int addr
        ; "line", Int info.line
        ; "col", Int info.col
        ; "symbol", Interned name
        ]
        @
        (match info.filename with
        | Some x -> [ "file", Interned x ]
        | None -> [])
    in
    Tracing.Trace.write_duration_begin
      t.trace
      ~thread:thread.thread
      ~name:demangled_name
      ~time
      ~args
      ~category:""
  | Ret ->
    Tracing.Trace.write_duration_end
      t.trace
      ~name
      ~time
      ~thread:thread.thread
      ~args:[]
      ~category:""
  | Ret_from_untraced { reset_time } ->
    Tracing.Trace.write_duration_complete
      t.trace
      ~time:reset_time
      ~time_end:time
      ~name:"[unknown]"
      ~thread:thread.thread
      ~args:[]
      ~category:""
;;

(* It would be reasonable to also have returns consume time, but making them not
   consume time substantially reduces the frequency where we need to use zero-duration
   events. In general the traces are easier to read if returns aren't counted as consuming
   time. *)
let consumes_time { name = _; kind } =
  match kind with
  | Call _ -> true
  | Ret | Ret_from_untraced _ -> false
;;

let write_pending_event t thread time ev =
  match ev.kind with
  | Ret_from_untraced _ | Call { from_untraced = true; _ } ->
    Deque.enqueue_front thread.start_events (time, ev)
  | Call _ when Time_ns.Span.( = ) time Time_ns.Span.zero ->
    Deque.enqueue_back thread.start_events (time, ev)
  | _ -> write_pending_event' t thread time ev
;;

let flush (t : t) ~to_time thread =
  (* Try to evenly distribute the time between timestamp updates between all the
     time-consuming events in the batch. *)
  let count = List.count thread.pending_events ~f:consumes_time in
  let total_ns =
    Time_ns.Span.( - ) to_time thread.pending_time |> Time_ns.Span.to_int_ns
  in
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
        Time_ns.Span.( + ) thread.pending_time (Time_ns.Span.of_int_ns !ns_offset)
      in
      ns_offset := !ns_offset + ns_share;
      write_pending_event t thread time ev);
  thread.pending_time <- to_time;
  thread.pending_events <- []
;;

(* We don't know how long the last group of events was actually spread out over, take a
   guess based on approximate typical group sizes, but there's not much we can really do
   to be more accurate *)
let last_group_spread = Time_ns.Span.of_int_ns 10

let flush_all t =
  Hashtbl.iter t.thread_info ~f:(fun thread ->
      let to_time = Time_ns.Span.( + ) thread.pending_time last_group_spread in
      flush t ~to_time thread;
      Deque.iter' thread.start_events `front_to_back ~f:(fun (time, ev) ->
          write_pending_event' t thread time ev);
      Deque.clear thread.start_events)
;;

let add_event t thread time ev =
  if Time_ns.Span.( <> ) time thread.pending_time then flush t ~to_time:time thread;
  thread.pending_events <- ev :: thread.pending_events
;;

let opt_pid_to_string opt_pid =
  match opt_pid with
  | None -> "?"
  | Some pid -> Pid.to_string pid
;;

let opt_int_to_string opt_int =
  match opt_int with
  | None -> "?"
  | Some int -> Int.to_string int
;;

(** Write perf_events into a file as a Fuschia trace (stack events). Events should be
    collected with --itrace=b or cre, and -F pid,tid,time,flags,addr,sym,symoff as per the
    constants defined above. *)
let write_event (t : t) ({ thread; time; symbol; kind; addr; offset } : Event.t) =
  let time = map_time t time in
  let ({ thread; callstack; reset_time; frames_to_unwind; _ } as thread_info) =
    Hashtbl.find_or_add t.thread_info thread ~default:(fun () ->
        let trace_pid =
          Tracing.Trace.allocate_pid
            t.trace
            ~name:
              [%string "%{opt_pid_to_string thread.pid}/%{opt_int_to_string thread.tid}"]
        in
        let thread = Tracing.Trace.allocate_thread t.trace ~pid:trace_pid ~name:"main" in
        { thread
        ; callstack = Stack.create ()
        ; reset_time = time
        ; frames_to_unwind = ref 0
        ; pending_events = []
        ; pending_time = Time_ns.Span.zero
        ; start_events = Deque.create ()
        })
  in
  let call ?(time = time) name =
    let ev = { name; kind = Call { addr; offset; from_untraced = false } } in
    add_event t thread_info time ev;
    Stack.push callstack name
  in
  let ret () =
    match Stack.pop callstack with
    | Some name -> add_event t thread_info time { name; kind = Ret }
    | None ->
      (* No known stackframe was popped --- could occur if the start of the snapshot
         started in the middle of a tracing region *)
      add_event
        t
        thread_info
        time
        { name = "[unknown]"; kind = Ret_from_untraced { reset_time } }
  in
  let check_current_symbol () =
    (* After every operation, we should be in a situation where the current symbol under
       the pc matches the symbol at the top of the callstack. This can go out-of-sync
       with jumps between functions (e.g. tailcalls, PLT) or returns out of the highest
       known function, so we have to correct the top of the stack here. *)
    match Stack.top callstack with
    | Some known when not (String.equal known symbol) ->
      ret ();
      call symbol
    | Some _ -> ()
    | None ->
      (* If we have no callstack left, then we just returned out of something we didn't
         see the call for. Since we're in snapshot mode, this happens with functions
         called before the perf events started, so add in a call that begins at the
         start of the trace for that pid.

         These shouldn't be buffered for spreading since we want them exactly at the reset
         time. *)
      let ev = { name = symbol; kind = Call { addr; offset; from_untraced = true } } in
      write_pending_event t thread_info reset_time ev;
      Stack.push callstack symbol
  in
  let unwind_stack diff =
    for _ = 0 to !frames_to_unwind + diff do
      ret ()
    done;
    frames_to_unwind := 0
  in
  let ret_track_exn_data () =
    (match Stack.top callstack with
    | Some "caml_next_frame_descriptor" -> incr frames_to_unwind
    | Some "caml_raise_exn" -> unwind_stack (-2)
    | Some "caml_raise_exception" -> unwind_stack 1
    | _ -> ());
    ret ()
  in
  let rec clear_stack () =
    match Stack.top callstack with
    | Some _ ->
      ret ();
      clear_stack ()
    | None -> ()
  in
  match kind with
  (* View stopping tracing always as a call (typically the result of a call into a
     special library / linker), with starting tracing again as exiting it. The one
     exception is the initial start of the trace for that process, when there is no
     stack and a prior end won't have pushed a synthetic stack frame. *)
  | Start when Stack.is_empty callstack -> call symbol
  | Call | End Call -> call symbol
  | End None -> call "[untraced]"
  | End Syscall -> call "[syscall]"
  | End Return -> call "[returned]"
  | Return ->
    ret_track_exn_data ();
    check_current_symbol ()
  | Start ->
    (* We don't call [check_current_symbol] here because stops don't change the program
       location in most cases, and when a call to a symbol page faults, the restart after
       the page fault at the new location would get treated as a tail call if we did call
       [check_current_symbol]. *)
    ret_track_exn_data ()
  | Decode_error ->
    Tracing.Trace.write_duration_instant
      t.trace
      ~thread
      ~name:"[decode error]"
      ~time
      ~args:[]
      ~category:"";
    clear_stack ();
    flush_all t;
    thread_info.reset_time <- time
  | Jump -> check_current_symbol ()
;;
