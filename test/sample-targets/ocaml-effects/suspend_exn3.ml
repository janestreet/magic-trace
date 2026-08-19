type _ Effect.t += Suspend : unit Effect.t

let main () =
  let effc (type a) (e : a Effect.t) =
    match e with
    | Suspend ->
      Some (fun (k : (a, unit) Effect.Deep.continuation) -> Effect.Deep.continue k ())
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
  try
    Effect.Deep.match_with
      (fun () ->
        Effect.perform Suspend;
        failwith "Failure")
      ()
      handler
  with
  | Failure fail -> print_endline fail
;;

let () = main ()
