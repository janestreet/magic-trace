(** The Jane Street internal implementation of this module includes functionality to host
    a Perfetto UI from the tool, which relies on some internal infrastructure. *)

open! Core
open! Async

module Serve = struct
  type t = unit

  let param =
    let%map_open.Command () = return () in
    ()
  ;;

  let serve_file _t ~path:_ =
    failwith "Serving a Perfetto UI is a Jane Street internal feature."
  ;;
end

type t = { store_path : string }

let param =
  let%map_open.Command store_path =
    flag "output" (required string) ~doc:"FILE output file name"
  in
  { store_path }
;;

let write_and_view ?num_temp_strs { store_path } ~default_name:_ ~f =
  let open Deferred.Or_error.Let_syntax in
  let w = Tracing_zero.Writer.create_for_file ?num_temp_strs ~filename:store_path () in
  let%map res = f w in
  Core.eprintf "Visit https://ui.perfetto.dev/ and open %s to view trace.\n%!" store_path;
  res
;;
