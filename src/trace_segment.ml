[@@@disable_unused_warnings]

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
        ; mutable parent : t
        }
end

module Callstack = struct
  type t =
    { time : Time_ns.Span.t
    ; mutable deepest_frame : Frame.t
    }

  let rec top' = function
    | Frame.None -> Frame.None
    | Some { parent = None; _ } as frame -> frame
    | frame -> top' frame
  ;;

  let top t = top' t.deepest_frame
end

type t = Callstack.t Vec.t Hashtbl.M(Event.Thread).t

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

let handle_ret
  (stacks_at_times : Callstack.t Vec.t)
  time
  ~(src : Location.t)
  ~(dst : Location.t)
  =
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
        | Some top_frame -> top_frame.parent <- frame);
      frame
    | Some matching_frame -> Some { matching_frame with location = dst }
  in
  Vec.push stacks_at_times { time; deepest_frame }
;;

let add_event' stacks_at_times (event : Event.Ok.Data.t) time =
  match event with
  | Trace { kind = Some Call; src; dst; trace_state_change = _ } ->
    handle_call stacks_at_times time ~src ~dst
  | Trace { kind = Some Return; src; dst; trace_state_change = _ } ->
    handle_ret stacks_at_times time ~src ~dst
  | Trace _
  | Event.Ok.Data.Power _
  | Event.Ok.Data.Stacktrace_sample _
  | Event.Ok.Data.Event_sample _ -> failwith "Unimplemented"
;;

let add_event t (event : Event.Ok.t) =
  let stacks_at_times = Hashtbl.find_or_add t event.thread ~default:Vec.create in
  add_event' stacks_at_times event.data event.time
;;
