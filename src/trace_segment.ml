open! Core
module Location = Event.Location

(* I'm calling this [Vec] because using [Stack] throughout this code would make it
   somewhat confusing when we semantically have a "callstack" vs. "data-structure I am
   using to maintain multiple elements". *)
module Vec : sig
  type 'a t

  val create : unit -> 'a t
  val to_list : 'a t -> 'a list
  val of_list : 'a list -> 'a t
  val iter : 'a t -> f:('a -> unit) -> unit
  val last : 'a t -> 'a option
  val last_exn : 'a t -> 'a
  val pop_exn : 'a t -> 'a
  val push : 'a t -> 'a -> unit
end = struct
  include Stack

  let last = top
  let last_exn = top_exn
end

module Frame = struct
  type t =
    | None
    | Some of
        { location : Location.t
        ; mutable parent : t (** [parent] may only be mutated from [None] to [Some _]. *)
        }

  let rec find (target : Symbol.t) (frame : t) : t =
    match frame with
    | None -> None
    | Some { location = { symbol; _ }; parent = _ } when Symbol.equal symbol target ->
      frame
    | Some { parent = None; location = _ } -> None
    | Some { parent; location = _ } -> find target parent
  ;;

  module For_testing = struct
    let rec to_string_list acc t =
      match t with
      | None -> acc
      | Some { location = { symbol; _ }; parent } ->
        to_string_list (Symbol.display_name symbol :: acc) parent
    ;;
  end
end

module Callstack = struct
  type t =
    { time : Time_ns.Span.t
    ; mutable leaf : Frame.t (** [leaf] may only be mutated from [None] to [Some _]. *)
    }

  let rec root = function
    | Frame.None -> Frame.None
    | Some { parent = None; _ } as frame -> frame
    | Some { parent; _ } -> root parent
  ;;

  let root t = root t.leaf
end

type t = Callstack.t Vec.t

let handle_call (t : t) time ~(src : Location.t) ~dst =
  let matching_frame : Frame.t =
    match Vec.last t with
    | None -> None
    | Some { time = _; leaf } -> Frame.find src.symbol leaf
  in
  let leaf =
    match matching_frame with
    | None ->
      Frame.Some { location = dst; parent = Some { location = src; parent = None } }
    | matching_frame -> Frame.Some { location = dst; parent = matching_frame }
  in
  Vec.push t { time; leaf }
;;

let handle_ret (t : t) time ~(dst : Location.t) =
  let matching_frame : Frame.t =
    match Vec.last t with
    | None -> None
    | Some { time = _; leaf } -> Frame.find dst.symbol leaf
  in
  let leaf =
    match matching_frame with
    | None ->
      (* We have returned into something we never saw the call for. This can happen if
         there is a sequence of calls like [fn1 -> fn2 -> fn3] and we started tracing
         during the execution of [fn2]. When we return from [fn2] to [fn1], we need to
         amend the callstacks we have recorded so far to reflect that [fn1] is the parent
         frame for all of them. *)
      let frame = Frame.Some { location = dst; parent = None } in
      Vec.iter t ~f:(fun callstack ->
        match Callstack.root callstack with
        | None -> callstack.leaf <- frame
        | Some top_frame as top_frame' when not (phys_equal top_frame' frame) ->
          top_frame.parent <- frame
        | Some _ -> ());
      frame
    | Some matching_frame -> Some { matching_frame with location = dst }
  in
  Vec.push t { time; leaf }
;;

let create () = Vec.create ()

let add_event t (event : Event.Ok.Data.t) time =
  match event with
  | Trace { kind = Some Call; src; dst; trace_state_change = _ } ->
    handle_call t time ~src ~dst
  | Trace { kind = Some Return; dst; src = _; trace_state_change = _ } ->
    handle_ret t time ~dst
  (* This is just a proof-of-concept at the moment *)
  | Trace _
  | Event.Ok.Data.Power _
  | Event.Ok.Data.Stacktrace_sample _
  | Event.Ok.Data.Event_sample _ -> failwith "Unimplemented"
;;

let%test_module _ =
  (module struct
    let setup_test () =
      let callstacks = Vec.create () in
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
      let internal_stack = Vec.of_list [ location "main" ] in
      let call (name : string) =
        incr_time ();
        let new_location = location name in
        let event =
          Event.Ok.Data.Trace
            { kind = Some Call
            ; src = Vec.last_exn internal_stack
            ; dst = new_location
            ; trace_state_change = None
            }
        in
        Vec.push internal_stack new_location;
        add_event callstacks event !time
      in
      let return ?dst () =
        incr_time ();
        let src = Vec.pop_exn internal_stack in
        let dst =
          match dst with
          | None -> Vec.last_exn internal_stack
          | Some dst ->
            let dst = location dst in
            Vec.push internal_stack dst;
            dst
        in
        let event =
          Event.Ok.Data.Trace { kind = Some Return; src; dst; trace_state_change = None }
        in
        add_event callstacks event !time
      in
      callstacks, call, return
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

    let print_callstacks (callstacks : t) =
      Vec.to_list callstacks
      |> List.rev
      |> List.map ~f:(fun callstack -> Frame.For_testing.to_string_list [] callstack.leaf)
      |> concat_horizontal
      |> print_endline;
      (* So that the closing |}] of the [%expect ...] block is on its own line. *)
      print_endline "-"
    ;;

    (* In all of the following examples, assume no tail-call-optimization is performed. *)

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
      let callstacks, call, return = setup_test () in
      call "fn1";
      call "fn2";
      (* Return from [fn2] *)
      return ();
      call "fn3";
      (* Return from [fn3] *)
      return ();
      (* Return from [fn1] *)
      return ();
      print_callstacks callstacks;
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
      let callstacks, call, return = setup_test () in
      call "fn1";
      call "fn2";
      (* Return from [fn2] *)
      return ();
      call "fn3";
      (* Return from [fn3] *)
      return ();
      (* Return from [fn1] *)
      return ();
      print_callstacks callstacks;
      [%expect
        {|
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}];
      (* Return from [main] to [start] *)
      return ~dst:"start" ();
      print_callstacks callstacks;
      [%expect
        {|
        start               start               start               start               start               start               start
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3
        - |}];
      (* Return from [start] to [init] *)
      return ~dst:"init" ();
      print_callstacks callstacks;
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
      let callstacks, call, return = setup_test () in
      call "fn1";
      call "fn2";
      (* Return from [fn2] *)
      return ();
      call "fn3";
      (* Raise from [fn3] into the [try] in [main] *)
      return ~dst:"main" ();
      print_callstacks callstacks;
      [%expect
        {|
      main                main                main                main                main
      fn1                 fn1                 fn1                 fn1
                          fn2                                     fn3
      - |}]
    ;;
  end)
;;
