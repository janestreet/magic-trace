(* Compression algorithm is slightly simplified version of
   external/memtrace/backtrace_codec.ml
   (callstacks and backtraces are essentially the same) *)

open Core
open Import

type t =
  { symbol_to_id : (Symbol.t, int) Hashtbl.t
  ; id_to_symbol : (int, Symbol.t) Hashtbl.t
  ; mutable next_symbol_id : int
  ; follow_table : (int, int) Hashtbl.t
  }

let init () =
  { symbol_to_id = Hashtbl.create (module Symbol)
  ; id_to_symbol = Hashtbl.create (module Int)
  ; next_symbol_id = 0
  ; follow_table = Hashtbl.create (module Int)
  }
;;

type compression_event =
  { new_symbols : (Symbol.t * int) list
  ; callstack : (int * int) list
  }
[@@deriving sexp, bin_io]

let update_follow_table t stack =
  (let%bind.Option suffix = List.tl stack in
   let%map.Option prefix = List.drop_last stack in
   List.iter2_exn prefix suffix ~f:(fun prev next ->
     Hashtbl.set t.follow_table ~key:prev ~data:next))
  |> Option.value ~default:()
;;

let compress_with_follow_table t stack =
  let compressed_stack =
    List.fold stack ~init:[] ~f:(fun acc x ->
      match acc with
      | [] -> [ x, x, 0 ]
      | (from_s, to_s, steps) :: tl ->
        let pred_next = Hashtbl.find t.follow_table to_s in
        (match pred_next with
         | Some a when a = x -> (from_s, x, steps + 1) :: tl
         | _ -> (x, x, 0) :: acc))
    |> List.rev
  in
  List.map compressed_stack ~f:(fun (from_s, _, steps) -> from_s, steps)
;;

let rec follow_symbol_steps t symbol = function
  | 0 -> []
  | steps ->
    let next_symbol = Hashtbl.find_exn t.follow_table symbol in
    next_symbol :: follow_symbol_steps t next_symbol (steps - 1)
;;

let decompress_with_follow_table t comp_stack =
  List.concat_map comp_stack ~f:(fun (from_s, steps) ->
    from_s :: follow_symbol_steps t from_s steps)
;;

let compress_callstack t callstack =
  let symbols = callstack in
  let new_symbol_events =
    List.filter_map symbols ~f:(fun s ->
      match Hashtbl.mem t.symbol_to_id s with
      | true -> None
      | false ->
        Hashtbl.add_exn t.symbol_to_id ~key:s ~data:t.next_symbol_id;
        t.next_symbol_id <- t.next_symbol_id + 1;
        Some (s, t.next_symbol_id - 1))
  in
  let symbol_ids = List.map symbols ~f:(fun s -> Hashtbl.find_exn t.symbol_to_id s) in
  let compressed_stack = compress_with_follow_table t symbol_ids in
  update_follow_table t symbol_ids;
  { new_symbols = new_symbol_events; callstack = compressed_stack }
;;

let decompress_callstack t { new_symbols; callstack } =
  List.iter new_symbols ~f:(fun (symbol, id) ->
    Hashtbl.set t.id_to_symbol ~key:id ~data:symbol);
  let symbol_ids = decompress_with_follow_table t callstack in
  update_follow_table t symbol_ids;
  List.map symbol_ids ~f:(fun s -> Hashtbl.find_exn t.id_to_symbol s)
;;
