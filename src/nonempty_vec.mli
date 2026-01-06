open! Core

module type Range := sig
  type t =
    #{ start : int
     ; stop : int
     }

  val length : t -> int
end

module type%template [@kind k = (value, value & value & value)] S := sig
  (** A [Vec.t] guaranteed to contain at least one element. *)
  type ('a : k) t

  module Range : Range

  val create : 'a -> 'a t
  val first : 'a t -> 'a
  val get : 'a t -> int -> 'a
  val set : 'a t -> int -> 'a -> unit
  val last : 'a t -> 'a
  val push_back : 'a t -> 'a -> unit
  val iter : 'a t -> f:local_ ('a -> unit) -> unit
  val iter_pairs : 'a t -> f:local_ (#('a * 'a) -> unit) -> unit
  val length : _ t -> int
end

module Value : S [@kind value]
module Valuex3 : S [@kind value & value & value]
