(** A module to manually instrument values and implement dynamic services based
    on the actual type of these values.

    The idea is to put a distinguished word, of type [t marker] in a value of type [t].
    This module implements tools to generate and scan for such word, and
    execute functions based on the type recovered.

    Manipulation of markers should be done with care: if the introspection find
    any value with the [t marker] word, it will incorrectly behave as if value
    was of type [t].

    The Safe_ functors ease manipulation of markers, at the cost of wrapping
    values.  Use the Unsafe_ ones if you know what you are doing.
*)

(** {1 Dynamic services}

    Services are typed queries which can be executed on arbitrary ocaml objects.
    The query will succeed if:
    - object has a marker
    - this marker implements the type of service being requested.
*)

(** The extensible type of dynamic services.
    Add your own services to the list and run queries at runtime without
    knowledge of the object type.

    Think of this as an extensible list of methods (and of markers as a vtable
    for those methods).
*)
type 'result service = ..

type _ service +=
   | Name : string service
   (** A user-friendly label for your object / class of objects *)
   | Traverse : ((Obj.t -> 'acc -> 'acc) -> 'acc -> 'acc) service
   (** Run a fold functions on object leafs, useful to traverse structure
       which are partially opaque. *)
   | Locate : Owee_location.t list service
   (** Return a list of locations relevant to the object *)

(** Possible outcomes for the execution of a service *)
type 'a service_result =
  | Success of 'a
  (** Object implements the service, here is your answer *)
  | Unsupported_service
  (** Service is not supported / unknown, but object is marked *)
  | Unmanaged_object
  (** No marker has been found on the object, you can't run any query on it *)

(** {1 Manipulating objects}

    User API to work with marked objects.
*)

(** Type of object marked with the safe interface *)
type 'a marked
val get : 'a marked -> 'a

(** Query an object for a service *)
val query_service : 'a -> 'result service -> 'result service_result

(** {1 Cycle detection}

    User API to work with graph of marked objects.
*)

(** Type storing the state needed of traversal of marked OCaml object graphs *)
type cycle

(** Start a fresh cycle detector *)
val start_cycle : unit -> cycle

(** Release all ressources associated to the cycle.
    The cycle value should not be used after that. *)
val end_cycle : cycle -> unit

(** Mark an object as seen in a cycle.
    An integer uniquely identifying the object in this cycle is returned. *)
val mark_seen : cycle -> Obj.t -> [`Already_seen of int | `Now_seen of int | `Unmanaged]

(** Was the object already seen during this traversal?
    If seen, the integer resulting from the call to [mark_seen] is returned. *)
val seen : cycle -> Obj.t -> [`Seen of int | `Not_seen | `Unmanaged]

(** Generate a fresh name, guaranteed not to collide with results of [mark_seen]. *)
val fresh_name : unit -> int

(** {1 Marking objects}

    Implementor API.  *)

(** The signature that needs to be implemented to add service support to your
    objects. *)
module type T0 = sig
  type t

  (** The service dispatch function.
      Given a value of [type t] and a service, try to satisfy this service. *)
  val service : t -> 'result service -> 'result service_result
end

(** {2 Safe api} *)

module Safe0 (M : T0) : sig
  val mark : M.t -> M.t marked
end

(** {2 Unsafe api} *)

type 'a marker
module Unsafe0 (M : T0) : sig
  (** The marker should only appear as a field of an object of type [M.t].

      type t = {
        ...;
        marker: M.t marker; (* Correct *)
      }

      type t =
        | Normal of ...
        | Marked of ... * M.t marker (* Correct *)

      type t =
        | Normal of ...
        | Marked of (... * M.t marker)
          (* Wrong: marker is part of the tuple, not of the value of type [t] *)

  *)
  val marker : M.t marker
end

(* {1 Generalization to parameterized types} *)

module type T1 = sig
  type 'x t
  val service : 'x t -> 'result service -> 'result service_result
end
module type T2 = sig
  type ('x, 'y) t
  val service : ('x, 'y) t -> 'result service -> 'result service_result
end
module type T3 = sig
  type ('x, 'y, 'z) t
  val service : ('x, 'y, 'z) t -> 'result service -> 'result service_result
end

module Safe1 (M : T1) : sig
  val mark : 'a M.t -> 'a M.t marked
end
module Safe2 (M : T2) : sig
  val mark : ('a, 'b) M.t -> ('a, 'b) M.t marked
end
module Safe3 (M : T3) : sig
  val mark : ('a, 'b, 'c) M.t -> ('a, 'b, 'c) M.t marked
end

module Unsafe1 (M : T1) : sig
  val marker : 'x M.t marker
end
module Unsafe2 (M : T2) : sig
  val marker : ('x, 'y) M.t marker
end
module Unsafe3 (M : T3) : sig
  val marker : ('x, 'y, 'z) M.t marker
end
