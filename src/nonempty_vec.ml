open! Core

type 'a t = 'a Vec.t

let create x =
  let t = Vec.create () in
  Vec.push_back t x;
  t
;;

let first t = Vec.unsafe_get t 0
let last t = Vec.unsafe_get t ((Vec.length t) - 1)
let push_back = Vec.push_back
let iter = Vec.iter
