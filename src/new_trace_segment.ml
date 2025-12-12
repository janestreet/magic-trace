[@@@disable_unused_warnings]

open! Core
module Location = Event.Location

module Frame : sig
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  val root : t -> t
  val find : t -> Symbol.t -> t Or_null.t
  val create : Location.t -> parent:t Or_null.t -> t
  val create_sentinel : unit -> t
  val replace_sentinel : t -> Location.t -> #(frame:t * new_sentinel:t)
end = struct
  type t =
    { mutable location : Event.Location.t
    ; mutable parent : t Or_null.t
    }

  let rec root = function
    | { parent = Null; _ } as t -> t
    | { parent = This parent; _ } -> root parent
  ;;

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
end

module Callstack = struct
  type t =
    #{ time : Timestamp.t
     ; leaf : Frame.t
     }
end

type t =
  { mutable root : Frame.t
  ; callstacks : Callstack.t Nonempty_vec.t
  }

let create () =
  let root = Frame.create_sentinel () in
  { root
  ; callstacks =
      Nonempty_vec.create (#{ time = Timestamp.zero; leaf = root } : Callstack.t)
  }
;;

let[@inline always] current_frame t = (Nonempty_vec.last t.callstacks).#leaf

let handle_call (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  match Frame.find (current_frame t) src.symbol with
  | This _ as src_frame ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:src_frame }
  | Null ->
    (* I would only expect this to happen if this call is the very first event in this
       trace-segment. *)
    let #(~frame:src_frame, ~new_sentinel) = Frame.replace_sentinel t.root src in
    t.root <- new_sentinel;
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = Frame.create dst ~parent:(This src_frame) }
;;

let handle_return (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  match Frame.find (current_frame t) dst.symbol with
  | This { parent; _ } ->
    Nonempty_vec.push_back t.callstacks #{ time; leaf = Frame.create dst ~parent }
  | Null ->
    (* We have returned into something we never saw the call for. This can happen if there
       is a sequence of calls like [fn1 -> fn2 -> fn3] and we started tracing during the
       execution of [fn2]. *)
    let #(~frame:dst_frame, ~new_sentinel) = Frame.replace_sentinel t.root dst in
    t.root <- new_sentinel;
    Nonempty_vec.push_back t.callstacks #{ time; leaf = dst_frame }
;;

let handle_jump (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
        failwith "Not yet implemented"
;;

let add_event (t : t) (event : Event.Ok.Data.t) (time : Timestamp.t) =
  match event with
  | Trace { kind = Some Call; src; dst; trace_state_change = _ } ->
    handle_call t time ~src ~dst
  | Trace { kind = Some Return; src; dst; trace_state_change = _ } ->
    handle_return t time ~src ~dst
  | _ -> assert false
;;


module%test _ = struct
  (* TODO for Claude: Create tests by adapting the tests at the bottom of
     `trace_segment.ml` to work with the new types defined in this file. *)
end
