[@@@alert "-do_not_spawn_domains"]
[@@@alert "-unsafe_multidomain"]

type _ Effect.t += Migrate : unit Effect.t

let rec push stack item =
  let before = Atomic.get stack in
  let after = item :: before in
  if not (Atomic.compare_and_set stack before after) then push stack item
;;

let x = ref 0

let[@inline never] perform0 () =
  x := !x + 1;
  Effect.perform Migrate
;;

let[@inline never] perform1 () =
  x := !x + 1;
  perform0 () [@nontail]
;;

let[@inline never] perform2 () =
  x := !x + 1;
  perform1 () [@nontail]
;;

let[@inline never] perform3 () =
  x := !x + 1;
  perform2 () [@nontail]
;;

let main () =
  let fibers_in = Atomic.make [] in
  let receiving_domain =
    Domain.spawn (fun () ->
      try
        let rec loop = function
          | fiber :: fibers ->
            fiber ();
            loop fibers
          | [] ->
            while Atomic.get fibers_in == [] do
              Domain.cpu_relax ()
            done;
            loop (List.rev (Atomic.exchange fibers_in []))
        in
        loop []
      with
      | Exit -> ())
  in
  let finally () =
    push fibers_in (fun () -> raise Exit);
    Domain.join receiving_domain
  in
  Fun.protect ~finally (fun () ->
    let effc (type a) (e : a Effect.t) =
      match e with
      | Migrate ->
        Some
          (fun (k : (a, unit) Effect.Deep.continuation) ->
            push fibers_in (Effect.Deep.continue k))
      | _ -> None
    in
    let handler = { Effect.Deep.retc = Fun.id; exnc = raise; effc } in
    for _ = 1 to 200 do
      Effect.Deep.match_with
        (fun () -> if Random.bool () then perform3 () else perform1 () [@nontail])
        ()
        handler
    done;
    Printf.printf "OK\n%!")
;;

let () = main ()
