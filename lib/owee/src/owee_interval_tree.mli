(** Originally from:
    https://github.com/UnixJunkie/interval-tree
    Instead of "Int64.t", we use "Int64.t".
*)

type 'a t

module Interval : sig

  (** An interval has a left bound, a right bound and a payload (called value) *)
  type 'a t = { lbound : Int64.t ;
                rbound : Int64.t ;
                value  : 'a    }

  (** [create lbound rbound value] create a new Int64.t interval
      with an associated value.
      PRECONDITION: [lbound] must be <= [rbound]. *)
  val create : Int64.t -> Int64.t -> 'a -> 'a t

  (** [of_triplet (lbound, rbound, value)] = [create lbound rbound value] *)
  val of_triplet : Int64.t * Int64.t * 'a -> 'a t

  (** [to_triplet itv] = [(lbound, rbound, value)] *)
  val to_triplet : 'a t -> Int64.t * Int64.t * 'a
end

(** {4 Constructors} *)

(** [create intervals_list] : interval tree of all intervals in the list *)
val create : 'a Interval.t list -> 'a t

(** [of_triplets interval_triplets] : interval tree of all intervals
    whose bounds and values are given in a list *)
val of_triplets : (Int64.t * Int64.t * 'a) list -> 'a t

(** {4 Query} *)

(** [query tree q] : list of intervals in the tree [t] containing
    the Int64.t [q] *)
val query : 'a t -> Int64.t -> 'a Interval.t list

(** [iter tree ~f] calls applies [f] to each interval that has been added to
    [tree].  Traversal order is not specified.  *)
val iter : 'a t -> f:('a Interval.t -> unit) -> unit
