open! Core

module Private = struct
  let stop_symbol = "magic_trace_stop_indicator"
end

external stop_indicator : int -> int -> unit = "magic_trace_stop_indicator" [@@noalloc]

let start_time = ref 0

let[@inline] tsc_int () =
  let tsc = Time_stamp_counter.now () in
  Time_stamp_counter.to_int63 tsc |> Int63.to_int_exn
;;

let mark_start () = start_time := tsc_int ()

module Min_duration = struct
  type t = int

  let of_ns ns =
    Time_stamp_counter.Span.of_ns
      (Int63.of_int ns)
      ~calibrator:(force Time_stamp_counter.calibrator)
    |> Time_stamp_counter.Span.to_int_exn
  ;;

  let over min =
    let span = tsc_int () - !start_time in
    span > min
  ;;
end

let take_snapshot_with_arg i = stop_indicator !start_time i

let take_snapshot_with_time_and_arg tsc i =
  let tsc_i = Time_stamp_counter.to_int63 tsc |> Int63.to_int_exn in
  stop_indicator tsc_i i
;;

let take_snapshot () = take_snapshot_with_arg 0
