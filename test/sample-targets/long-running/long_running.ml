(** Program for testing magic-trace with threads and long running processes. *)

open! Core

let[@inline never] create_pair n =
  let x = Some n in
  x, n + 1
;;

let[@inline never] my_tiny_fn n =
  match create_pair n with
  | Some n', n'' when n' = n && n'' = n + 1 -> ()
  | _, _ -> failwith "lolwut"
;;

let[@inline never] call_n_times n =
  for _ = 1 to n do
    my_tiny_fn n
  done
;;

(* Can potentially help with debugging, by encoding a number as
   control flow so that it can be read out of the processor trace. *)
let[@inline never] rec number_as_control_flow n =
  match n > 0 with
  | false -> ()
  | true ->
    call_n_times (n % 10);
    number_as_control_flow (n / 10)
;;

type t =
  { limit : int option
  ; num_snaps : int
  ; snap_every : Time_ns.Span.t
  ; last_snap : Time_ns.t
  ; do_snap : bool
  ; sleeps : bool
  }

let[@inline never] rec main_loop t n =
  number_as_control_flow n;
  let calibrator = force Time_stamp_counter.calibrator in
  let now = Time_stamp_counter.now () |> Time_stamp_counter.to_time_ns ~calibrator in
  let next_snap = Time_ns.add t.last_snap t.snap_every in
  match Time_ns.( > ) now next_snap with
  | true ->
    if t.do_snap
    then Magic_trace.take_snapshot_with_time_and_arg (Time_stamp_counter.now ()) n;
    (match t.limit with
     | Some limit when limit >= t.num_snaps -> ()
     | _ -> main_loop { t with last_snap = now; num_snaps = t.num_snaps + 1 } (n + 1))
  | false ->
    if t.sleeps && n % 4000 = 0 then ignore (Core_unix.nanosleep 0.001 : float);
    main_loop t (n + 1)
;;

let command =
  Command.basic
    ~summary:"sample executable for tracing that continually uses CPU"
    (let%map_open.Command limit = flag "-limit" (optional int) ~doc:"snapshot limit"
     and snap_every =
       flag
         "-snap-every"
         (optional_with_default (Time_ns.Span.of_int_ms 1_000) Time_ns_unix.Span.arg_type)
         ~doc:"Call Magic_trace.take_snapshot at this interval"
     and multi_thread = flag "-multi-thread" no_arg ~doc:"Spawn a second thread"
     and sleeps = flag "-sleeps" no_arg ~doc:"Periodically sleep" in
     fun () ->
       let t =
         { limit
         ; snap_every
         ; num_snaps = 0
         ; last_snap = Time_ns.now ()
         ; sleeps
         ; do_snap = true
         }
       in
       let thread =
         match multi_thread with
         | false -> None
         | true ->
           (* Do this before multi-threading to avoid race *)
           let _calibrator = force Time_stamp_counter.calibrator in
           Core_thread.create
             ~on_uncaught_exn:`Kill_whole_process
             (fun () ->
                let t2 = { t with do_snap = false } in
                main_loop t2 0)
             ()
           |> Some
       in
       main_loop t 0;
       Option.iter thread ~f:Core_thread.join)
;;

let () = Command_unix.run command
