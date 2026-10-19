type _ Effect.t += Suspend : unit Effect.t

let main () =
  let effc (type a) (e : a Effect.t) =
    match e with
    | Suspend -> Some (fun (_ : (a, unit) Effect.Deep.continuation) -> failwith "Failure")
    | _ -> None
  in
  let handler =
    { Effect.Deep.retc = Fun.id
    ; exnc =
        (fun exn ->
          print_string "exnc";
          raise exn)
    ; effc
    }
  in
  try
    Effect.Deep.match_with
      (fun () ->
        try Effect.perform Suspend with
        | _ -> ())
      ()
      handler
  with
  | Failure fail -> print_endline fail
;;

let () = main ()
