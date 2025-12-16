open! Core
module Location = Event.Location

module Frame : sig
  (* The fields can only be mutated on a sentinel instance, via [replace_sentinel]. *)
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  val find : t -> Symbol.t -> t Or_null.t
  val create : Location.t -> parent:t Or_null.t -> t
  val create_sentinel : unit -> t
  val replace_sentinel : t -> Location.t -> #(frame:t * new_sentinel:t)

  module For_testing : sig
    val to_string_list : t -> string list
  end
end = struct
  type t =
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  let rec find t target =
    match t with
    | { location = { symbol; _ }; _ } when Symbol.equal symbol target -> This t
    | { parent = Null; _ } -> Null
    | { parent = This parent; _ } -> find parent target
  ;;

  let[@inline always] create location ~parent = { location; parent }

  let sentinel_location : Location.t =
    { instruction_pointer = 0L; symbol_offset = 0; symbol = Unknown }
  ;;

  let[@inline always] create_sentinel () = { location = sentinel_location; parent = Null }

  let replace_sentinel sentinel location =
    assert (phys_equal sentinel.location sentinel_location);
    let new_sentinel = create_sentinel () in
    sentinel.location <- location;
    sentinel.parent <- This new_sentinel;
    #(~frame:sentinel, ~new_sentinel)
  ;;

  module For_testing = struct
    let rec to_string_list acc t =
      match t.parent with
      | Null -> acc (* Stop before sentinel - sentinel has no parent *)
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
  { mutable root : Frame.t (** Invariant: [root] is always a sentinel. *)
  ; callstacks : Callstack.t Nonempty_vec.t
  }

let create () =
  let root = Frame.create_sentinel () in
  { root
  ; callstacks =
      Nonempty_vec.create
        (#{ time = Timestamp.zero; leaf = root; control_flow = Jump } : Callstack.t)
  }
;;

let[@inline always] current_frame t = (Nonempty_vec.last t.callstacks).#leaf

let replace_root t location =
  let #(~frame, ~new_sentinel) = Frame.replace_sentinel t.root location in
  t.root <- new_sentinel;
  frame
;;

let handle_call (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  match Frame.find (current_frame t) src.symbol with
  | This _ as src_frame ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:src_frame; control_flow = Call }
  | Null ->
    (* I would only expect this to happen if this call is the very first event in this
       trace-segment. *)
    let src_frame = replace_root t src in
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:(This src_frame); control_flow = Call }
;;

let handle_return (t : t) (time : Timestamp.t) ~src:_ ~(dst : Location.t) =
  match Frame.find (current_frame t) dst.symbol with
  | This { parent; _ } ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent; control_flow = Return }
  | Null ->
    (* We have returned into something we never saw the call for. This can happen if there
       is a sequence of calls like [fn1 -> fn2 -> fn3] and we started tracing during the
       execution of [fn2]. *)
    let dst_frame = replace_root t dst in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow = Return }
;;

let handle_jump (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  let current_frame = current_frame t in
  match Frame.find current_frame src.symbol with
  | This src_frame ->
    (* This is either a branch within a function or a (possibly recursive) tail-call *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:src_frame.parent; control_flow = Jump }
  | Null when not (Symbol.equal src.symbol dst.symbol) ->
    let dst_frame =
      match Frame.find current_frame dst.symbol with
      | This { parent; _ } -> Frame.create dst ~parent
      | Null -> replace_root t dst
    in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow = Jump }
  | Null ->
    let dst_frame = replace_root t dst in
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame; control_flow = Jump }
;;

let add_event (t : t) (event : Event.Ok.Data.t) (time : Timestamp.t) =
  match event with
  | Trace { kind = Some Call; src; dst; trace_state_change = _ } ->
    handle_call t time ~src ~dst
  | Trace { kind = Some Return; src; dst; trace_state_change = _ } ->
    handle_return t time ~src ~dst
  | Trace { kind = Some Jump; src; dst; trace_state_change = _ } ->
    handle_jump t time ~src ~dst
  | _ -> assert false
;;

let emit_frame_enter (_time : Timestamp.t) (_location : Location.t) =
  (* Intentionally left unimplemented for now, just pretend this does what it says. *)
  ()
;;

let emit_frame_exit (_time : Timestamp.t) (_location : Location.t) =
  (* Intentionally left unimplemented for now, just pretend this does what it says. *)
  ()
;;

(* Temporarily ignore unused function warnings *)
let _ = emit_frame_enter
let _ = emit_frame_exit

let write_trace (t : t) =
  (* Temporarily ignore unused variable warning, delete this line when you start writing
     code! *)
  ignore (t : t);
  (*=
     Here's pseudocode of what this function should do:
     ```
     for i in range(1, len(t.callstacks)):
       prev_callstack = t.callstacks[i - 1]
       curr_callstack = t.callstacks[i]
       if prev_callstack.depth > curr_callstack.depth:
         iterate through prev_callstack leaf-to-root until you reach
         curr_callstack.leaf, emitting frame_exit events as
         you go.
       elif prev_callstack.depth < curr_callstack.depth:
         iterate through curr_callstack leaf-to-root until you reach
         prev_callstack.leaf, emitting frame_enter events **in
         the inverse order of iteration** (i.e. this will *not* be tail-recursive)
       elif prev_callstack.leaf.location.symbol != curr_callstack.leaf.location.symbol:
         emit a frame_exit event for prev_callstack.leaf, then emit a
         frame_enter event for curr_callstack.leaf
     ```

     The nice thing about the first element of being a sentinel is that all of this works
     without needing a special-case for the initial callstack.
   *)
  ()
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
