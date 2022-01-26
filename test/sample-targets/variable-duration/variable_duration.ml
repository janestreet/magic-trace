(** Program for testing magic-trace with operations that take a variable amount of time
    measured using [mark_start]. *)

open! Core

let[@inline never] do_delay () = ignore (Core_unix.nanosleep 0.000_1 : float)
let min_dur = Magic_trace.Min_duration.of_ns 700_000

let[@inline never] variable_delay n =
  Magic_trace.mark_start ();
  let trailing_ones = Ocaml_intrinsics.Int.count_trailing_zeros (lnot n) in
  let delays = trailing_ones + 1 in
  for _ = 1 to delays do
    do_delay ()
  done;
  if Magic_trace.Min_duration.over min_dur then Magic_trace.take_snapshot_with_arg delays
;;

let () =
  for i = 1 to 10_000 do
    variable_delay i
  done
;;
