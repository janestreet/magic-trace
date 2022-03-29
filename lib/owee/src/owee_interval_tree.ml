(* interval tree for Int64.t intervals, intended usage is to build the tree once
   then query it many times

   reference:

   @book{ CompGeomThirdEdSpringer,
   title     = "Computational Geometry: Algorithms and Applications",
   author    = "M. {de Berg} and O. Cheong and M. {van Kreveld} and
   M. Overmars",
   edition   = "Third Edition",
   pages     = {223--224},
   doi       = "10.1007/978-3-540-77974-2",
   year      = "2008",
   publisher = "Springer"
   } *)

module Interval : sig
  (* since bounds are read-only, we don't care about leaving them public *)
  type 'a t = { lbound : Int64.t ;
                rbound : Int64.t ;
                value  : 'a    }
  val create : Int64.t -> Int64.t -> 'a -> 'a t
  val of_triplet : Int64.t * Int64.t * 'a -> 'a t
  val to_triplet : 'a t -> Int64.t * Int64.t * 'a
end = struct
  type 'a t = { lbound : Int64.t ;
                rbound : Int64.t ;
                value  : 'a    }
  let create lbound rbound value =
    assert (lbound <= rbound);
    { lbound ; rbound ; value }
  let of_triplet (l, r, v) =
    create l r v
  let to_triplet itv =
    (itv.lbound, itv.rbound, itv.value)
end

module A   = Array
module Itv = Interval
module L   = List

open Itv

type 'a interval_tree =
  | Empty
  | Node of
      (* x_mid left_list       right_list      left_tree          right_tree *)
      Int64.t *  'a Itv.t list * 'a Itv.t list * 'a interval_tree * 'a interval_tree

type 'a t = 'a interval_tree

(* -------------------- utility functions -------------------- *)

let leftmost_bound_first i1 i2 =
  compare i1.lbound i2.lbound

let rightmost_bound_first i1 i2 =
  compare i2.rbound i1.rbound

let is_before interval x_mid =
  interval.rbound < x_mid

let contains interval x_mid =
  (interval.lbound <= x_mid) && (x_mid <= interval.rbound)

let bounds_array_of_intervals intervals =
  let n   = L.length intervals  in
  let res = A.make (2 * n) 0L   in
  let i   = ref 0               in
  L.iter
    (fun interval ->
      res.(!i) <- interval.lbound; incr i;
      res.(!i) <- interval.rbound; incr i)
    intervals;
  res

let median xs =
  A.sort compare xs;
  let n = A.length xs in
  if n mod 2 = 1 then
    xs.(n/2)
  else
    Int64.div (Int64.add xs.(n/2) xs.(n/2 - 1)) 2L

let median intervals =
  let bounds = bounds_array_of_intervals intervals in
  median bounds

let partition intervals x_mid =
  let left_intervals, maybe_right_intervals =
    L.partition
      (fun interval -> is_before interval x_mid)
      intervals in
  let mid_intervals, right_intervals =
    L.partition
      (fun interval -> contains interval x_mid)
      maybe_right_intervals in
  left_intervals, mid_intervals, right_intervals

(* -------------------- construction -------------------- *)

(* interval tree of a list of intervals
   WARNING: NOT TAIL REC. *)
let rec create = function
  | [] -> Empty
  | intervals ->
    let x_mid            = median intervals                 in
    let left, mid, right = partition intervals x_mid        in
    let left_list        = L.sort leftmost_bound_first  mid in
    let right_list       = L.sort rightmost_bound_first mid in
    Node (x_mid,
          left_list, right_list,
          create left, create right)

(* interval tree of a list of interval bounds pairs and values
   [(lb1, rb1, v1); (lb2, rb2, v2); ...]
   WARNING: NOT TAIL REC. *)
let of_triplets triplets =
  create
    (L.fold_left
       (fun acc (l, r, v) -> (Itv.create l r v) :: acc)
       []
       triplets)

(* -------------------- query -------------------- *)

(* fold_left f on l while p is true *)
let rec fold_while f p acc = function
  | [] -> acc
  | x :: xs ->
    if p x then
      fold_while f p (f x :: acc) xs
    else
      acc

let filter_left_list l qx acc =
  fold_while
    (fun x -> x)
    (fun interval -> interval.lbound <= qx)
    acc l

let filter_right_list l qx acc =
  fold_while
    (fun x -> x)
    (fun interval -> interval.rbound >= qx)
    acc l

(* find all intervals that contain qx *)
let query initial_tree qx =
  let rec query_priv acc = function
    | Empty -> acc
    | Node (x_mid, left_list, right_list, left_tree, right_tree) ->
      if qx < x_mid then
        let new_acc = filter_left_list  left_list  qx acc in
        query_priv new_acc left_tree
      else
        let new_acc = filter_right_list right_list qx acc in
        query_priv new_acc right_tree
  in
  query_priv [] initial_tree

(* iter on all intervals, traversal order is not specified *)
let rec iter tree ~f =
  match tree with
  | Empty -> ()
  | Node (_, left_list, right_list, left_tree, right_tree) ->
    List.iter f left_list;
    iter left_tree ~f;
    List.iter f right_list;
    iter right_tree ~f
