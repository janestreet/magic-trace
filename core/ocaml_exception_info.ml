open! Core

module Kind = struct
  type t =
    | Pushtrap
    | Poptrap
  [@@deriving sexp_of]
end

(* CR-someday tbrindus: we can make this faster by using int63s everywhere. We will never
   have OCaml code in kernel-space. *)
type t =
  { pushtrap_and_poptrap_addresses : (int64 * Kind.t) array
  ; entertrap_addresses : Int64.Set.t
  }
[@@deriving sexp_of]

let create ~pushtraps ~poptraps ~entertraps : t =
  let pushtrap_and_poptrap_addresses =
    [ Array.map ~f:(fun addr -> addr, Kind.Pushtrap) pushtraps
    ; Array.map ~f:(fun addr -> addr, Kind.Poptrap) poptraps
    ]
    |> Array.concat
  in
  Array.sort pushtrap_and_poptrap_addresses ~compare:(fun (addr, _) (addr', _) ->
      Int64.compare addr addr');
  { pushtrap_and_poptrap_addresses; entertrap_addresses = Int64.Set.of_array entertraps }
;;

let iter_pushtraps_and_poptraps_in_range =
  let address_get t i =
    let addr, _ = t.(i) in
    addr
  in
  let first_index_greater_than_or_equal_to t x =
    Binary_search.binary_search
      t.pushtrap_and_poptrap_addresses
      ~length:Array.length
      ~get:address_get
      ~compare:Int64.compare
      `First_greater_than_or_equal_to
      x
  in
  let last_index_less_than_or_equal_to t x =
    Binary_search.binary_search
      t.pushtrap_and_poptrap_addresses
      ~length:Array.length
      ~get:address_get
      ~compare:Int64.compare
      `Last_less_than_or_equal_to
      x
  in
  fun ~from:from' ~to_:to_' ~f t ->
    let from = first_index_greater_than_or_equal_to t from' in
    let to_ = last_index_less_than_or_equal_to t to_' in
    match from, to_ with
    | Some from, Some to_ ->
      for i = from to to_ do
        f t.pushtrap_and_poptrap_addresses.(i)
      done
    | _, _ -> ()
;;

let is_entertrap t ~addr = Set.mem t.entertrap_addresses addr

let%test_module _ =
  (module struct
    open Core

    let iter_and_print ~from ~to_ t =
      let range = ref [] in
      iter_pushtraps_and_poptraps_in_range ~from ~to_ ~f:(fun r -> range := r :: !range) t;
      let range = !range |> List.rev in
      Core.print_s
        [%message "" (from : int64) (to_ : int64) (range : (int64 * Kind.t) list)]
    ;;

    let%expect_test "basic range classification tests" =
      let t =
        create ~pushtraps:[| 0L; 5L; 10L |] ~poptraps:[| 2L; 100L |] ~entertraps:[| 50L |]
      in
      iter_and_print ~from:0L ~to_:1L t;
      [%expect {|
          ((from 0) (to_ 1) (range ((0 Pushtrap)))) |}];
      iter_and_print ~from:0L ~to_:4L t;
      [%expect {|
          ((from 0) (to_ 4) (range ((0 Pushtrap) (2 Poptrap)))) |}];
      iter_and_print ~from:3L ~to_:7L t;
      [%expect {|
          ((from 3) (to_ 7) (range ((5 Pushtrap)))) |}];
      iter_and_print ~from:49L ~to_:100L t;
      [%expect {|
          ((from 49) (to_ 100) (range ((100 Poptrap)))) |}];
      iter_and_print ~from:75L ~to_:101L t;
      [%expect {|
          ((from 75) (to_ 101) (range ((100 Poptrap)))) |}];
      iter_and_print ~from:75L ~to_:80L t;
      [%expect {| ((from 75) (to_ 80) (range ())) |}];
      iter_and_print ~from:150L ~to_:200L t;
      [%expect {| ((from 150) (to_ 200) (range ())) |}]
    ;;
  end)
;;
