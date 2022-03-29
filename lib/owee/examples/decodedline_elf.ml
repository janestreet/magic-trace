(* ./decodedline <mybin>
   output should be similar to
   objdump --dwarf=decodedline <mybin>
*)
let path =
  if Array.length Sys.argv <= 1 then
    (prerr_endline ("Usage: " ^ Sys.argv.(0) ^ " my_binary.elf"); exit 1)
  else
    Sys.argv.(1)

let buffer = Owee_buf.map_binary path

let _header, sections = Owee_elf.read_elf buffer

let () =
  match Owee_elf.find_section sections ".debug_line" with
  | None -> ()
  | Some section ->
    let body = Owee_buf.cursor (Owee_elf.section_body buffer section) in
    let rec aux () =
      match Owee_debug_line.read_chunk body with
      | None -> ()
      | Some (header, chunk) ->
        let check header state () =
          let open Owee_debug_line in
          if not state.end_sequence then
          match get_filename header state with
          | None -> ()
          | Some filename ->
            Printf.printf "%s\t%d\t0x%x\n" filename state.line state.address
        in
        Owee_debug_line.fold_rows (header, chunk) check ();
        aux ()
    in
    aux ()
