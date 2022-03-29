let f () = ()

let () =
  match Owee_location.locate f with
  | None -> print_endline "No location for f"
  | Some (filename, line, column) ->
    Printf.printf "f is defined in %s, line %d, column %d\n" filename line column
