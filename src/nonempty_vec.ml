open! Core
[%%template
[@@@kind k = (value & value & value)]

type ('a : k) t = 'a Vec.t [@kind k]

let create x =
  let t = (Vec.create [@kind k]) () in
  (Vec.push_back [@kind k]) t x;
  t
;;

let first t = (Vec.unsafe_get [@kind k]) t 0
let last t = (Vec.unsafe_get [@kind k]) t (((Vec.length [@kind k]) t) - 1)
let push_back = (Vec.push_back [@kind k])
let iter = (Vec.iter [@kind k])
]
