open! Core

type t = int

let page_size = 4096L
let min_byte_units_int = page_size
let min_byte_units = Byte_units.of_bytes_int64_exn min_byte_units_int

(* Virtual address space is only so large. *)
let max_byte_units_int = Int64.( lsl ) 1L 48
let max_byte_units = Byte_units.of_bytes_int64_exn max_byte_units_int
let pp = Byte_units.to_string_hum
let warn message = Core.eprintf "Warning: %s\n%!" message

let create byte_units =
  let bytes = Byte_units.bytes_int64 byte_units in
  if Int64.( < ) bytes min_byte_units_int
  then (
    warn
      [%string
        "Rounding small bytes, %{pp byte_units}, up to the minimum of %{pp \
         min_byte_units}."];
    Int64.(to_int_exn (min_byte_units_int / page_size)))
  else if Int64.( > ) bytes max_byte_units_int
  then (
    warn
      [%string
        "Rounding large bytes, %{pp byte_units}, down to the maximum of %{pp \
         max_byte_units}."];
    Int64.(to_int_exn (max_byte_units_int / page_size)))
  else (
    let num_pages = Int64.( / ) bytes page_size in
    let num_pages_rounded_up =
      let open Int64 in
      if num_pages * page_size <> bytes then num_pages + one else num_pages
    in
    let num_pages_rounded_up_to_pow2_int = Int64.ceil_pow2 num_pages_rounded_up in
    if Int64.(num_pages_rounded_up_to_pow2_int <> num_pages)
    then (
      let num_pages_rounded_up =
        Byte_units.of_bytes_int64_exn Int64.(num_pages_rounded_up_to_pow2_int * page_size)
      in
      warn
        [%string
          "Rounding %{pp byte_units} up to the next power of two number of pages, %{pp \
           num_pages_rounded_up}."]);
    Int64.to_int_exn num_pages_rounded_up_to_pow2_int)
;;

let optional_flag name ~doc =
  let open Command.Param in
  flag name (optional Byte_units.arg_type) ~doc |> map ~f:(Option.map ~f:create)
;;

module Repr = struct
  type t =
    { size : Byte_units.t
    ; pages : int
    }
  [@@deriving sexp_of]
end

let repr t =
  { Repr.size = Int64.(page_size * Int64.of_int t) |> Byte_units.of_bytes_int64_exn
  ; pages = t
  }
;;

let sexp_of_t t = [%sexp_of: Repr.t] (repr t)
let num_pages t = t

let%expect_test "examples" =
  let check s = print_s ([%sexp_of: t] (create (Byte_units.of_string s))) in
  check "8K";
  [%expect "((size 8K) (pages 2))"];
  check "8000B";
  [%expect
    {|
    Warning: Rounding 7.8125K up to the next power of two number of pages, 8K.
    ((size 8K) (pages 2)) |}];
  check "-3K";
  [%expect
    {|
    Warning: Rounding small bytes, -3K, up to the minimum of 4K.
    ((size 4K) (pages 1)) |}];
  check "128B";
  [%expect
    {|
    Warning: Rounding small bytes, 128B, up to the minimum of 4K.
    ((size 4K) (pages 1)) |}];
  check "9K";
  [%expect
    {|
    Warning: Rounding 9K up to the next power of two number of pages, 16K.
    ((size 16K) (pages 4)) |}];
  check "1G";
  [%expect {| ((size 1G) (pages 262144)) |}];
  check "1.1G";
  [%expect
    {|
    Warning: Rounding 1.1G up to the next power of two number of pages, 2G.
    ((size 2G) (pages 524288)) |}];
  check "300T";
  [%expect
    {|
    Warning: Rounding large bytes, 307200G, down to the maximum of 262144G.
    ((size 262144G) (pages 68719476736)) |}]
;;
