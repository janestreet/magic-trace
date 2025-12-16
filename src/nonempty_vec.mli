open! Core

[%%template:
[@@@kind k = (value & value & value)]

(** A [Vec.t] guaranteed to contain at least one element. *)
type ('a : k) t

val create : 'a -> 'a t
val first : 'a t  -> 'a
val last : 'a t  -> 'a
val push_back : 'a t -> 'a -> unit
val iter : 'a t -> f:local_ ('a -> unit) -> unit
val iter_pairs : 'a t -> f:local_ (#('a * 'a) -> unit) -> unit
]
