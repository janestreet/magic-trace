let main () =
  try
    let effc (type a) (_ : a Effect.t) = None in
    let[@inline never] exnc exn =
      let _ = Sys.opaque_identity () in
      raise exn
    in
    let handler = { Effect.Deep.retc = Fun.id; exnc; effc } in
    Effect.Deep.match_with (fun () -> failwith "Failure") () handler
  with
  | Failure fail -> print_endline fail
;;

let () = main ()
