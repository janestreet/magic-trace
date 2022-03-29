open! Core
include Elf_intf

type t =
  { symbol : Owee_elf.Symbol_table.t
  ; string : Owee_elf.String_table.t
  ; debug : Owee_buf.t option
  ; base_offset : int
  ; filename : string
  ; statically_mappable : bool
  }

let filename t = t.filename

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

let create filename =
  try
    let buf = Owee_buf.map_binary filename in
    let header, sections = Owee_elf.read_elf buf in
    let string = Owee_elf.find_string_table buf sections in
    let symbol = Owee_elf.find_symbol_table buf sections in
    match string, symbol with
    | Some string, Some symbol ->
      let base_offset =
        find_base_offset sections |> Option.value ~default:0L |> Int64.to_int_exn
      in
      let statically_mappable = is_non_pie_executable header in
      let debug = Owee_elf.find_section_body buf sections ~section_name:".debug_line" in
      Some { string; symbol; debug; base_offset; filename; statically_mappable }
    | _, _ -> None
  with
  | Owee_buf.Invalid_format _ ->
    Core.eprintf "Invalid or unknown debug info format.\n";
    None
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

let all_symbols t =
  let res = String.Table.create () in
  Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
      if is_func symbol
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

let symbol_stop_info t pid symbol =
  let name = Owee_elf.Symbol_table.Symbol.name symbol t.string in
  let name = Option.value_exn ~message:"stop_info symbols must have a name" name in
  let filename = Filename_unix.realpath t.filename in
  let addr = Owee_elf.Symbol_table.Symbol.value symbol in
  let addr =
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
  let size = Owee_elf.Symbol_table.Symbol.size_in_bytes symbol in
  let offset = Int64.( - ) addr (Int64.of_int t.base_offset) in
  let filter = [%string {|stop %{offset#Int64}/%{size#Int64}@%{filename}|}] in
  { Stop_info.name; addr; filter }
;;

let addr_table t =
  let table = Int.Table.create () in
  Option.iter t.debug ~f:(fun body ->
      (* We only want to include line info from the start address of symbols in the table,
       lest it grow too large on big executables. We don't need to include mappings for
       lines in the middle of functions. *)
      let symbol_starts = Int.Hash_set.create () in
      Owee_elf.Symbol_table.iter t.symbol ~f:(fun symbol ->
          if is_func symbol
          then
            Hash_set.add
              symbol_starts
              (Owee_elf.Symbol_table.Symbol.value symbol |> Int64.to_int_exn));
      let cursor = Owee_buf.cursor body in
      let rec load_table_next () =
        match Owee_debug_line.read_chunk cursor with
        | None -> ()
        | Some (header, chunk) ->
          let process header (state : Owee_debug_line.state) () =
            if (not state.end_sequence) && Hash_set.mem symbol_starts state.address
            then
              Hashtbl.set
                table
                ~key:state.address
                ~data:
                  { Location.filename = Owee_debug_line.get_filename header state
                  ; line = state.line
                  ; col = state.col
                  }
          in
          Owee_debug_line.fold_rows (header, chunk) process ();
          load_table_next ()
      in
      load_table_next ());
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
