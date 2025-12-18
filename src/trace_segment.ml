open! Core
module Location = Event.Location
module Nonempty_vec = Nonempty_vec.Valuex3

module Frame : sig
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  val create : Location.t -> parent:t Or_null.t -> t
  val find : t -> Symbol.t -> t Or_null.t

  (** Iterate through [t] until reaching a frame whose symbol matches the provided
      argument. *)
  val iter_until : t -> Symbol.t -> f:local_ (t -> unit) -> unit

  (** Like [iter_until], except that the callback [f] is called in root-to-leaf order. *)
  val iter_until_rev : t -> Symbol.t -> f:local_ (t -> unit) -> unit

  module Sentinel : sig
    type frame := t

    (** The root of a callstack. A sentinel does not correspond to a real program
        location, and its parent is always [Null]; it is the *only* frame allowed to have
        a [Null] parent.

        Using a sentinel allows us to avoid a variety of special-cases, and lets us update
        the root of all callstacks in a trace in O(1) time. *)
    type t = private frame

    val create : unit -> t

    (* TODO do this by accepting a mutable interior pointer to a [t] so that we can hide
       the implementation details instead of requiring the user of this module to mutate
       their sentinel to [new_sentinel]. *)
    val append : t -> Location.t -> #(frame:frame * new_sentinel:t)
  end

  module For_testing : sig
    val to_string_list : t -> string list
  end
end = struct
  type t =
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  let[@inline always] create location ~parent = { location; parent }

  let rec find t target =
    match t with
    | { parent = Null; _ } -> Null
    | { location = { symbol; _ }; _ } when Symbol.equal symbol target -> This t
    | { parent = This parent; _ } -> find parent target
  ;;

  let[@inline always] rec iter_until t stop_symbol ~f =
    match t with
    | { parent = Null; _ } -> ()
    | { location = { symbol; _ }; _ } when Symbol.equal symbol stop_symbol -> ()
    | { parent = This parent; _ } ->
      (f [@inlined hint]) t;
      iter_until parent stop_symbol ~f
  ;;

  let[@inline always] rec iter_until_rev t stop_symbol ~f =
    match t with
    | { parent = Null; _ } -> ()
    | { location = { symbol; _ }; _ } when Symbol.equal symbol stop_symbol -> ()
    | { parent = This parent; _ } ->
      iter_until_rev parent stop_symbol ~f;
      (f [@inlined hint]) t
  ;;

  module Sentinel = struct
    type nonrec t = t

    let sentinel_location : Location.t =
      { instruction_pointer = 0L; symbol_offset = 0; symbol = Unknown }
    ;;

    let[@inline always] create () = { location = sentinel_location; parent = Null }

    let append sentinel location =
      let new_sentinel = create () in
      sentinel.location <- location;
      sentinel.parent <- This new_sentinel;
      #(~frame:sentinel, ~new_sentinel)
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
  end
end

module Control_flow = struct
  type t =
    | Jump
    | Call
    | Return
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
  ; callstacks : Callstack.t Nonempty_vec.t
  }

let create () =
  let root = Frame.Sentinel.create () in
  { root
  ; callstacks =
      Nonempty_vec.create
        (#{ time = Timestamp.zero; leaf = (root :> Frame.t); control_flow = Return }
         : Callstack.t)
  }
;;

let[@inline always] current_frame t = (Nonempty_vec.last t.callstacks).#leaf

let replace_root t location =
  let #(~frame, ~new_sentinel) = Frame.Sentinel.append t.root location in
  t.root <- new_sentinel;
  frame
;;

let handle_call (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  let control_flow : Control_flow.t = Call in
  match Frame.find (current_frame t) src.symbol with
  | This _ as src_frame ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:src_frame; control_flow }
  | Null ->
    (* I would only expect this to happen if this call is the very first event in this
       trace-segment. *)
    let src_frame = replace_root t src in
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:(This src_frame); control_flow }
;;

let handle_return (t : t) (time : Timestamp.t) ~src:_ ~(dst : Location.t) =
  let control_flow : Control_flow.t = Return in
  match Frame.find (current_frame t) dst.symbol with
  | This { parent; _ } ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent; control_flow }
  | Null ->
    (* We have returned into something we never saw the call for. This can happen if there
       is a sequence of calls like [fn1 -> fn2 -> fn3] and we started tracing during the
       execution of [fn2]. *)
    let dst_frame = replace_root t dst in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow }
;;

let handle_jump (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  let control_flow : Control_flow.t = Jump in
  let current_frame = current_frame t in
  match Frame.find current_frame src.symbol with
  | This src_frame ->
    (* This is either a branch within a function or a (possibly recursive) tail-call *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:src_frame.parent; control_flow }
  | Null when not (Symbol.equal src.symbol dst.symbol) ->
    let dst_frame =
      match Frame.find current_frame dst.symbol with
      | This { parent; _ } -> Frame.create dst ~parent
      | Null -> replace_root t dst
    in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow }
  | Null ->
    let dst_frame = replace_root t dst in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow }
