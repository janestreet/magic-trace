open! Core

type buffered_step =
  { thread : Tracing_zero.Writer.Thread_id.t
  ; ticks : int
  ; is_first_step : bool
  }

type t =
  { flow_id : int
  ; mutable buffer : buffered_step option
  }

let create ~flow_id = { flow_id; buffer = None }

let write_step t w ~thread ~ticks =
  let is_first_step =
    match t.buffer with
    | None -> true
    | Some { thread; ticks; is_first_step = true } ->
      Tracing_zero.Writer.write_flow_begin w ~thread ~ticks ~flow_id:t.flow_id;
      false
    | Some { thread; ticks; is_first_step = false } ->
      Tracing_zero.Writer.write_flow_step w ~thread ~ticks ~flow_id:t.flow_id;
      false
  in
  t.buffer <- Some { thread; ticks; is_first_step }
;;

let finish t w =
  match t.buffer with
  | None -> ()
  | Some { is_first_step = true; _ } -> ()
  | Some { thread; ticks; is_first_step = false } ->
    Tracing_zero.Writer.write_flow_end w ~thread ~ticks ~flow_id:t.flow_id;
    t.buffer <- None
;;
