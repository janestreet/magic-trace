type _ Effect.t += Suspend : unit Effect.t

let main () =
  let effc (type a) (e : a Effect.t) =
    match e with
    | Suspend -> failwith "Failure"
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
  try Effect.Deep.match_with (fun () -> Effect.perform Suspend) () handler with
  | Failure fail -> print_endline fail
;;

let () = main ()