;;

let handle_trace_end t time ~src = handle_jump t time ~src ~dst:src

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
  match event with
  | Trace { trace_state_change = Some End; src; _ } -> handle_trace_end t time ~src
  | Trace { kind = Some (Call | Syscall); src; dst; trace_state_change = _ } ->
    handle_call t time ~src ~dst
  | Trace { kind = Some Return; src; dst; trace_state_change = _ } ->
    handle_return t time ~src ~dst
  | Trace { kind = Some (Jump | Async); src; dst; trace_state_change = _ } ->
    handle_jump t time ~src ~dst
  | _ -> (* TODO *) ()
;;

let emit_frame_enter
  (trace : Tracing.Trace.t)
  thread
  (time : Timestamp.t)
  (location : Location.t)
  =
  Tracing.Trace.write_duration_begin
    trace (* TODO: populate arguments *)
    ~args:[]
    ~thread
    ~name:(Symbol.display_name location.symbol)
    ~time:(time :> Time_ns.Span.t)
    ~category:""
;;

let emit_frame_exit
  (trace : Tracing.Trace.t)
  thread
  (time : Timestamp.t)
  (location : Location.t)
  =
  Tracing.Trace.write_duration_end
    trace
    ~args:[]
    ~thread
    ~name:(Symbol.display_name location.symbol)
    ~time:(time :> Time_ns.Span.t)
    ~category:""
;;

let make_emit_trace_events trace thread = exclave_
  Staged.stage (stack_ fun (#(prev, curr) : #(Callstack.t * Callstack.t)) ->
    let[@inline always] emit_frame_enter time location =
      emit_frame_enter trace thread time location
    in
    let[@inline always] emit_frame_exit time location =
      emit_frame_exit trace thread time location
    in
    let time = curr.#time in
    match curr.#control_flow with
    | Jump ->
      (* I'm not sure we even need to be recording a new callstack in the first place when
         the symbol doesn't change, but I need to double-check. *)
      if not (Symbol.equal prev.#leaf.location.symbol curr.#leaf.location.symbol)
      then (
        emit_frame_exit time prev.#leaf.location;
        emit_frame_enter time curr.#leaf.location)
    | Call ->
      Frame.iter_until_rev
        curr.#leaf
        prev.#leaf.location.symbol
        ~f:(stack_ fun [@inline always] frame -> emit_frame_enter time frame.location)
      [@nontail]
    | Return ->
      Frame.iter_until
        prev.#leaf
        curr.#leaf.location.symbol
        ~f:(stack_ fun [@inline always] frame -> emit_frame_exit time frame.location)
      [@nontail])
;;

let write_trace (t : t) (trace : Tracing.Trace.t) thread =
  let () =
    (* Modify [t.callstacks] so that the first invocation of [emit_trace_events] calls
       [emit_frame_enter] for the entire callstack. This is necessary because otherwise
       we'd be missing parent-frames in the trace that we discovered by returning into them
       (see the [Null] case in [handle_return]). *)
    Nonempty_vec.set
      t.callstacks
      0
      #{ (Nonempty_vec.get t.callstacks 0) with leaf = (t.root :> Frame.t) };
    Nonempty_vec.set
      t.callstacks
      1
      #{ (Nonempty_vec.get t.callstacks 1) with control_flow = Call }
  in
  let emit_trace_events = Staged.unstage (make_emit_trace_events trace thread) in
  Nonempty_vec.iter_pairs t.callstacks ~f:emit_trace_events;
  (* Morally this is equivalent to if there was a sentinel at the end of [t.callstacks]
     with [control_flow = Return], but to avoid the possibility of needlessly reallocating
     the vector, we do this directly. *)
  let last_callstack = Nonempty_vec.last t.callstacks in
  emit_trace_events
    #( last_callstack
     , #{ time = last_callstack.#time; leaf = (t.root :> Frame.t); control_flow = Return }
     ) [@nontail]
;;

module%test _ = struct
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
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}]
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
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}];
    (* Return for a call we didn't see *)
    return ~src:"main" ~dst:"start";
    print_callstacks t;
    [%expect
      {|
        start               start               start               start               start               start               start
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}];
    (* Another return for a call we didn't see *)
    return ~src:"start" ~dst:"init";
    print_callstacks t;
    [%expect
      {|
        init                init                init                init                init                init                init                init
        start               start               start               start               start               start               start
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}]
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
      main                main                main                main                main
      fn1                 fn1                 fn1                 fn1
                          fn2                                     fn3
      - |}]
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
        fn1                 fn1
        - |}]
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
        main                main                main
        fn1                 fn2
        - |}]
  ;;
end
