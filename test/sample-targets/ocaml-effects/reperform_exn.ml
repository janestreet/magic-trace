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
  Effect.Deep.match_with
    (fun () ->
      try
        Effect.Deep.match_with
          (fun () ->
            Effect.perform Yield;
            failwith "Failure")
          ()
          inner
      with
      | Failure _ -> ())
    ()
    outer
;;

let () = main ()
