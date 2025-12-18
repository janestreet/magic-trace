open! Core
module Location = Event.Location
module Nonempty_vec = Nonempty_vec.Valuex3

module Frame : sig
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  val create : Location.t -> parent:t Or_null.t -> t
  val root : t -> t
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
    val consume : t -> Location.t -> parent:frame -> frame
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

  let[@inline always] create location ~parent = { location; parent }

  let rec root t =
    match t with
    | { parent = Null; _ } | { parent = This { parent = Null; _ }; _ } -> t
    | { parent = This parent; _ } -> root parent
  ;;

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

    let consume t location ~parent =
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
  let new_sentinel = Frame.Sentinel.create () in
  let root = Frame.Sentinel.consume t.root location ~parent:(new_sentinel :> Frame.t) in
  t.root <- new_sentinel;
  root
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

(* let handle_trace_end t time ~src ~dst = handle_call t time ~src ~dst *)

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

let print_all_callstacks t =
  Nonempty_vec.iter t.callstacks ~f:(fun callstack ->
    Frame.For_testing.to_string_list callstack.#leaf
    |> String.concat ~sep:"  "
    |> Debug.eprint)
  [@nontail]
;;

let[@inline always] print (event : Event.Ok.Data.t) (time : Timestamp.t) =
  if debug then print event time
;;

let add_event (t : t) (event : Event.Ok.Data.t) (time : Timestamp.t) =
  print event time;
  match event with
  | Trace { trace_state_change = Some _; _ } -> ()
  | Trace { kind = Some (Call | Syscall); src; dst; trace_state_change = _ } ->
    handle_call t time ~src ~dst
  | Trace { kind = Some Return; src; dst; trace_state_change = _ } ->
    handle_return t time ~src ~dst
  | Trace { kind = Some (Jump | Async); src; dst; trace_state_change = _ } ->
    handle_jump t time ~src ~dst
  | _ -> (* TODO *) ()
;;

let start_time t =
  if Nonempty_vec.length t.callstacks = 1
  then Null
  else This (Nonempty_vec.get t.callstacks 1).#time
;;

let end_time t =
  if Nonempty_vec.length t.callstacks = 1
  then Null
  else This (Nonempty_vec.last t.callstacks).#time
;;

