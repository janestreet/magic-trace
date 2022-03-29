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
  let buildid = Owee_elf_notes.read_buildid buffer sections in
  Printf.printf "%s\n" buildid
;;
