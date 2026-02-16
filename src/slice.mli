open! Core

type (+'a : value mod non_float) t : immediate & immediate & value

val empty : 'a t
val create : ('a : value mod non_float). pos:int -> len:int -> 'a iarray -> 'a t
val length : ('a : value mod non_float). 'a t -> int
val unsafe_get : ('a : value mod non_float). 'a t -> int -> 'a
val get : ('a : value mod non_float). 'a t -> int -> 'a
val iter : ('a : value mod non_float). 'a t -> f:('a -> unit) @ local -> unit
val map_to_list : ('a : value mod non_float). 'a t -> f:('a -> 'b) @ local -> 'b list
