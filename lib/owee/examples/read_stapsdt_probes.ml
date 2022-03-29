let () =
  let path =
    if not (Array.length Sys.argv = 2)
    then (
      prerr_endline ("Usage: " ^ Sys.argv.(0) ^ " my_binary.elf");
      exit 1)
    else Sys.argv.(1)
  in
  let buffer = Owee_buf.map_binary path in
  let _header, sections = Owee_elf.read_elf buffer in
  let option_value ~default = function
    | None -> default
    | Some x -> x
  in
  let f (p : Owee_elf_notes.Stapsdt.t) =
    Printf.printf
      "addr=0x%Lx %s %s %s semaphore=0x%Lx\n"
      p.addr
      p.provider
      p.name
      p.args
      (option_value p.semaphore ~default:0L)
  in
  Owee_elf_notes.Stapsdt.iter buffer sections ~f
;;
