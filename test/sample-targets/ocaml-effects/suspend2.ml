type _ Effect.t += Suspend : unit Effect.t

let main () =
  let effc (type a) (e : a Effect.t) =
    match e with
    | Suspend ->
      Some (fun (k : (a, unit) Effect.Deep.continuation) -> Effect.Deep.continue k ())
    | _ -> None
  in
  let handler = { Effect.Deep.retc = Fun.id; exnc = raise; effc } in
  for _ = 1 to 10 do
    Effect.Deep.match_with
      (fun () ->
        Effect.perform Suspend;
        Effect.perform Suspend;
        Effect.perform Suspend)
      ()
      handler
  done;
  Printf.printf "OK\n%!"
;;

let () = main ()
