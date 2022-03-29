type 'result service = ..

type _ service +=
   | Name : string service
   | Traverse : ((Obj.t -> 'acc -> 'acc) -> 'acc -> 'acc) service
   | Locate : Owee_location.t list service

type 'a service_result =
  | Success of 'a
  | Unsupported_service
  | Unmanaged_object

let magic_potion = Obj.repr (ref ())

type 'a marker = {
  magic_potion: Obj.t;
  service: 'result. 'a -> 'result service -> 'result service_result;
}
let size_marker = 2

type 'a cycle_marker = {
  magic_potion: Obj.t;
  original: 'a marker;
  unique_id: int;
  mutable users: int;
}
let size_cycle_marker = 4

let unique_ids = ref 0

let fresh_name () =
  incr unique_ids;
  !unique_ids

let make_cycle_marker (marker : _ marker) = {
  magic_potion;
  original = marker;
  unique_id = fresh_name ();
  users = 0
}

let is_marker obj =
  if Obj.tag obj = 0 && Obj.size obj >= 2 && Obj.field obj 0 == magic_potion then
    if Obj.size obj = size_marker then `Marker
    else if Obj.size obj = size_cycle_marker then `Cycle_marker
    else `No
  else `No

let find_marker t =
  let rec aux (obj : 'a) i j =
    if i >= j then `No else
      let obj' = Obj.field (Obj.repr obj) i in
      match is_marker obj' with
      | `Marker -> `Marker (i, (Obj.obj obj' : 'a marker))
      | `Cycle_marker -> `Cycle_marker (i, (Obj.obj obj' : 'a cycle_marker))
      | `No -> aux obj (i + 1) j
  in
  let obj = Obj.repr t in
  if Obj.tag obj < Obj.lazy_tag
  then aux t 0 (Obj.size obj)
  else `No

let query_service t service =
  match find_marker t with
  | `No -> Unmanaged_object
  | `Marker (_,marker) | `Cycle_marker (_,{original = marker; _}) ->
    marker.service t service

module type T0 = sig
  type t
  val service : t -> 'result service -> 'result service_result
end

module Unsafe0 (M : T0) : sig
  val marker : M.t marker
end = struct
  let marker = M.({ magic_potion; service })
end

type 'a marked = {
  cell: 'a;
  marker: 'a marked marker;
}

let make_marked cell marker = {cell; marker}

let get t = t.cell

module Safe0 (M : T0) : sig
  val mark : M.t -> M.t marked
end = struct
  include Unsafe0(struct
      type t = M.t marked
      let service obj (type a) (request : a service) : a service_result =
        M.service obj.cell request
    end)
  let mark cell = make_marked cell marker
end

(******)

module type T1 = sig
  type 'x t
  val service : 'x t -> 'result service -> 'result service_result
end

module Unsafe1 (M : T1) : sig
  val marker : 'x M.t marker
end = struct
  let marker = M.({ magic_potion; service })
end

module Safe1 (M : T1) : sig
  val mark : 'a M.t -> 'a M.t marked
end = struct
  include Unsafe1(struct
      type 'a t = 'a M.t marked
      let service obj (type a) (request : a service) : a service_result =
        M.service obj.cell request
    end)
  let mark cell = make_marked cell marker
end

module type T2 = sig
  type ('x, 'y) t
  val service : ('x, 'y) t -> 'result service -> 'result service_result
end

module Unsafe2 (M : T2) : sig
  val marker : ('x, 'y) M.t marker
end = struct
  let marker = M.({ magic_potion; service })
end

module Safe2 (M : T2) : sig
  val mark : ('a, 'b) M.t -> ('a, 'b) M.t marked
end = struct
  include Unsafe2(struct
      type ('a, 'b) t = ('a, 'b) M.t marked
      let service obj (type a) (request : a service) : a service_result =
        M.service obj.cell request
    end)
  let mark cell = make_marked cell marker
end

module type T3 = sig
  type ('x, 'y, 'z) t
  val service : ('x, 'y, 'z) t -> 'result service -> 'result service_result
end

module Unsafe3 (M : T3) : sig
  val marker : ('x, 'y, 'z) M.t marker
end = struct
  let marker = M.({ magic_potion; service })
end

module Safe3 (M : T3) : sig
  val mark : ('a, 'b, 'c) M.t -> ('a, 'b, 'c) M.t marked
end = struct
  include Unsafe3(struct
      type ('a, 'b, 'c) t = ('a, 'b, 'c) M.t marked
      let service obj (type a) (request : a service) : a service_result =
        M.service obj.cell request
    end)
  let mark cell = make_marked cell marker
end

(* Cycle detection *)

type cycle = {
  (* FIXME: someday, find better than an hashtable, or maybe just drop cycle
            detection to some library like Phystable? *)
  seen_ids: (int, unit) Hashtbl.t;
  (* Cause uncessary retention, switch to weak array?*)
  mutable seen_objs: Obj.t list;
}

let seen cycle obj =
  match find_marker obj with
  | `No -> `Unmanaged
  | `Marker _ -> `Not_seen
  | `Cycle_marker (_,marker) ->
    if Hashtbl.mem cycle.seen_ids marker.unique_id then
      `Seen marker.unique_id
    else
      `Not_seen

let add_to_cycle cycle (obj : 'a) (marker : 'a cycle_marker) =
  marker.users <- marker.users + 1;
  Hashtbl.add cycle.seen_ids marker.unique_id ();
  cycle.seen_objs <- Obj.repr obj :: cycle.seen_objs;
  `Now_seen marker.unique_id

let update_marker (obj : 'a) (field : int) (marker : 'a marker) =
  Obj.set_field (Obj.repr obj) field (Obj.repr marker)

let update_cycle_marker (obj : 'a) (field : int) (marker : 'a cycle_marker) =
  Obj.set_field (Obj.repr obj) field (Obj.repr marker)

let mark_seen cycle obj =
  match find_marker obj with
  | `No -> `Unmanaged
  | `Marker (i,marker) ->
    let marker = make_cycle_marker marker in
    update_cycle_marker obj i marker;
    add_to_cycle cycle obj marker
  | `Cycle_marker (_,marker) ->
    if Hashtbl.mem cycle.seen_ids marker.unique_id then
      `Already_seen marker.unique_id
    else
      add_to_cycle cycle obj marker

let unmark_seen obj =
  match find_marker obj with
  | `Cycle_marker (i,marker) ->
    marker.users <- marker.users - 1;
    if marker.users = 0 then
      update_marker obj i marker.original
  | `Marker _ ->
    prerr_endline "UNEXPECTED MARKER";
    assert false
  | `No ->
    prerr_endline "UNEXPECTED UNMANAGED";
    assert false

let end_cycle cycle =
  Hashtbl.reset cycle.seen_ids;
  let seen_objs = cycle.seen_objs in
  cycle.seen_objs <- [];
  List.iter unmark_seen seen_objs

let start_cycle () =
  let cycle = { seen_ids = Hashtbl.create 7; seen_objs = [] } in
  Gc.finalise end_cycle cycle;
  cycle
