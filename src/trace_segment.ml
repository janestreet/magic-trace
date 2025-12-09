open! Core
module Location = Event.Location

(* Renaming this purely to avoid confusion between "callstack" and "data-structure I am
   using to maintain multiple elements" *)
module Vec = Stack

module Frame = struct
  type t =
    | None
    | Some of
        { location : Location.t
        ; mutable parent : t (** [parent] may only be mutated from [None] to [Some _]. *)
        }
  [@@deriving sexp_of]

  let rec to_symbol_list acc t =
    match t with
    | None -> acc
    | Some { location = { symbol; _ }; parent } ->
      to_symbol_list (Symbol.display_name symbol :: acc) parent
  ;;
end

module Callstack = struct
  type t =
    { time : Time_ns.Span.t
    ; mutable deepest_frame : Frame.t
    (** [deepest_frame] may only be mutated from [None] to [Some _]. This is the same
        invariant as on [Frame.parent], but since we can't express "pointer to a record
        field" in OCaml, we can't easily unify these concepts. *)
    }
  [@@deriving sexp_of]

  let rec top = function
    | Frame.None -> Frame.None
    | Some { parent = None; _ } as frame -> frame
    | Some { parent; _ } -> top parent
  ;;

  let top t = top t.deepest_frame
end

let rec find_matching_frame (target : Symbol.t) (frame : Frame.t) : Frame.t =
  match frame with
  | None -> None
  | Some { location = { symbol; _ }; parent = _ } when Symbol.equal symbol target -> frame
  | Some { parent = None; location = _ } -> None
  | Some { parent; location = _ } -> find_matching_frame target parent
;;

let handle_call (stacks_at_times : Callstack.t Vec.t) time ~(src : Location.t) ~dst =
  let matching_frame : Frame.t =
    match Vec.top stacks_at_times with
    | None -> None
    | Some { time = _; deepest_frame } -> find_matching_frame src.symbol deepest_frame
  in
  let deepest_frame =
    match matching_frame with
    | None ->
      Frame.Some { location = dst; parent = Some { location = src; parent = None } }
    | matching_frame -> Frame.Some { location = dst; parent = matching_frame }
  in
  Vec.push stacks_at_times { time; deepest_frame }
;;

let handle_ret (stacks_at_times : Callstack.t Vec.t) time ~(dst : Location.t) =
  let matching_frame : Frame.t =
    match Vec.top stacks_at_times with
    | None -> None
    | Some { time = _; deepest_frame } -> find_matching_frame dst.symbol deepest_frame
  in
  let deepest_frame =
    match matching_frame with
    | None ->
      (* We have returned into something we never saw the call for. This can happen if
         there is a sequence of calls like [fn1 -> fn2 -> fn3] and we started tracing
         during the execution of [fn2]. When we return from [fn2] to [fn1], we need to
         amend the callstacks we have recorded so far to reflect that [fn1] is the
         top-most frame for all of them. *)
      let frame = Frame.Some { location = dst; parent = None } in
      Vec.iter stacks_at_times ~f:(fun callstack ->
        match Callstack.top callstack with
        | None -> callstack.deepest_frame <- frame
        | Some top_frame as top_frame' when not (phys_equal top_frame' frame) ->
          top_frame.parent <- frame
        | Some _ -> ());
      frame
    | Some matching_frame -> Some { matching_frame with location = dst }
  in
  Vec.push stacks_at_times { time; deepest_frame }
;;

let add_event' stacks_at_times (event : Event.Ok.Data.t) time =
  match event with
  | Trace { kind = Some Call; src; dst; trace_state_change = _ } ->
    handle_call stacks_at_times time ~src ~dst
  | Trace { kind = Some Return; dst; src = _; trace_state_change = _ } ->
    handle_ret stacks_at_times time ~dst
  (* This is just a proof-of-concept at the moment *)
  | Trace _
  | Event.Ok.Data.Power _
  | Event.Ok.Data.Stacktrace_sample _
  | Event.Ok.Data.Event_sample _ -> failwith "Unimplemented"
;;

type t = Callstack.t Vec.t Hashtbl.M(Event.Thread).t

let _add_event (t : t) (event : Event.Ok.t) =
  let stacks_at_times = Hashtbl.find_or_add t event.thread ~default:Vec.create in
  add_event' stacks_at_times event.data event.time
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
            ; src = Stack.top_exn internal_stack
            ; dst = new_location
            ; trace_state_change = None
            }
        in
        Stack.push internal_stack new_location;
        add_event' callstacks event !time
      in
      let return ?dst () =
        incr_time ();
        let src = Stack.pop_exn internal_stack in
        let event =
          Event.Ok.Data.Trace
            { kind = Some Return
            ; src
            ; dst =
                (match dst with
                 | Some dst -> location dst
                 | None -> Stack.top_exn internal_stack)
            ; trace_state_change = None
            }
        in
        add_event' callstacks event !time
      in
      callstacks, call, return
    ;;

    let join_strings (lists : string list list) : string =
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

    let print_callstacks (callstacks : Callstack.t Vec.t) =
      Vec.to_list callstacks
      |> List.map ~f:(fun callstack -> Frame.to_symbol_list [] callstack.deepest_frame)
      |> List.rev
      |> join_strings
      |> print_endline
    ;;

    (*=
       Assume no tail-call-optimization is performed:

       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()
    *)
    let%expect_test "Sanity-check [add_event']" =
      let callstacks, call, return = setup_test () in
      call "fn1";
      call "fn2";
      return ();
      call "fn3";
      return ();
      return ();
      print_callstacks callstacks;
      [%expect
        {|
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3 |}]
    ;;

    (*=
       Assume no tail-call-optimization is performed, and we started tracing during the execution of [main],
       so we never saw the call to [start]:

       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()

       let start () = main ()
    *)
    let%expect_test "A return to a function we never saw the call for" =
      let callstacks, call, return = setup_test () in
      call "fn1";
      call "fn2";
      return ();
      call "fn3";
      return ();
      return ();
      return ~dst:"start" ();
      print_callstacks callstacks;
      [%expect
        {|
        start               start               start               start               start               start               start
        main                main                main                main                main                main
        fn1                 fn1                 fn1                 fn1                 fn1
                            fn2                                     fn3 |}]
    ;;
  end)
;;
