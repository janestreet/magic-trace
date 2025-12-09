open! Core

module%template [@kind k = (value, value & value & value)] T = struct
  type ('a : k) t = ('a Vec.t[@kind k])

  let create x =
    let t = (Vec.create [@kind k]) () in
    (Vec.push_back [@kind k]) t x;
    t
  ;;

  let unsafe_get = (Vec.unsafe_get [@kind k])
  let get = (Vec.get [@kind k])
  let set = (Vec.set [@kind k])
  let length = (Vec.length [@kind k])
  let first t = unsafe_get t 0
  let last t = unsafe_get t (length t - 1)
  let push_back = (Vec.push_back [@kind k])
  let iter = (Vec.iter [@kind k])

  let iter_pairs t ~f =
    let mutable prev = first t in
    for i = 1 to length t - 1 do
      let curr = unsafe_get t i in
      f #(prev, curr);
      prev <- curr
    done
  ;;
end

module Value = T [@kind value]
module Valuex3 = T [@kind value & value & value]
