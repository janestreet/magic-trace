open! Core

type t = string [@@deriving sexp_of]

let equal = phys_equal
let compare t1 t2 = Int.compare (Obj.magic t1) (Obj.magic t2)
let hash t = Int.hash (Obj.magic t)
let hash_fold_t hash_state t = Int.hash_fold_t hash_state (Obj.magic t)
let cache = String.Hash_set.create ()
let intern t = Hash_set.get_or_add cache t

let t_of_sexp = function
  | Sexp.Atom string -> intern string
  | _ -> assert false
;;

let of_string = intern
let to_string t = t
let uuid = "6c0bf9f4-3378-11f1-ae24-c84bd6ab9c33"
let caller_identity = Bin_prot.Shape.Uuid.of_string uuid

include functor Binable.Of_stringable_with_uuid
