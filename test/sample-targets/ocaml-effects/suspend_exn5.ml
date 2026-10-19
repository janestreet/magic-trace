type _ Effect.t += Suspend : unit Effect.t

let main () =
  let cont : (unit, unit) Effect.Deep.continuation option ref = ref None in
  let effc (type a) (e : a Effect.t) =
    match e with
    | Suspend -> Some (fun (k : (a, unit) Effect.Deep.continuation) -> cont := Some k)
    | _ -> None
  in
  let handler =
    { Effect.Deep.retc = Fun.id
    ; exnc =
        (fun exn ->
          print_endline "exnc";
          raise exn)
    ; effc
    }
  in
  Effect.Deep.match_with
    (fun () ->
      Effect.Deep.match_with (fun () -> Effect.perform Suspend) () handler;
      Effect.perform Suspend;
      failwith "Failure")
    ()
    handler;
  try Effect.Deep.continue (Option.get !cont) () with
  | Failure fail -> print_endline fail
;;

let () = main ()
