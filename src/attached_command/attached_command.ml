open! Core
open! Async

type t =
  { process : Process.t
  ; finished : unit Or_error.t Deferred.t
  }

type outcome =
  | Command_finished of unit Or_error.t
  | Recording_stopped

let create ~prog ~argv =
  (* A separate process group lets us stop the workload and any descendants if the
     recording ends first. [forward_output_and_wait] closes stdin and drains both output
     streams, so this path is intentionally for non-interactive workloads. *)
  let%map.Deferred process =
    Process.create ~setpgid:Core_unix.Pgid.new_process_group ~prog ~args:argv ()
  in
  Or_error.map process ~f:(fun process ->
    let finished = Process.forward_output_and_wait process in
    { process; finished })
;;

let wait_for_outcome ~stop ~finished =
  let%map.Deferred () =
    Deferred.any_unit [ stop; Deferred.map finished ~f:(fun _ -> ()) ]
  in
  (* Prefer the command result if the command and recording finish in the same Async
     cycle. In particular, this prevents a non-zero exit from being hidden by the
     recording stop that the command itself initiates. *)
  match Deferred.peek finished with
  | Some result -> Command_finished result
  | None -> Recording_stopped
;;

let wait t ~stop = wait_for_outcome ~stop ~finished:t.finished

let send_to_process_group t signal =
  Signal_unix.send_i signal (`Group (Process.pid t.process))
;;

let terminate ?(grace_period = Time_ns.Span.of_sec 1.) ?(signal = Signal.term) t =
  send_to_process_group t signal;
  match%bind.Deferred Clock_ns.with_timeout grace_period t.finished with
  | `Result result -> return result
  | `Timeout ->
    send_to_process_group t Signal.kill;
    t.finished
;;

module%test _ = struct
  let%expect_test "command result wins a simultaneous stop" =
    let stop = Ivar.create () in
    let finished = Ivar.create () in
    Ivar.fill_exn stop ();
    Ivar.fill_exn finished (Ok ());
    let%map outcome =
      wait_for_outcome ~stop:(Ivar.read stop) ~finished:(Ivar.read finished)
    in
    (match outcome with
     | Command_finished _ -> print_endline "command finished"
     | Recording_stopped -> print_endline "recording stopped");
    [%expect {| command finished |}]
  ;;

  let%expect_test "recording can stop before the command" =
    let stop = Ivar.create () in
    let finished = Ivar.create () in
    Ivar.fill_exn stop ();
    let%map outcome =
      wait_for_outcome ~stop:(Ivar.read stop) ~finished:(Ivar.read finished)
    in
    (match outcome with
     | Command_finished _ -> print_endline "command finished"
     | Recording_stopped -> print_endline "recording stopped");
    [%expect {| recording stopped |}]
  ;;

  let%expect_test "a non-zero command exit is preserved" =
    let%bind command =
      create
        ~prog:"/bin/sh"
        ~argv:
          [ "-c"
          ; "printf 'argument: %s\\n' \"$1\"; exit 23"
          ; "magic-trace-test"
          ; "with spaces"
          ]
    in
    let command = ok_exn command in
    let%map outcome = wait command ~stop:(Deferred.never ()) in
    (match outcome with
     | Recording_stopped -> print_endline "recording stopped"
     | Command_finished result -> printf "command failed: %b\n" (Or_error.is_error result));
    [%expect {|
      argument: with spaces
      command failed: true |}]
  ;;

  let%expect_test "stopping the recording reaps the command process group" =
    let%bind command =
      create ~prog:"/bin/sh" ~argv:[ "-c"; "trap '' TERM; sleep 60 & wait" ]
    in
    let command = ok_exn command in
    (* Give the shell enough time to install its TERM handler and start the child. *)
    let%bind () = Clock_ns.after (Time_ns.Span.of_ms 50.) in
    let stop = Ivar.create () in
    let outcome = wait command ~stop:(Ivar.read stop) in
    Ivar.fill_exn stop ();
    let%bind outcome in
    (match outcome with
     | Command_finished _ -> print_endline "command finished"
     | Recording_stopped -> print_endline "recording stopped");
    let%bind result = terminate command ~grace_period:(Time_ns.Span.of_ms 10.) in
    let process_group_reaped =
      match Signal_unix.send Signal.zero (`Group (Process.pid command.process)) with
      | `No_such_process -> true
      | `Ok -> false
    in
    printf "process group reaped: %b\n" (Or_error.is_error result && process_group_reaped);
    [%expect {|
      recording stopped
      process group reaped: true |}]
    |> Deferred.return
  ;;
end
