open! Core

type t = { mutable last_output : Time_ns.Span.t }

let create () = { last_output = Time_ns.Span.zero }

let event_start t ~output_time ?input_time () =
  let input_time =
    match input_time with
    (* Use 0-duration slice if no input time *)
    | None -> output_time
    (* We might have queuing, each message has to start after the last finishes *)
    | Some input_time ->
      (* Avoid saying the next event starts at exactly the time of the prior send *)
      let after_last = Time_ns.Span.(t.last_output + of_int_ns 1) in
      (* This defends against multiple events output at the same time but intentionally
         not against input_time>output_time since we want a downstream error for that *)
      Time_ns.Span.max (Time_ns.Span.min after_last output_time) input_time
  in
  t.last_output <- output_time;
  input_time
;;
