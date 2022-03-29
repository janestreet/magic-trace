[@@@ocaml.warning "+a-4-9-30-40-41-42"]

let path, address =
  let argv_len = Array.length Sys.argv in
  if argv_len < 1 || argv_len > 3 then
    (prerr_endline ("Usage: " ^ Sys.argv.(0)
      ^ " my_binary.elf [ADDRESS]"); exit 1)
  else
    let path = Sys.argv.(1) in
    let address =
      if argv_len = 3 then Some (Int64.of_string Sys.argv.(2)) else None
    in
    path, address

let buffer =
  let fd = Unix.openfile path [Unix.O_RDONLY] 0 in
  let len = Unix.lseek fd 0 Unix.SEEK_END in
  let map = Unix.map_file
      fd Bigarray.int8_unsigned Bigarray.c_layout false [|len|]
  in
  Unix.close fd;
  Bigarray.array1_of_genarray map

let _header, sections = Owee_elf.read_elf buffer

let () =
  match Owee_elf.find_symbol_table buffer sections with
  | None -> failwith "Symbol table not found"
  | Some symtab ->
    match Owee_elf.find_string_table buffer sections with
    | None -> failwith "String table not found"
    | Some strtab ->
      let module S = Owee_elf.Symbol_table.Symbol in
      let symbol_name sym =
        match S.name sym strtab with
        | None -> "<none>"
        | Some name -> name
      in
      match address with
      | None ->
        Printf.printf "All symbols:\n";
        Owee_elf.Symbol_table.iter symtab ~f:(fun sym ->
          Printf.printf "%s" (symbol_name sym);
          match S.type_attribute sym with
          | Func -> Printf.printf " (function)\n";
          | _ -> Printf.printf "\n")
      | Some address ->
        Printf.printf "Symbols overlapping address 0x%Lx:\n" address;
        List.iter (fun sym -> Printf.printf "%s\n" (symbol_name sym))
          (Owee_elf.Symbol_table.functions_enclosing_address symtab ~address)
