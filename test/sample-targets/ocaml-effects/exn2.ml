let[@inline never] fail () = failwith "Failure"

let main () =
  try
    let effc (type a) (_ : a Effect.t) = None in
    let handler = { Effect.Deep.retc = Fun.id; exnc = raise; effc } in
    Effect.Deep.match_with (fun () -> ()) () handler;
    fail ()
  with
  | Failure fail -> print_endline fail
;;

let () = main ()
