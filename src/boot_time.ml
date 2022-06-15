open! Core

external clock_gettime_perf_ns : unit -> int = "magic_clock_gettime_perf_ns"

let time_ns_of_boot_in_perf_time () =
  let perf_ns =
    try clock_gettime_perf_ns () with
    | _ ->
      (* CR-soon tbrindus: this raises in CI, and [am_running_inline_test] and
         [am_running_test] don't seem to be set within @runtest. *)
      0
  in
  let realtime_ns = Time_ns.to_int_ns_since_epoch (Time_ns.now ()) in
  Time_ns.sub
    (Time_ns.of_int63_ns_since_epoch (Int63.of_int realtime_ns))
    (Time_ns.Span.of_int_ns perf_ns)
;;
