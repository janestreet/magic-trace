open! Core
include Elf_intf

type t =
  { symbol : Owee_elf.Symbol_table.t
  ; string : Owee_elf.String_table.t
  ; all_elf : Owee_buf.t
  ; sections : Owee_elf.section array
  ; debug : Owee_buf.t option
  ; ocaml_exception_info : Ocaml_exception_info.t option
  ; base_offset : int
  ; filename : string
  ; statically_mappable : bool
  }

let ocaml_exception_info t = t.ocaml_exception_info

(** Elf files tend to have a "base offset" between where their sections end up in memory
    and where they are in the file, this function figures out that offset. *)
let find_base_offset sections =
  (* iterate sections and find offset of first non-zero address *)
  Array.find_map sections ~f:(fun (section : Owee_elf.section) ->
    if Int64.(section.sh_addr = 0L)
    then None
    else Some Int64.(section.sh_addr - section.sh_offset))
;;

let is_non_pie_executable (header : Owee_elf.header) =
  match header.e_type with
  | 2 (* ET_EXEC 2 Executable file *) -> true
  | 3 (* ET_DYN 3 Shared object file *) -> false
  | _e_type -> false
;;

let find_ocaml_exception_info buffer sections =
  let read_note cursor ~actual_base =
    let descsz =
      Owee_elf_notes.read_desc_size ~expected_owner:"OCaml" ~expected_type:1 cursor
    in
    if descsz < 8 * 4
    then Owee_buf.invalid_format (Printf.sprintf "Too small size of note %d\n" descsz);
    let recorded_base = Owee_buf.Read.u64 cursor in
    let rec read_address_list acc =
      let addr = Owee_buf.Read.u64 cursor in
      if Int64.equal addr 0L
      then acc
      else (
        let addr = Owee_elf_notes.Stapsdt.adjust addr ~actual_base ~recorded_base in
        read_address_list (addr :: acc))
    in
    (* Order of field initializers matters!! Keep in sync with [Emit.mlp]. *)
    let entertraps = read_address_list [] in
    let pushtraps = read_address_list [] in
    let poptraps = read_address_list [] in
    entertraps, pushtraps, poptraps
  in
  try
    let ocaml_eh = Owee_elf_notes.find_notes_section sections ".note.ocaml_eh" in
    match Owee_elf_notes.Stapsdt.find_base_address sections with
    | None ->
      Core.eprint_s [%message "Found .note.ocaml_eh but not .stapsdt.base"];
      None
    | Some actual_base ->
      let rec read_all cursor ~entertraps ~pushtraps ~poptraps =
        if Owee_buf.at_end cursor
        then (
          let combine traps = Array.of_list (List.concat traps) in
          combine entertraps, combine pushtraps, combine poptraps)
        else (
          let entertraps', pushtraps', poptraps' = read_note cursor ~actual_base in
          read_all
            cursor
            ~entertraps:(entertraps' :: entertraps)
            ~pushtraps:(pushtraps' :: pushtraps)
            ~poptraps:(poptraps' :: poptraps))
      in
      let body = Owee_elf.section_body buffer ocaml_eh in
      let cursor = Owee_buf.cursor body in
      let entertraps, pushtraps, poptraps =
        read_all cursor ~entertraps:[] ~pushtraps:[] ~poptraps:[]
      in
      Some (Ocaml_exception_info.create ~pushtraps ~poptraps ~entertraps)
  with
  | Owee_elf_notes.Section_not_found _ -> None
;;

let create filename =
  try
    let buffer = Owee_buf.map_binary filename in
    let header, sections = Owee_elf.read_elf buffer in
    let string = Owee_elf.find_string_table buffer sections in
    let symbol = Owee_elf.find_symbol_table buffer sections in
    match string, symbol with
    | Some string, Some symbol ->
      let base_offset =
        find_base_offset sections |> Option.value ~default:0L |> Int64.to_int_exn
      in
      let statically_mappable = is_non_pie_executable header in
      let debug =
        Owee_elf.find_section_body buffer sections ~section_name:".debug_line"
      in
      let ocaml_exception_info = find_ocaml_exception_info buffer sections in
      Some
        { string
        ; symbol
        ; debug
        ; all_elf = buffer
        ; sections
        ; base_offset
        ; filename
        ; statically_mappable
        ; ocaml_exception_info
        }
    | _, _ -> None
  with
  | _ -> None
;;

let is_func sym =
  match Owee_elf.Symbol_table.Symbol.type_attribute sym with
  | Func -> true
  | _ -> false
;;

let matching_functions t symbol_re =
  let res = ref String.Map.empty in
  Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
    match Owee_elf.Symbol_table.Symbol.name symbol t.string with
    | Some name when is_func symbol && Re.execp symbol_re name ->
      (* Duplicate symbols are possible if a symbol is in both the dynamic and static
         symbol tables. *)
      (match Map.add !res ~key:name ~data:symbol with
       | `Ok a -> res := a
       | `Duplicate -> ())
    | _ -> ());
  !res
;;

let traverse_debug_line ~f t =
  Option.iter t.debug ~f:(fun body ->
    let cursor = Owee_buf.cursor body in
    let pointers_to_other_sections = Owee_elf.debug_line_pointers t.all_elf t.sections in
    let rec load_table_next () =
      match Owee_debug_line.read_chunk cursor ~pointers_to_other_sections with
      | None -> ()
      | Some (header, chunk) ->
        let process header (state : Owee_debug_line.state) () =
          if not state.end_sequence then f header state
        in
        Owee_debug_line.fold_rows (header, chunk) process ();
        load_table_next ()
    in
    load_table_next ())
;;

let find_symbol t name =
  let some_name = Some name in
  with_return (fun return ->
    Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
      if is_func symbol
         && [%compare.equal: string option]
              (Owee_elf.Symbol_table.Symbol.name symbol t.string)
              some_name
      then return.return (Some symbol));
    None)
;;

let find_selection t name : Selection.t option =
  let maybe_int_of_string str = Option.try_with (fun () -> Int.of_string str) in
  let find_line_selection name =
    let desired_filename, desired_line, desired_col =
      match String.split name ~on:':' with
      | [ desired_filename; desired_line; desired_col ] ->
        ( Some desired_filename
        , maybe_int_of_string desired_line
        , maybe_int_of_string desired_col )
      | [ desired_filename; desired_line ] ->
        Some desired_filename, maybe_int_of_string desired_line, None
      | _ -> None, None, None
    in
    let%bind.Option desired_filename = desired_filename in
    let%bind.Option desired_line = desired_line in
    let cols = ref [] in
    traverse_debug_line
      ~f:(fun header state ->
        let filename = Owee_debug_line.get_filename header state in
        let line = state.line in
        let col = state.col in
        match filename with
        | Some filename ->
          if String.(desired_filename = filename) && desired_line = line
          then cols := (col, state.address) :: !cols
        | None -> ())
      t;
    let cols =
      List.sort !cols ~compare:(fun (col1, _) (col2, _) -> Int.compare col1 col2)
    in
    match cols with
    | [] -> None
    | (col, address) :: _ ->
      (match desired_col with
       | None ->
         if List.length cols > 1
         then
           Core.eprintf
             "Multiple snapshot symbols on same line. Selecting column %d with address \
              0x%x.\n"
             col
             address;
         Some (Selection.Address { address; name })
       | Some desired_col ->
         (match
            List.find_map cols ~f:(fun (col, _) ->
              if col = desired_col then Some address else None)
          with
          | None -> None
          | Some address -> Some (Selection.Address { address; name })))
  in
  let find_addr_selection addr =
    Option.bind
      (Option.try_with (fun () ->
         let addr =
           if not (String.is_prefix ~prefix:"0x" addr) then "0x" ^ addr else addr
         in
         Int.Hex.of_string addr))
      ~f:(fun address -> Some (Selection.Address { address; name }))
  in
  let find_symbol_selection name =
    Option.map (find_symbol t name) ~f:(fun symbol -> Selection.Symbol symbol)
  in
  let prefix_and_functions =
    [ "symbol:", find_symbol_selection
    ; "line:", find_line_selection
    ; "addr:", find_addr_selection
    ]
  in
  match
    List.find_map prefix_and_functions ~f:(fun (prefix, f) ->
      match String.is_prefix name ~prefix with
      | true -> f (String.drop_prefix name (String.length prefix))
      | false -> None)
  with
  | Some _ as result -> result
  | None -> List.find_map prefix_and_functions ~f:(fun ((_prefix : string), f) -> f name)
;;

let all_symbols ?(select = `File_or_func) t =
  let res = String.Table.create () in
  Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
    let should_add =
      match select, Owee_elf.Symbol_table.Symbol.type_attribute symbol with
      | `File_or_func, File | `File_or_func, Func -> true
      | `File, File | `Func, Func -> true
      | _, _ -> false
    in
    if should_add
    then (
      match Owee_elf.Symbol_table.Symbol.name symbol t.string with
      | None -> ()
      | Some name ->
        (* Duplicate symbols are possible if a symbol is in both the dynamic and static
           symbol tables. *)
        (match Hashtbl.add res ~key:name ~data:symbol with
         | `Ok | `Duplicate -> ())));
  String.Table.to_alist res
;;

let all_file_selections t symbol =
  let locations = ref [] in
  let desired_filename = Owee_elf.Symbol_table.Symbol.name symbol t.string in
  traverse_debug_line
    ~f:(fun header state ->
      let filename = Owee_debug_line.get_filename header state in
      match filename, desired_filename with
      | Some filename, Some desired_filename ->
        if String.(filename = desired_filename)
        then (
          let name = [%string "%{filename}:%{state.line#Int}:%{state.col#Int}"] in
          let closest_symbol =
            Owee_elf.Symbol_table.symbols_enclosing_address
              t.symbol
              ~address:(Int64.of_int state.address)
            |> List.hd
          in
          let closest_symbol_name =
            Option.bind closest_symbol ~f:(fun closest_symbol ->
              Owee_elf.Symbol_table.Symbol.name closest_symbol t.string)
          in
          let show_name =
            match closest_symbol_name with
            | None -> name
            | Some closest_symbol_name -> [%string "%{name} %{closest_symbol_name}"]
          in
          let selection = Selection.Address { address = state.address; name } in
          locations := (show_name, selection) :: !locations)
      | None, _ | _, None -> ())
    t;
  !locations
;;

let selection_stop_info t pid selection =
  let filename = Filename_unix.realpath t.filename in
  let compute_addr addr =
    if t.statically_mappable
    then addr
    else
      Owee_linux_maps.scan_pid (Pid.to_int pid)
      |> List.filter_map ~f:(fun { address_start; address_end; pathname; offset; _ } ->
        let open Int64 in
        let length = address_end - address_start in
        if String.(pathname = filename) && addr >= offset && addr < offset + length
        then Some (addr - offset + address_start)
        else None)
      |> List.hd_exn
  in
  let compute_filter ~name ~addr ~size =
    let offset = Int64.( - ) addr (Int64.of_int t.base_offset) in
    let filter = [%string {|stop %{offset#Int64}/%{size#Int64}@%{filename}|}] in
    { Stop_info.name; addr; filter }
  in
  match selection with
  | Selection.Symbol symbol ->
    let name = Owee_elf.Symbol_table.Symbol.name symbol t.string in
    let name = Option.value_exn ~message:"stop_info symbols must have a name" name in
    let addr = Owee_elf.Symbol_table.Symbol.value symbol in
    let addr = compute_addr addr in
    let size = Owee_elf.Symbol_table.Symbol.size_in_bytes symbol in
    compute_filter ~name ~addr ~size
  | Address { address; name } ->
    let addr = compute_addr (Int64.of_int address) in
    compute_filter ~name ~addr ~size:1L
;;

let addr_table t =
  let table = Int.Table.create () in
  let symbol_starts = Int.Hash_set.create () in
  Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
    if is_func symbol
    then
      Hash_set.add
        symbol_starts
        (Owee_elf.Symbol_table.Symbol.value symbol |> Int64.to_int_exn));
  traverse_debug_line
    ~f:(fun header state ->
      if Hash_set.mem symbol_starts state.address
      then
        Hashtbl.set
          table
          ~key:state.address
          ~data:
            { Location.filename = Owee_debug_line.get_filename header state
            ; line = state.line
            ; col = state.col
            })
    t;
  table
;;

module Symbol_resolver = struct
  type nonrec t =
    { elf : t
    ; file_offset : int
    ; loaded_offset : int
    }

  type resolved =
    { name : string
    ; start_addr : int
    ; end_addr : int
    }

  let resolve (t : t) addr =
    let open Option.Let_syntax in
    let normal_offset = t.file_offset + t.elf.base_offset in
    let original_addr = addr - t.loaded_offset + normal_offset in
    let%bind symb =
      Owee_elf.Symbol_table.symbols_enclosing_address
        t.elf.symbol
        ~address:(Int64.of_int original_addr)
      |> List.last
    in
    let name, start_addr, size =
      Owee_elf.Symbol_table.Symbol.(
        ( name symb t.elf.string
        , (value symb |> Int64.to_int_exn) - normal_offset + t.loaded_offset
        , size_in_bytes symb |> Int64.to_int_exn ))
    in
    let%bind name = name in
    return { name; start_addr; end_addr = start_addr + size }
  ;;
end
