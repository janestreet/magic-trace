open! Core

type ('a : value mod non_float) t =
  #{ len : int
   ; pos : int
   ; data : 'a iarray
   }

let empty = #{ len = 0; pos = 0; data = [::] }

let create ~pos ~len data =
  assert (pos >= 0 && len >= 0 && pos + len <= Iarray.length data);
  #{ len; pos; data }
;;

let[@inline always] length t = t.#len
let[@inline always] unsafe_get t i = Iarray.unsafe_get t.#data (t.#pos + i)

let get t i =
  assert (i >= 0 && i < t.#len);
  unsafe_get t i
;;

let iter t ~f =
  for i = 0 to t.#len - 1 do
    f (unsafe_get t i)
  done
;;

let map_to_list t ~f =
  let list = ref [] in
  for i = 0 to t.#len - 1 do
    list := f (unsafe_get t i) :: !list
  done;
  List.rev !list
;;
