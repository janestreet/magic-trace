open! Core
open! Async
open! Import

module Symbol_hit = struct
  module Kind = struct
    type t =
      | Start
      | Stop
    [@@deriving sexp_of]
  end

  type t =
    { kind : Kind.t
    ; symbol : Symbol.t
    ; time : Time_ns.Span.t
    }
  [@@deriving sexp_of]
end

let range_hit_times ~decode_events ~range_symbols =
  let open Deferred.Or_error.Let_syntax in
  let%bind { Decode_result.events; _ } = decode_events () in
  Deferred.List.map events ~how:`Sequential ~f:(fun events ->
    let { Trace_filter.start_symbol; stop_symbol } = range_symbols in
    let is_start symbol = String.(Symbol.display_name symbol = start_symbol) in
    let is_stop symbol = String.(Symbol.display_name symbol = stop_symbol) in
    Pipe.filter_map events ~f:(function
      | Error _ | Ok { data = Power _; _ } | Ok { data = Event_sample _; _ } -> None
      | Ok { data = Trace trace; time; _ } ->
        (match trace.kind with
         | Some Call ->
           let symbol = trace.dst.symbol in
           if is_start symbol
           then Some { Symbol_hit.kind = Start; symbol; time }
           else if is_stop symbol
           then Some { Symbol_hit.kind = Stop; symbol; time }
           else None
         | _ -> None)
      | Ok { data = Stacktrace_sample { callstack }; time; _ } ->
        List.rev callstack
        |> List.fold ~init:None ~f:(fun acc call ->
          match acc, call with
          | None, { symbol; _ } when is_start symbol ->
            Some { Symbol_hit.kind = Start; symbol; time }
          | None, { symbol; _ } when is_stop symbol ->
            Some { Symbol_hit.kind = Stop; symbol; time }
          | acc, _ -> acc))
    |> Pipe.to_list)
  |> Deferred.map ~f:Or_error.return
;;

let remove_unmatched_hits (hits : Symbol_hit.t list) =
  let rec remove_unmatched_hits' ~accum hits =
    match hits with
    | [] -> accum
    | [ { Symbol_hit.kind = Start; _ } ] -> accum
    | [ { Symbol_hit.kind = Stop; _ } ] -> accum
    | first :: second :: rest ->
      (match first.kind, second.kind with
       | _, Start -> remove_unmatched_hits' ~accum (second :: rest)
       | Stop, Stop -> remove_unmatched_hits' ~accum rest
       | Start, Stop -> remove_unmatched_hits' ~accum:(second :: first :: accum) rest)
  in
  remove_unmatched_hits' ~accum:[] hits |> List.rev
;;

(* Calls provided [decode_event] and marks events if they should be written (are
   in-between a start and stop symbol). If there are multiple calls to
   [range_start_symbol] at the same time, they will all be marked [should_write = true]. *)
let decode_events_and_annotate ~decode_events ~range_symbols =
  let open Deferred.Or_error.Let_syntax in
  let%bind { Decode_result.events; close_result } = decode_events ()
  and range_hit_times = range_hit_times ~decode_events ~range_symbols in
  let hit_sequences = List.map range_hit_times ~f:remove_unmatched_hits in
  let events =
    List.zip_exn events hit_sequences
    |> List.map ~f:(fun (events, hit_sequence) ->
      Pipe.folding_map
        events
        ~init:(hit_sequence, false)
        ~f:(fun (hits, in_filtered_region) event ->
          let hits, in_filtered_region =
            match hits with
            | [] -> hits, in_filtered_region
            | hd :: tl ->
              (match event with
               | Ok { data = Trace { kind = Some Call; dst; _ }; time; _ }
                 when Time_ns_unix.Span.(time = hd.time)
                      && Symbol.equal dst.symbol hd.symbol -> tl, not in_filtered_region
               | Ok { data = Stacktrace_sample _; time; _ }
                 when Time_ns_unix.Span.(time = hd.time) -> tl, not in_filtered_region
               | Ok { data = Trace _; _ }
               | Ok { data = Power _; _ }
               | Ok { data = Stacktrace_sample _; _ }
               | Ok { data = Event_sample _; _ }
               | Error _ -> hits, in_filtered_region)
          in
          ( (hits, in_filtered_region)
          , Event.With_write_info.create ~should_write:in_filtered_region event )))
  in
  return (events, close_result)
;;
