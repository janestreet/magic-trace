open! Core
open! Async

let pt_file dir = dir ^/ "auxdata.bin"
let sb_file dir = dir ^/ "sideband.bin"
let setup_file dir = dir ^/ "setup.sexp"

type record_opts = unit

let record_param = Command.Param.return ()

type recording =
  { state : Manual_perf.Tracing_state.t
  ; mutable snapshot_taken : bool
  }

let attach_and_record () ~record_dir ?filter pid =
  let res =
    let setup_file = setup_file record_dir in
    let pt_file = pt_file record_dir in
    let sideband_file = sb_file record_dir in
    let%map.Or_error state =
      Manual_perf.Tracing_state.attach ?filter ~pt_file ~sideband_file ~setup_file pid
    in
    { state; snapshot_taken = false }
  in
  Deferred.return res
;;

let take_snapshot t =
  match t.snapshot_taken with
  | true -> Ok ()
  | false ->
    t.snapshot_taken <- true;
    Manual_perf.Tracing_state.take_snapshot t.state
;;

let finish_recording' t =
  Manual_perf.Tracing_state.destroy t.state;
  Or_error.return ()
;;

let finish_recording t = Deferred.return (finish_recording' t)

type decode_opts = unit

let decode_param = Command.Param.return ()

let rec fill_with_items n q decoder =
  if n = 0
  then ()
  else (
    match Decoding.decode_one decoder with
    | Some item ->
      Queue.enqueue q item;
      fill_with_items (n - 1) q decoder
    | None -> ())
;;

let decode_events () ~record_dir =
  (* Adapt the decoder to a pipe by pushing things in batches to avoid going through the
     async scheduler on every event. *)
  let batch_size = 100 in
  let rec decode_into decoder writer =
    let q = Queue.create ~capacity:batch_size () in
    fill_with_items batch_size q decoder;
    match Queue.is_empty q with
    | true ->
      Pipe.close writer;
      Deferred.unit
    | false ->
      let%bind () = Pipe.transfer_in writer ~from:q in
      decode_into decoder writer
  in
  let reader, writer = Pipe.create ~size_budget:batch_size () in
  let decoder =
    Decoding.create
      ~pt_file:(pt_file record_dir)
      ~sideband_file:(sb_file record_dir)
      ~setup_file:(setup_file record_dir)
  in
  don't_wait_for (decode_into decoder writer);
  Deferred.Or_error.return reader
;;
