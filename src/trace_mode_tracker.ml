open! Core
open! Import

module Reaction = struct
  type t =
    | Believe
    | Disbelieve
  [@@deriving sexp_of]
end

type state =
  | Tracing
  | Not_tracing
[@@deriving sexp_of]

type t =
  { mutable events_seen : int
  ; mutable state : state
  }
[@@deriving sexp_of]

let create () = { events_seen = 0; state = Tracing }
let event_seen t = t.events_seen <- t.events_seen + 1

let tr_strt t : Reaction.t =
  event_seen t;
  let first_event = t.events_seen = 1 in
  if first_event
  then Believe
  else (
    match t.state with
    | Tracing -> Disbelieve
    | Not_tracing ->
      t.state <- Tracing;
      Believe)
;;

let tr_end t : Reaction.t =
  event_seen t;
  match t.state with
  | Tracing ->
    t.state <- Not_tracing;
    Believe
  | Not_tracing -> Disbelieve
;;

let any_other_event = event_seen

let process_trace_state_change t (change : Event.Trace_state_change.t option) =
  let reaction =
    match change with
    | Some Start -> tr_strt t
    | Some End -> tr_end t
    | None ->
      any_other_event t;
      Believe
  in
  match reaction with
  | Believe -> change
  | Disbelieve -> None
;;

let%test_module _ =
  (module struct
    let p r = print_s ([%sexp_of: Reaction.t] r)

    let%expect_test "believable flow" =
      let t = create () in
      p (tr_strt t);
      [%expect "Believe"];
      p (tr_end t);
      [%expect "Believe"];
      p (tr_strt t);
      [%expect "Believe"];
      p (tr_end t);
      [%expect "Believe"]
    ;;

    let%expect_test "what are you smoking" =
      let t = create () in
      any_other_event t;
      p (tr_strt t);
      [%expect "Disbelieve"];
      p (tr_strt t);
      [%expect "Disbelieve"];
      p (tr_end t);
      [%expect "Believe"];
      p (tr_end t);
      [%expect "Disbelieve"];
      p (tr_strt t);
      [%expect "Believe"];
      p (tr_strt t);
      [%expect "Disbelieve"]
    ;;
  end)
;;