let emit_frame_enter
  (trace : Tracing.Trace.t)
  thread
  (time : Timestamp.t)
  (location : Location.t)
  =
  if debug then Debug.eprintf "Enter %s\n" (Symbol.display_name location.symbol);
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
  if debug then Debug.eprintf "Exit %s\n" (Symbol.display_name location.symbol);
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
        (* Debug.eprint *)
        (*   ("Handling jump from callstack: " *)
        (*    ^ (Frame.For_testing.to_string_list prev.#leaf |> String.concat ~sep:" -> ")); *)
        (*    Debug.eprintf "Jumping from %s to %s\n" (Symbol.display_name prev.#leaf.location.symbol) (Symbol.display_name curr.#leaf.location.symbol); *)
        emit_frame_exit time prev.#leaf.location;
        emit_frame_enter time curr.#leaf.location)
    | Call ->
      (* Debug.eprint *)
      (*   ("Handling call from callstack: " *)
      (*    ^ (Frame.For_testing.to_string_list prev.#leaf |> String.concat ~sep:" -> ")); *)
      (* Debug.eprintf "Calling %s from %s\n" (Symbol.display_name curr.#leaf.location.symbol) (Symbol.display_name prev.#leaf.location.symbol); *)
      Frame.iter_until_rev
        curr.#leaf
        prev.#leaf.location.symbol
        ~f:(stack_ fun [@inline always] frame -> emit_frame_enter time frame.location)
      [@nontail]
    | Return ->
      (* Debug.eprint *)
      (*   ("Handling return from callstack: " *)
      (*    ^ (Frame.For_testing.to_string_list prev.#leaf |> String.concat ~sep:" -> ")); *)
      (* Debug.eprintf *)
      (*   "Returning to symbol %s\n" *)
      (*   (Symbol.display_name curr.#leaf.location.symbol); *)
      Frame.iter_until
        prev.#leaf
        curr.#leaf.location.symbol
        ~f:(stack_ fun [@inline always] frame -> emit_frame_exit time frame.location)
      [@nontail])
;;

let write_trace
  (t : t)
  (trace : Tracing.Trace.t)
  thread
  ~enter_initial_callstack
  ~exit_final_callstack
  =
  if Nonempty_vec.length t.callstacks > 1
  then (
    if enter_initial_callstack
    then (
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
        #{ (Nonempty_vec.get t.callstacks 1) with control_flow = Call });
    let emit_trace_events = Staged.unstage (make_emit_trace_events trace thread) in
    Nonempty_vec.iter_pairs t.callstacks ~f:emit_trace_events;
    if exit_final_callstack
    then (
      (* Morally this is equivalent to if there was a sentinel at the end of [t.callstacks]
       with [control_flow = Return], but to avoid the possibility of needlessly
       reallocating the vector, we do this directly. *)
      let last_callstack = Nonempty_vec.last t.callstacks in
      emit_trace_events
        #( last_callstack
         , #{ time = last_callstack.#time
            ; leaf = (t.root :> Frame.t)
            ; control_flow = Return
            } ) [@nontail]))
;;

module Stitch_result = struct
  type t =
    | Stitched
    | Indepdenent
  [@@deriving sexp_of, compare]
end

let stitch ~(before : t) ~(after : t) : Stitch_result.t =
  let end_of_before = (Nonempty_vec.last before.callstacks).#leaf in
  let start_of_after = Frame.root (Nonempty_vec.first after.callstacks).#leaf in
  match Frame.find end_of_before start_of_after.location.symbol with
  | Null ->
    (* [before] and [after] share no common ancestor, so there is nothing to be done. *)
    Indepdenent
  | This { parent = Null; _ } ->
    (* It's imposisble for [Frame.find] to return a sentinel. *)
    assert false
  | This { parent = This { parent = Null; _ }; _ } ->
    (* The root of [before] and the root of [after] are already the same, do nothing. *)
    Stitched
  | This
      { parent =
          This ({ parent = This before_version_grandparent; _ } as before_version_parent)
      ; _
      } ->
    let _ =
      Frame.Sentinel.consume
        after.root
        before_version_parent.location
        ~parent:before_version_grandparent
    in
    after.root <- before.root;
    Stitched
;;

module%test _ = struct
  (* Takes a string like "a-b-c-d-e" which describes a callstack in root-to-leaf
     order, each letter being a function name. *)
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
               ~parent:(This root))
    in
    #(~root, ~leaf)
  ;;

  (* Throughout this test-suite, things are rendered vertically in the same way they'd appear in the Perfetto viewer. *)

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

  let create_singelton (frames : string) : t =
    let #(~root, ~leaf) = parse_frames frames in
    { root
    ; callstacks =
        Nonempty_vec.create
          Callstack.(#{ time = Timestamp.zero; control_flow = Call; leaf })
    }
  ;;

  let print_singleton_callstack t =
    print_frame_callstack (Nonempty_vec.first t.callstacks).#leaf
  ;;

  let%expect_test "[stitch] with common ancestor" =
    let before : t = create_singelton "a-b-c-d-e" in
    let after : t = create_singelton "d-f" in
    print_endline "--- [after] ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] ---
      d
      f
      |}];
    [%test_result: Stitch_result.t] ~expect:Stitched (stitch ~before ~after);
    print_endline "--- [after] stitched ---";
    print_singleton_callstack after;
    [%expect
      {|
      --- [after] stitched ---
      a
      b
      c
      d
      f
      |}]
  ;;

  let%expect_test "[stitch] with no common ancestor" =
    let before : t = create_singelton "a-b-c-d-e" in
    let after : t = create_singelton "x-e" in
    print_endline "--- [after] ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] ---
      x
      e
      |}];
    [%test_result: Stitch_result.t] ~expect:Indepdenent (stitch ~before ~after);
    print_endline "--- [after] stitched ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] stitched ---
      x
      e
      |}]
  ;;

  let%expect_test "[stitch] where common ancestor is already the root of both [before] \
                   and [after]"
    =
    let before : t = create_singelton "a-b-c-d-e" in
    let after : t = create_singelton "a-b-c-f-g" in
    print_endline "--- [after] ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] ---
      a
      b
      c
      f
      g
      |}];
    [%test_result: Stitch_result.t] ~expect:Stitched (stitch ~before ~after);
    print_endline "--- [after] stitched ---";
    print_singleton_callstack after;
    [%expect
      {|
      --- [after] stitched ---
      a
      b
      c
      f
      g
      |}]
  ;;

  let%expect_test "[stitch] where common ancestor is just below the root" =
    let before : t = create_singelton "a-b-c-d-e" in
    let after : t = create_singelton "b-c-f-g" in
    print_endline "--- [after] ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] ---
      b
      c
      f
      g
      |}];
    [%test_result: Stitch_result.t] ~expect:Stitched (stitch ~before ~after);
    print_endline "--- [after] stitched ---";
    print_singleton_callstack after;
    [%expect
      {|
      --- [after] stitched ---
      a
      b
      c
      f
      g
      |}]
  ;;

  let%expect_test "[stitch] where common ancestor is leaf of [after]" =
    let before : t = create_singelton "a-b-c-d-e" in
    let after : t = create_singelton "e" in
    print_endline "--- [after] ---";
    print_singleton_callstack after;
    [%expect {|
      --- [after] ---
      e
      |}];
    [%test_result: Stitch_result.t] ~expect:Stitched (stitch ~before ~after);
    print_endline "--- [after] stitched ---";
    print_singleton_callstack after;
    [%expect
      {|
      --- [after] stitched ---
      a
      b
      c
      d
      e
      |}]
  ;;

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
