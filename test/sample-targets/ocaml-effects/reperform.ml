type _ Effect.t += Yield : unit Effect.t

let main () =
  let outer =
    let effc (type a) (e : a Effect.t) =
      match e with
      | Yield ->
        Some (fun (k : (a, unit) Effect.Deep.continuation) -> Effect.Deep.continue k ())
      | _ -> None
    in
    { Effect.Deep.retc = Fun.id; exnc = raise; effc }
  in
  let inner = { Effect.Deep.retc = Fun.id; exnc = raise; effc = (fun _ -> None) } in
  for _ = 1 to 10 do
    Effect.Deep.match_with
      (fun () ->
        Effect.Deep.match_with
          (fun () ->
            Effect.perform Yield;
            Effect.perform Yield)
          ()
          inner)
      ()
      outer
  done;
  Printf.printf "OK\n%!"
;;

let () = main ()
