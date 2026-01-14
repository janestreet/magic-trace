open! Core
module Location = Event.Location
module Nonempty_vec = Nonempty_vec.Valuex3

module Frame : sig
  (* These fields are actually **immutable** except for [Sentinel.t] instances. *)
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  val create : Location.t -> parent:t -> t

  (** Find the first frame whose [location.symbol] matches the provided argument.

      Returns the matching frame (if found), and that frame's distance from the initial
      frame (e.g. a call to [find my_frame my_symbol] with a return value of
      [#(This _, ~distance:0)] indicates that [my_frame.location.symbol] is [my_symbol]). *)
  val find : t -> Symbol.t -> #(t Or_null.t * distance:int)

  val iter_n : t -> int -> f:local_ (t -> unit) -> unit
  val iter_rev : t -> f:local_ (t -> unit) -> unit

  module Sentinel : sig
    type frame := t

    (** The root of a callstack. A sentinel does not correspond to a real program
        location, and its parent is always [Null]; it is the *only* frame allowed to have
        a [Null] parent.

        Using a sentinel allows us to avoid a variety of special-cases, and lets us update
        the root of all callstacks in a trace in O(1) time. *)
    type t = private frame

    val create : unit -> t

    (** Mutate [t]'s contents to the provided [location] and [parent] and return [t] as a
        [frame]. *)
    val become_frame : t -> Location.t -> parent:frame -> frame
  end

  module For_testing : sig
    val to_string_list : t -> string list
    val print_callstack : t -> unit
  end
end = struct
  type t =
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  let[@inline always] create location ~parent = { location; parent = This parent }

  let rec find t target distance =
    match t with
    | { parent = Null; _ } -> #(Null, ~distance)
    | { location = { symbol; _ }; _ } when Symbol.equal symbol target ->
      #(This t, ~distance)
    | { parent = This parent; _ } -> find parent target (distance + 1)
  ;;

  let find t target = find t target 0

  let rec iter_n t n ~f =
    match t, n with
    | { parent = Null; _ }, _ | _, 0 -> ()
    | { parent = This parent; _ }, n ->
      f t;
      iter_n parent (n - 1) ~f
  ;;

  let rec iter_rev t ~f =
    match t with
    | { parent = Null; _ } -> ()
    | { parent = This parent; _ } ->
      iter_rev parent ~f;
      f t
  ;;

  module Sentinel = struct
    type nonrec t = t

    let sentinel_location : Location.t =
      { instruction_pointer = 0L; symbol_offset = 0; symbol = Unknown }
    ;;

    let[@inline always] create () = { location = sentinel_location; parent = Null }

    let become_frame t location ~parent =
      t.location <- location;
      t.parent <- This parent;
      t
    ;;
  end

  module For_testing = struct
    let rec to_string_list acc t =
      match t.parent with
      | Null -> acc
      | This parent ->
        to_string_list (Symbol.display_name t.location.symbol :: acc) parent
    ;;

    let to_string_list t = to_string_list [] t
    let print_callstack leaf = to_string_list leaf |> String.concat_lines |> print_endline
  end
end

module Control_flow = struct
  type t =
    | Jump
    | Call
    | Return of { distance : int }
    (** [distance] indicates how many frames this return pops off of the callstack.
        [distance = 1] is the usual case of returning from the current frame to its
        parent. *)
end

module Callstack = struct
  type t =
    #{ time : Timestamp.t
     ; leaf : Frame.t
     ; control_flow : Control_flow.t
     }
end

type t =
  { mutable root : Frame.Sentinel.t
  ; mutable last_event_time : Timestamp.t
  (** Strictly speaking maintaining [last_event_time] is not necessary, but we do so in
      order to make bugs obvious. *)
  ; callstacks : Callstack.t Nonempty_vec.t
  }

let create () =
  let root = Frame.Sentinel.create () in
  { root
  ; last_event_time = Timestamp.zero
  ; callstacks =
      Nonempty_vec.create
        (#{ time = Timestamp.zero
          ; leaf = (root :> Frame.t)
          ; control_flow = Return { distance = Int.max_value }
          }
         : Callstack.t)
  }
;;

let[@inline always] current_frame t = (Nonempty_vec.last t.callstacks).#leaf

let replace_root t location =
  let new_sentinel = Frame.Sentinel.create () in
  let root =
    Frame.Sentinel.become_frame t.root location ~parent:(new_sentinel :> Frame.t)
  in
  t.root <- new_sentinel;
  root
;;

(* [handle_call] uses [src], unlike the other event handlers. The rationale for this
   is that in the context of a call, [src] is the parent frame of the call to [dst]
   and thus *it continues to exist*. We want our callstacks to reflect that. *)
let handle_call (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  (* First, reconcile things such that [src] matches [current_frame t] if it doesn't
     already. *)
  let () =
    match Frame.find (current_frame t) src.symbol with
    | #(This _, ~distance:0) -> (* The happy case, [src] matches [current_frame t]. *) ()
    | #(This src_frame, ~distance) ->
      (* [src] exists, but is higher up the callstack. *)
      Nonempty_vec.push_back
        t.callstacks
        #{ time; leaf = src_frame; control_flow = Return { distance } }
    | #(Null, ~distance:0) ->
      (* I would only ever expect this to occur at the very beginning of a trace. *)
      let src_frame = replace_root t src in
      Nonempty_vec.push_back t.callstacks #{ time; leaf = src_frame; control_flow = Call }
    | #(Null, ~distance:_) ->
      (* We've somehow reached [src] without seeing the control-flow that brought us here.

         To maximize our chances of producing a coherent trace, we create a frame for
         [src] as a child of the current frame. The idea here is that because we support
         "long" [Return]s (i.e. [Return]s with [distance > 1]), inserting the additional
         frame for [src] ( *in addition* to the frame we always create for [dst]) gives us
         better odds of resynchronizing with the event stream, since now we can easily
         handle a later return event to [src], [dst], or even both. *)
      let src_frame = Frame.create src ~parent:(current_frame t) in
      Nonempty_vec.push_back t.callstacks #{ time; leaf = src_frame; control_flow = Call }
  in
  (* Then create the new frame for [dst]. *)
  Nonempty_vec.push_back
    t.callstacks
    #{ time; leaf = Frame.create dst ~parent:(current_frame t); control_flow = Call }
;;

let handle_return (t : t) (time : Timestamp.t) ~(dst : Location.t) =
  match (current_frame t).parent with
  | Null ->
    (* We are returning into something we did not see the call for. This can happen if
       there's a series of calls like [fn1 -> fn2 -> fn3] and we started tracing during
       the execution of [fn2], then we see a return into [fn1]. *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = replace_root t dst; control_flow = Return { distance = 0 } }
  | This parent_frame ->
    (* We start our search for [dst] from the parent of the current frame because
       otherwise you'd incorrectly handle non-tail recursion, and because returning to the
       current frame is impossible anyway. We add 1 to [distance] in the [control_flow] to
       account for the one extra frame implicitly traversed by doing this. *)
    (match Frame.find parent_frame dst.symbol with
     | #(This dst_frame, ~distance) ->
       Nonempty_vec.push_back
         t.callstacks
         #{ time; leaf = dst_frame; control_flow = Return { distance = distance + 1 } }
     | #(Null, ~distance) ->
       (* Like the [Null] case above, we are returning into something we never saw the
          call for. *)
       Nonempty_vec.push_back
         t.callstacks
         #{ time
          ; leaf = replace_root t dst
          ; control_flow = Return { distance = distance + 1 }
          })
;;

let handle_jump (t : t) (time : Timestamp.t) ~(dst : Location.t) =
  let current_frame = current_frame t in
  match Frame.find current_frame dst.symbol with
  | #(This _, ~distance:0) ->
    (* [dst] matches [current_frame t]. This is either a branch within a function, or
       tail-recursion. For now we don't need to do anything in this case. That will change
       once we support inlined frames. *)
    ()
  | #(This dst_frame, ~distance) ->
    (* [dst] exists, but is higher up the callstack. This is likely an exception, or some
       other exotic control-flow. *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = dst_frame; control_flow = Return { distance } }
  | #(Null, ~distance:0) ->
    (* This is probably a non-recursive tail-call. *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = replace_root t dst; control_flow = Jump }
  | #(Null, ~distance:_) ->
    (* This is probably a non-recursive tail-call. *)
    let parent =
      (* We know this call will never raise because only sentinels have a [Null] parent,
         and the [#(Null, ~distance:0)] case above handles the case where [current_frame]
         is a sentinel. *)
      Or_null.value_exn current_frame.parent
    in
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent; control_flow = Jump }
;;

let[@cold] print (event : Event.Ok.Data.t) (time : Timestamp.t) =
  match event with
  | Trace { kind; src; dst; trace_state_change } ->
    eprint_s
      ~mach:()
      [%message
        (kind : Event.Kind.t option)
          ~time:(Time_ns.Span.to_int_ns (time :> Time_ns.Span.t) % 10000 : int)
          ~src:(Symbol.display_name src.symbol)
          ~dst:(Symbol.display_name dst.symbol)
          (trace_state_change : Trace_state_change.t option)]
  | _ -> ()
;;

let debug = false

let[@inline always] print (event : Event.Ok.Data.t) (time : Timestamp.t) =
  if debug then print event time
;;

let add_event (t : t) (event : Event.Ok.Data.t) (time : Timestamp.t) =
  print event time;
  assert (Timestamp.( >= ) time t.last_event_time);
  t.last_event_time <- time;
  match event with
  (* TODO Get the untraced "kind" right instead of always showing [Location.untraced] for untraced time. *)
  | Trace { trace_state_change = Some Start; dst; _ } -> handle_return t time ~dst
  | Trace { trace_state_change = Some End; src; dst = _; _ } ->
    handle_call t time ~src ~dst:Location.untraced
  | Trace
      { kind = Some (Call | Syscall | Hardware_interrupt | Interrupt)
      ; src
      ; dst
      ; trace_state_change = _
      } -> handle_call t time ~src ~dst
  | Trace { kind = Some (Return | Sysret | Iret); dst; _ } -> handle_return t time ~dst
  | Trace { kind = Some (Jump | Async); dst; _ } -> handle_jump t time ~dst
  (* TODO *)
  | Trace { kind = Some Tx_abort | None; _ }
  | Power _ | Stacktrace_sample _ | Event_sample _ -> ()
;;

module Writer : sig
  type t

  val create : Tracing.Trace.t -> Tracing.Trace.Thread.t -> Elf.Addr_table.t -> t @ local
  val emit_frame_enter : t @ local -> Timestamp.t -> Location.t -> unit
  val emit_frame_exit : t @ local -> Timestamp.t -> Location.t -> unit
end = struct
  type t =
    { mutable last_time : Timestamp.t @@ global
    ; active_frames : Symbol.t Vec.t @@ global
    (** Strictly speaking maintaining [last_time] and [active_frames] is not necessary
        assuming the rest of the code is written correctly, but not checking our
        invariants makes it *much* harder to figure out where things go wrong, because you
        would just end up with a mangled Perfetto trace but the [magic-trace] invocation
        would complete silently and successfully. *)
    ; trace : Tracing.Trace.t @@ global
    ; thread : Tracing.Trace.Thread.t @@ global
    ; debug_info : Elf.Addr_table.t @@ global
    }

  let create trace thread debug_info = exclave_
    stack_
      { last_time = Timestamp.zero
      ; active_frames = Vec.create ()
      ; trace
      ; thread
      ; debug_info
      }
  ;;

  let location_args debug_info (location : Location.t) =
    let display_name = Symbol.display_name location.symbol in
    let base_address =
      Int64.(location.instruction_pointer - of_int location.symbol_offset)
    in
    let open Tracing.Trace.Arg in
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
    let address = "address", Pointer location.instruction_pointer in
    match location.symbol with
    | From_perf_map { start_addr = _; size = _; function_ = _ } ->
      address :: [ "symbol", Interned display_name ]
    | _ ->
      (match Option.bind (Int64.to_int base_address) ~f:(Hashtbl.find debug_info) with
       | None -> address :: [ "symbol", Interned display_name ]
       | Some (info : Elf.Location.t) ->
         (address
          :: [ "line", Int info.line
             ; "col", Int info.col
             ; "symbol", Interned display_name
             ])
         @
           (match info.filename with
           | Some x -> [ "file", Interned x ]
           | None -> []))
  ;;

  let emit_frame_enter (t : t) (time : Timestamp.t) (location : Location.t) =
    assert (Timestamp.( >= ) time t.last_time);
    t.last_time <- time;
    Vec.push_back t.active_frames location.symbol;
    if debug then eprintf "Enter %s\n" (Symbol.display_name location.symbol);
    Tracing.Trace.write_duration_begin
      t.trace
      ~args:(location_args t.debug_info location)
      ~thread:t.thread
      ~name:(Symbol.display_name location.symbol)
      ~time:(time :> Time_ns.Span.t)
      ~category:""
  ;;

  let emit_frame_exit t (time : Timestamp.t) (location : Location.t) =
    assert (Timestamp.( >= ) time t.last_time);
    t.last_time <- time;
    [%test_result: Symbol.t] ~expect:(Vec.pop_back_exn t.active_frames) location.symbol;
    if debug then eprintf "Exit %s\n" (Symbol.display_name location.symbol);
    Tracing.Trace.write_duration_end
      t.trace
      ~args:[]
      ~thread:t.thread
      ~name:(Symbol.display_name location.symbol)
      ~time:(time :> Time_ns.Span.t)
      ~category:""
  ;;
end

(* Intel PT may produce many events with the same timestamp due to resolution limitations.
   To produce better visual traces, we "smear" time, evenly distributing time amongst runs
   of consecutive events that all have the same timestamp. *)
let smear_times (callstacks : Callstack.t Nonempty_vec.t) =
  (* It would be reasonable to also have [Return]s consume time, but making them not consume
     time substantially reduces the frequency where we need to use zero-duration events.
     In general the traces are easier to read if returns aren't counted as consuming time. *)
  let[@inline always] consumes_time : Control_flow.t -> bool = function
    | Call | Jump -> true
    | _ -> false
  in
  let len = Nonempty_vec.length callstacks in
  let mutable i = 0 in
  while i < len do
    let t1 = (Nonempty_vec.get callstacks i).#time in
    (* Find the end of the run of events with the same timestamp *)
    let mutable run_end = i in
    let mutable num_time_consuming_events =
      consumes_time (Nonempty_vec.get callstacks i).#control_flow |> Bool.to_int
    in
    while
      run_end + 1 < len
      && Timestamp.equal (Nonempty_vec.get callstacks (run_end + 1)).#time t1
    do
      num_time_consuming_events
      <- num_time_consuming_events
         + (consumes_time (Nonempty_vec.get callstacks (run_end + 1)).#control_flow
            |> Bool.to_int);
      run_end <- run_end + 1
    done;
    num_time_consuming_events <- Int.max 1 num_time_consuming_events;
    let run_length = run_end - i + 1 in
    if run_end + 1 < len
    then (
      (* Smear times across this run *)
      let t2 = (Nonempty_vec.get callstacks (run_end + 1)).#time in
      let duration_ns =
        Time_ns.Span.( - ) (t2 :> Time_ns.Span.t) (t1 :> Time_ns.Span.t)
        |> Time_ns.Span.to_int_ns
      in
      let mutable time_consuming_events_seen = 0 in
      for k = 0 to run_length - 1 do
        let cs = Nonempty_vec.get callstacks (i + k) in
        let offset_ns =
          duration_ns * time_consuming_events_seen / num_time_consuming_events
        in
        let smeared_time =
          Timestamp.create Time_ns.Span.((t1 :> Time_ns.Span.t) + of_int_ns offset_ns)
        in
        (* Rewriting the entire [Callstack.t] instead of modifying just the [time] field
           in-place is sad, but I'm not sure the microoptimization is worth the hassle
           it'd take to achieve it. *)
        Nonempty_vec.set callstacks (i + k) #{ cs with time = smeared_time };
        time_consuming_events_seen
        <- time_consuming_events_seen + (consumes_time cs.#control_flow |> Bool.to_int)
      done
      (* else: final run - keep original times *));
    i <- run_end + 1
  done
;;

let write_trace
  (t : t)
  (trace : Tracing.Trace.t)
  thread
  debug_info
  ~enter_initial_callstack
  ~exit_final_callstack
  =
  let writer = Writer.create trace thread debug_info in
  if Nonempty_vec.length t.callstacks > 1
  then (
    smear_times t.callstacks;
    if enter_initial_callstack
    then (
      let first_callstack = Nonempty_vec.get t.callstacks 1 in
      let () =
        match first_callstack.#leaf.parent with
        | Null -> ()
        | This parent_frame ->
          (* Emit a frame enter for everything except the leaf in the initial callstack. We
             need to do this because otherwise we'd be missing parent frames in the trace that
             we discovered by returning into them (see the [Null] case in [handle_return]). *)
          Frame.iter_rev parent_frame ~f:(stack_ fun frame ->
            Writer.emit_frame_enter writer first_callstack.#time frame.location)
      in
      (* Modify [t.callstacks] so that the first pair processed in
         [Nonempty_vec.iter_pairs] below calls [emit_frame_enter] for the leaf frame. *)
      Nonempty_vec.set t.callstacks 1 #{ first_callstack with control_flow = Call });
    Nonempty_vec.iter_pairs
      t.callstacks
      ~f:(stack_ fun (#(prev, curr) : #(Callstack.t * Callstack.t)) ->
        let time = curr.#time in
        match curr.#control_flow with
        | Jump ->
          Writer.emit_frame_exit writer time prev.#leaf.location;
          Writer.emit_frame_enter writer time curr.#leaf.location
        | Call -> Writer.emit_frame_enter writer time curr.#leaf.location
        | Return { distance } ->
          Frame.iter_n prev.#leaf distance ~f:(stack_ fun frame ->
            Writer.emit_frame_exit writer time frame.location)
          [@nontail]);
    if exit_final_callstack
    then (
      (* Call [emit_frame_exit] for all remaining frames at the end of the segment. *)
      let last_callstack = Nonempty_vec.last t.callstacks in
      Frame.iter_n last_callstack.#leaf Int.max_value ~f:(stack_ fun frame ->
        Writer.emit_frame_exit writer last_callstack.#time frame.location)
      [@nontail]))
;;

module%test _ = struct
  (* Takes a string like "a-b-c-d-e" which describes a callstack in root-to-leaf order,
     each letter being a function name. *)
  let parse_frames string =
    let root = Frame.Sentinel.create () in
    let leaf =
      String.split string ~on:'-'
      |> List.fold
           ~init:(root :> Frame.t)
           ~f:(fun root leaf_name ->
             Frame.create
               Location.
                 { symbol_offset = 0
                 ; instruction_pointer = 0L
                 ; symbol = From_perf leaf_name
                 }
               ~parent:root)
    in
    #(~root, ~leaf)
  ;;

  (* Throughout this test-suite, things are rendered vertically in the same way they'd
     appear in the Perfetto viewer. *)

  let print_frame_callstack = Frame.For_testing.print_callstack

  let%expect_test "[parse_frames] utility" =
    let #(~root:_, ~leaf) = parse_frames "a-b-c-d-e" in
    print_frame_callstack leaf;
    [%expect {|
      a
      b
      c
      d
      e
      |}]
  ;;

  module%test Smear_times = struct
    let create_callstacks_with_control_flow (items : (int * Control_flow.t) list)
      : Callstack.t Nonempty_vec.t
      =
      let #(~root:_, ~leaf) = parse_frames "a" in
      match items with
      | [] -> assert false
      | (first_time, first_cf) :: rest ->
        let vec =
          Nonempty_vec.create
            (#{ time = Timestamp.create (Time_ns.Span.of_int_ns first_time)
              ; leaf
              ; control_flow = first_cf
              }
             : Callstack.t)
        in
        List.iter rest ~f:(fun (t, cf) ->
          Nonempty_vec.push_back
            vec
            (#{ time = Timestamp.create (Time_ns.Span.of_int_ns t)
              ; leaf
              ; control_flow = cf
              }
             : Callstack.t));
        vec
    ;;

    let create_callstacks (times : int list) : Callstack.t Nonempty_vec.t =
      List.map ~f:(fun time -> time, Control_flow.Call) times
      |> create_callstacks_with_control_flow
    ;;

    let print_times (callstacks : Callstack.t Nonempty_vec.t) =
      Nonempty_vec.iter callstacks ~f:(fun (cs : Callstack.t) ->
        printf "%2d " (Time_ns.Span.to_int_ns (cs.#time :> Time_ns.Span.t)));
      print_endline ""
    ;;

    let%expect_test "[smear_times] with all different timestamps (no smearing needed)" =
      let callstacks = create_callstacks [ 0; 10; 20; 30 ] in
      print_times callstacks;
      [%expect {|  0 10 20 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 |}]
    ;;

    let%expect_test "[smear_times] with consecutive same timestamps" =
      let callstacks = create_callstacks [ 0; 0; 0; 30 ] in
      print_times callstacks;
      [%expect {|  0  0  0 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 |}]
    ;;

    let%expect_test "[smear_times] with multiple runs of same timestamps" =
      let callstacks = create_callstacks [ 0; 0; 20; 20; 20; 50 ] in
      print_times callstacks;
      [%expect {|  0  0 20 20 20 50 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 40 50 |}]
    ;;

    let%expect_test "[smear_times] final run keeps original time" =
      let callstacks = create_callstacks [ 0; 0; 30; 30; 30 ] in
      print_times callstacks;
      [%expect {|  0  0 30 30 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 15 30 30 30 |}]
    ;;

    let%expect_test "[smear_times] single event" =
      let callstacks = create_callstacks [ 100 ] in
      print_times callstacks;
      [%expect {| 100 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {| 100 |}]
    ;;

    let%expect_test "[smear_times] all same timestamp (final run)" =
      let callstacks = create_callstacks [ 50; 50; 50 ] in
      print_times callstacks;
      [%expect {| 50 50 50 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {| 50 50 50 |}]
    ;;

    let%expect_test "[smear_times] only Call and Jump events consume time" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Return { distance = 1 }
          ; 0, Call
          ; 0, Return { distance = 1 }
          ; 0, Jump
          ; 100, Call
          ]
      in
      print_times callstacks;
      [%expect {|  0  0  0  0 100 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0  0 50 50 100 |}]
    ;;

    let%expect_test "[smear_times] first event is a Call" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Call; 0, Return { distance = 1 }; 0, Jump; 90, Call ]
      in
      print_times callstacks;
      [%expect {|  0  0  0 90 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 45 45 90 |}]
    ;;

    let%expect_test "[smear_times] only Returns uses fallback" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Return { distance = 1 }
          ; 0, Return { distance = 1 }
          ; 0, Return { distance = 1 }
          ; 90, Call
          ]
      in
      print_times callstacks;
      [%expect {|  0  0  0 90 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0  0  0 90 |}]
    ;;
  end

  let setup_test () =
    let t = create () in
    let ip = ref (-1) in
    let time = ref Time_ns.Span.zero in
    let incr_time () = time := Time_ns.Span.(!time + of_int_ns 1) in
    let location (name : string) : Location.t =
      incr ip;
      Location.
        { instruction_pointer = Int64.of_int !ip
        ; symbol_offset = 0
        ; symbol = From_perf name
        }
    in
    let call ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Call
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    let return ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Return
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    let jump ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Jump
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    #(~t, ~call, ~return, ~jump)
  ;;

  let frames_to_list t =
    let result = ref [] in
    Nonempty_vec.iter t.callstacks ~f:(fun (cs : Callstack.t) ->
      result := cs.#leaf :: !result);
    List.rev !result
  ;;

  let concat_horizontal (lists : string list list) : string =
    let max_len =
      List.fold lists ~init:0 ~f:(fun acc lst -> Int.max acc (List.length lst))
    in
    let width = 20 in
    List.init max_len ~f:(fun row_idx ->
      List.map lists ~f:(fun lst ->
        let s = List.nth lst row_idx |> Option.value ~default:"" in
        sprintf "%-*s" width s)
      |> String.concat)
    |> String.concat ~sep:"\n"
  ;;

  let print_callstacks (t : t) =
    frames_to_list t
    (* Skip the initial sentinel callstack *)
    |> List.tl
    |> Option.value ~default:[]
    |> List.map ~f:(fun frame -> Frame.For_testing.to_string_list frame)
    |> concat_horizontal
    |> print_endline;
    (* So that the closing |}] of the [%expect ...] block is on its own line. *)
    print_endline "-"
  ;;

  (* In all of the following examples, unless otherwise specified assume no
     tail-call-optimization is performed. *)

  (*=
       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()
    *)
  let%expect_test "Sanity-check [add_event]" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    (* Return from [fn3] *)
    return ~src:"fn3" ~dst:"fn1";
    (* Return from [fn1] *)
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       Assume we started tracing during the execution of [main] so we never saw the calls to [start] or [init]

       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()

       let start () = main ()
       let init () = start ()
    *)
  let%expect_test "A return to a function we never saw the call for" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    return ~src:"fn3" ~dst:"fn1";
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}];
    (* Return for a call we didn't see *)
    return ~src:"main" ~dst:"start";
    print_callstacks t;
    [%expect
      {|
      start               start               start               start               start               start               start               start
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}];
    (* Another return for a call we didn't see *)
    return ~src:"start" ~dst:"init";
    print_callstacks t;
    [%expect
      {|
      init                init                init                init                init                init                init                init                init
      start               start               start               start               start               start               start               start
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       let fn2 () = ()
       let fn3 () = raise Failure

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = try fn1 () with _ -> ()
       *)
  let%expect_test "Return multiple levels up the stack" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    (* Raise from [fn3] into the [try] in [main] *)
    return ~src:"fn3" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       let fn1 () =
         if something then do_something else do_something_else
       ;;

       let main () = fn1 ()
       *)
  let%expect_test "Simple jumps within a function" =
    let #(~t, ~call, ~return, ~jump) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    jump ~src:"fn1" ~dst:"fn1";
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main
                          fn1
      -
      |}]
  ;;

  (*=

       let fn2 () = ()
       let fn1 () = fn2() [@tail]

       let main () = fn1 ()
       *)
  let%expect_test "Tail-call" =
    let #(~t, ~call, ~return, ~jump) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    (* Tail-call [fn2] from [fn1] *)
    jump ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main
                          fn1                 fn2
      -
      |}]
  ;;
end
