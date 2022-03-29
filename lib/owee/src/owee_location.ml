type t

external extract : (_ -> _) -> t =
  "ml_owee_code_pointer" "ml_owee_code_pointer" "noalloc"

let count_rows body ~pointers_to_other_sections =
  let open Owee_debug_line in
  let cursor = Owee_buf.cursor body in
  let count = ref 0 in
  let rec aux () =
    match read_chunk cursor ~pointers_to_other_sections with
    | None -> !count
    | Some line_program ->
      let check _header state address =
        if address <> max_int then
          incr count;
        if state.end_sequence
        then max_int
        else state.address
      in
      let _ : int = fold_rows line_program check max_int in
      aux ()
  in
  aux ()

type 'a map_entry = {
  addr_lo: int;
  addr_hi: int;
  payload: 'a;
}

type location = string * int * int

let store_rows body array ~pointers_to_other_sections =
  let open Owee_debug_line in
  let cursor = Owee_buf.cursor body in
  let index = ref 0 in
  let prev_line = ref 0 in
  let prev_col  = ref 0 in
  let prev_file = ref None in
  let rec aux () =
    match read_chunk cursor ~pointers_to_other_sections with
    | None -> ()
    | Some (header, chunk) ->
      let check _header state address =
        if address <> max_int then
          begin
            array.(!index) <- {
              addr_lo = address;
              addr_hi = state.address;
              payload =
                (match !prev_file with
                 | Some fname -> Some (fname, !prev_line, !prev_col : location)
                 | None -> None);
            };
            incr index
          end;
        prev_file := get_filename header state;
        prev_line := state.line;
        prev_col := state.col;
        if state.end_sequence then
          max_int
        else
          state.address
      in
      let _ : int = fold_rows (header, chunk) check max_int in
      aux ()
  in
  aux ()

let extract_debug_info buffer =
  let _header, sections = Owee_elf.read_elf buffer in
  match Owee_elf.find_section sections ".debug_line" with
  | None -> [||],None
  | Some section ->
    (*Printf.eprintf "Looking for 0x%X\n" t;*)
    let body = Owee_elf.section_body buffer section in
    let pointers_to_other_sections = Owee_elf.debug_line_pointers buffer sections in
    let count = count_rows body ~pointers_to_other_sections in
    let debug_entries = Array.make count
        {addr_lo = max_int; addr_hi = max_int; payload = None} in
    store_rows body debug_entries ~pointers_to_other_sections;
    debug_entries, (Owee_elf.find_section sections ".text")

let memory_map = lazy begin try
    let slots = Hashtbl.create 7 in
    let find_slot pathname =
      try Hashtbl.find slots pathname
      with Not_found ->
        let slot = lazy (
          try pathname |> Owee_buf.map_binary |> extract_debug_info
          with exn ->
            prerr_endline ("Owee: fail to parse binary " ^ pathname ^ ": " ^
                           Printexc.to_string exn);
            ([||],None)
        ) in
        Hashtbl.replace slots pathname slot;
        slot
    in
    let add_entry acc (entry : Owee_linux_maps.entry) =
      if not (Sys.file_exists entry.pathname) then acc
      else
        {
          addr_lo = Int64.to_int entry.address_start;
          addr_hi = Int64.to_int entry.address_end;
          payload = (Int64.to_int entry.offset, find_slot entry.pathname)
        } :: acc
    in
    let entries =
      Owee_linux_maps.scan_self ()
      |> List.fold_left add_entry []
      |> Array.of_list
    in
    Array.sort (fun e1 e2 -> compare e1.addr_lo e2.addr_lo) entries;
    entries
  with exn ->
    prerr_endline ("Owee: fail to parse memory map: " ^
                   Printexc.to_string exn);
    [||]
end


let force_int i : t = Obj.magic (lnot i lxor -1)
let none = force_int 0

let rec bsearch table i j address =
  if i >= j then raise Not_found
  else
    let k = (i + j) / 2 in
    let entry = table.(k) in
    if entry.addr_lo lsr 1 <= address && address < entry.addr_hi lsr 1 then
      entry
    else if address < entry.addr_lo lsr 1 then
      bsearch table i k address
    else
      bsearch table (k + 1) j address

let bsearch table address =
  bsearch table 0 (Array.length table) address

let lookup t =
  if t = none then None
  else if Obj.is_int (Obj.repr t) then
    let t : int = Obj.magic t in
    let lazy memory_map = memory_map in
    match bsearch memory_map t with
    | exception Not_found -> None
    | { payload = (offset, lazy (entries,text_section)); _ } as map_entry ->
      match text_section with
      | None -> None
      | Some text_section ->
        let sec_offset = Int64.(shift_right text_section.sh_offset 1 |> to_int) in
        let sec_addr = Int64.(shift_right text_section.sh_addr 1 |> to_int) in
        let a = t - map_entry.addr_lo lsr 1 + offset lsr 1 + sec_addr - sec_offset in
        match bsearch entries a with
        | exception Not_found -> None
        | dbg_entry -> dbg_entry.payload
  else
    let t = Obj.repr t in
    assert (Obj.tag t = 0);
    assert (Obj.size t = 1);
    assert (Obj.size (Obj.field t 0) = 3);
    Obj.obj t

let locate f = lookup (extract f)

external nearest_symbol : t -> string = "ml_owee_code_pointer_symbol"

let demangled_symbol s =
  let len = String.length s in
  if len <= 4
     || s.[0] <> 'c'
     || s.[1] <> 'a'
     || s.[2] <> 'm'
     || s.[3] <> 'l'
  then s
  else
    let end_of_name = ref len in
    let skip_at_end = function
      | '0'..'9' -> true
      | '_' -> true
      | _ -> false
    in
    while !end_of_name > 4 && skip_at_end s.[!end_of_name - 1] do
      decr end_of_name
    done;
    let buf = Buffer.create len in
    let skip = ref false in
    for i = 4 to !end_of_name - 1 do
      if !skip then
        skip := false
      else if s.[i] = '_'
         && i + 1 < len
         && s.[i + 1] = '_'
      then (Buffer.add_char buf '.'; skip := true)
      else
        Buffer.add_char buf s.[i]
    done;
    if !end_of_name < len then
      (Buffer.add_char buf '/';
       let e = !end_of_name + 1 in
       Buffer.add_substring buf s e (len - e));
    Buffer.contents buf

let nearest_demangled_symbol t =
  demangled_symbol (nearest_symbol t)
