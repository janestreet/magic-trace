open Owee_buf

type header = {
  is_64bit                   : bool;
  total_length               : u64;
  version                    : u16;
  address_size               : u8 option; (* only available in DWARF >= 5 *)
  prologue_length            : u32;
  minimum_instruction_length : u8;
  default_is_stmt            : u8;
  line_base                  : u8;
  line_range                 : u8;
  opcode_base                : u8;
  standard_opcode_lengths    : string;
  filenames                  : string array;
}

type pointers_to_other_sections = {
  debug_line_str : t option;
  debug_str      : t option;
}

let read_filename_version_lt_5 t =
  match Read.zero_string t () with
  | None -> invalid_format "Unterminated filename"
  | Some s ->
    match s with
    | "" -> ""
    | fname ->
      let _dir  = Read.uleb128 t in
      let _time = Read.uleb128 t in
      let _len  = Read.uleb128 t in
      fname

let rec skip_directories_version_lt_5 t =
  match Read.zero_string t () with
  | None -> invalid_format "Unterminated directory list"
  | Some s ->
    match s with
    | "" -> ()
    | _dir ->
      (*print_endline _dir;*)
      skip_directories_version_lt_5 t

let rec read_filename_version_gte_5
    t
    ~pointers_to_other_sections
    ~is_64bit
    ~address_size
  = function
  | `string ->
    (match Read.zero_string t () with
     | None -> invalid_format "Unterminated filename"
     | Some x -> Some x)
  | `indirect ->
    (* I have no idea if this can actually be hit; the spec doesn't explicitly mention
       [indirect] in this context. Let's handle it anyway, just in case. *)
    let form = Owee_form.read t in
    read_filename_version_gte_5
      t
      ~pointers_to_other_sections
      ~is_64bit
      ~address_size
      form
  | (`line_strp | `strp) as form ->
    let buf =
      match form with
      | `line_strp -> pointers_to_other_sections.debug_line_str
      | `strp -> pointers_to_other_sections.debug_str
    in
    (match buf with
    | None -> None
    | Some buf ->
      let offset = if is_64bit then Int64.to_int (Read.u64 t) else Read.u32 t in
      let cursor = cursor buf ~at:offset in
      Read.zero_string cursor ())
  | unknown_form ->
    Owee_form.skip unknown_form t ~is_64bit ~address_size;
    None

let unwrap_address_size_v5_only = function
  | Some address_size -> address_size
  | None ->
    failwith "Expected address size in v5"

let skip_directories_version_gte_5 t ~is_64bit ~address_size =
  let format_count = Read.u8 t in
  let descriptors =
    Array.init format_count (fun _ ->
      let content_type_code : u128 = Read.uleb128 t in
      let form = Owee_form.read t in
      (content_type_code, form))
  in
  let directory_entry_count = Read.uleb128 t in
  for _ = 1 to directory_entry_count do
    Array.iter
    (fun (_, form) -> Owee_form.skip form t ~is_64bit ~address_size)
    descriptors
  done

let skip_directories t ~is_64bit ~version ~address_size =
  if version < 5 then
    skip_directories_version_lt_5 t
  else begin
    let address_size = unwrap_address_size_v5_only address_size in
    skip_directories_version_gte_5 t ~is_64bit ~address_size
  end

let read_filenames_version_lt_5 t =
  let rec loop acc =
    match read_filename_version_lt_5 t with
    | "" -> acc 
    | fname ->
      (*Printf.eprintf "%S\n%!" fname;*)
      loop (fname :: acc)
  in
  loop [] |> List.rev |> Array.of_list

let read_filenames_version_gte_5
    t
    ~pointers_to_other_sections
    ~is_64bit
    ~address_size
  =
  let format_count = Read.u8 t in
  let descriptors =
    Array.init format_count (fun _ ->
      let content_type_code : u128 = Read.uleb128 t in
      let form = Owee_form.read t in
      (content_type_code, form))
  in
  let directory_entry_count = Read.uleb128 t in
  let filenames = ref [] in
  for _ = 1 to directory_entry_count do
    Array.iter
      (fun (content_type_code, form) ->
        if content_type_code = 0x01 (* DW_LNCT_path *) then begin
          match
            read_filename_version_gte_5
              t
              ~pointers_to_other_sections
              ~is_64bit
              ~address_size
              form
          with
          | None -> ()
          | Some filename ->
            (*Printf.eprintf "%S\n%!" filename;*)
            filenames := filename :: !filenames
        end else
          Owee_form.skip form t ~is_64bit ~address_size
      )
      descriptors
  done;
  !filenames |> List.rev |> Array.of_list

(* Returns the list in the other direction. *)
let read_filenames
    t
    ~pointers_to_other_sections
    ~version
    ~is_64bit
    ~address_size
  =
  if version < 5 then
    read_filenames_version_lt_5 t
  else begin
    let address_size = unwrap_address_size_v5_only address_size in
    read_filenames_version_gte_5
      t
      ~pointers_to_other_sections 
      ~is_64bit
      ~address_size
  end

let read_prologue_length t ~is_64bit =
  if is_64bit then Int64.to_int (Read.u64 t) else Read.u32 t

let read_header t ~pointers_to_other_sections =
  ensure t 24 ".debug_line header truncated";
  let total_length = Read.u32 t in
  let is_64bit     = total_length = 0xFFFF_FFFF in
  let total_length =
    if is_64bit then Read.u64 t else Int64.of_int total_length
  in
  let chunk = sub t (Int64.to_int total_length) in
  let version = Read.u16 chunk in
  assert_format (version >= 2 && version <= 5)
    "unknown .debug_line version";
  let address_size, segment_selector_size =
    if version >= 5 then begin
      let address_size          = Read.u8 chunk in
      let segment_selector_size = Read.u8 chunk in
      (Some address_size, Some segment_selector_size)
    end
    else None, None
  in
  ignore (segment_selector_size : u8 option);
  let prologue_length = read_prologue_length chunk ~is_64bit in
  ensure chunk prologue_length "prologue_length too big";
  let prologue = sub chunk prologue_length in
  let minimum_instruction_length = Read.u8 prologue in
  if version >= 4 then begin
    let max_ops_per_instruction = Read.u8 prologue in
    assert_format (max_ops_per_instruction = 1)
      "VLIW not supported"
  end;
  let default_is_stmt = Read.u8 prologue in
  let line_base       = Read.s8 prologue in
  let line_range      = Read.u8 prologue in
  let opcode_base     = Read.u8 prologue in
  assert_format (opcode_base > 0)
    "invalid opcode_base";
  let standard_opcode_lengths = Read.fixed_string prologue (opcode_base - 1) in
  skip_directories prologue ~is_64bit ~version ~address_size;
  let filenames =
    read_filenames
      prologue
      ~pointers_to_other_sections
      ~is_64bit
      ~version
      ~address_size
  in
  let header =
    { is_64bit; total_length; version;
      address_size; prologue_length; minimum_instruction_length;
      default_is_stmt; line_base; line_range; opcode_base;
      standard_opcode_lengths; filenames }
  in
  (header, chunk)

let read_chunk t ~pointers_to_other_sections =
  if at_end t
  then None
  else Some (read_header t ~pointers_to_other_sections)

type state = {
  mutable address        : int;
  mutable filename       : string;
  mutable file           : int;
  mutable line           : int;
  mutable col            : int;
  mutable is_statement   : bool;
  mutable basic_block    : bool;
  mutable end_sequence   : bool;
  mutable prologue_end   : bool;
  mutable epilogue_begin : bool;
  mutable isa            : int;
  mutable discriminator  : int;
}

let initial_state header = {
  address        = 0;
  filename       = "";
  file           = 1;
  line           = 1;
  col            = 0;
  is_statement   = header.default_is_stmt <> 0;
  basic_block    = false;
  end_sequence   = false;
  prologue_end   = false;
  epilogue_begin = false;
  isa            = 0;
  discriminator  = 0;
}

let reset_state state header =
  state.address        <- 0;
  state.filename       <- "";
  state.file           <- 1;
  state.line           <- 1;
  state.col            <- 0;
  state.is_statement   <- header.default_is_stmt <> 0;
  state.basic_block    <- false;
  state.end_sequence   <- false;
  state.prologue_end   <- false;
  state.epilogue_begin <- false;
  state.isa            <- 0;
  state.discriminator  <- 0

let get_filename header {file; filename; _} =
  if file <= 0 then
    None
  else if file <= Array.length header.filenames then
    Some header.filenames.(file - 1)
  else
    Some filename

let flush_row header state f acc =
  let acc = f header state acc in
  state.basic_block <- false;
  state.prologue_end <- false;
  state.epilogue_begin <- false;
  state.discriminator <- 0;
  acc

let step header section state f acc =
  if state.line < 0 then prerr_endline "NEGLINE";
  match Read.u8 section with
  (*| n when (Printf.eprintf "opcode:%d\n%!" n; false) -> assert false*)

  | 1 (*DW_LNS_copy *) ->
    flush_row header state f acc;

  | 2 (*DW_LNS_advance_pc *) ->
    state.address <- state.address +
                     (Read.uleb128 section) * header.minimum_instruction_length;
    acc

  | 3 (*DW_LNS_advance_line *) ->
    state.line <- state.line + Read.sleb128 section;
    acc

  | 4 (*DW_LNS_set_file *) ->
    state.file <- Read.uleb128 section;
    acc

  | 5 (*DW_LNS_set_column *) ->
    state.col <- Read.uleb128 section;
    acc

  | 6 (*DW_LNS_negate_stmt *) ->
    state.is_statement <- not state.is_statement;
    acc

  | 7 (*DW_LNS_set_basic_block *) ->
    state.basic_block <- true;
    acc

  | 8 (*DW_LNS_const_add_pc *) ->
    state.address <- state.address +
                     header.minimum_instruction_length *
                     ((255 - header.opcode_base) / header.line_range);
    acc

  | 9 (*DW_LNS_fixed_advance_pc*) ->
    state.address <- state.address + Read.u16 section;
    acc

  | 10 (*DW_LNS_set_prologue_end*) when header.version > 2 ->
    state.prologue_end <- true;
    acc

  | 11 (*DW_LNS_set_epilogue_begin*) when header.version > 2 ->
    state.epilogue_begin <- true;
    acc

  | 12 (*DW_LNS_set_isa*) when header.version > 2 ->
    state.isa <- Read.uleb128 section;
    acc

  | 0 (*DW_LNS_extended_op*) ->
    let insn_len = Read.uleb128 section in
    assert_format (insn_len <> 0) "invalid extended opcode length";
    begin match Read.u8 section with
      (*| n when (Printf.eprintf "eopcode:%d\n%!" n; false) -> assert false*)
      | 1 (* DW_LNE_end_sequence *) ->
        state.end_sequence <- true;
        let acc = flush_row header state f acc in
        reset_state state header;
        acc
      | 2 (* DW_LNE_set_address *) ->
        (* FIXME: target dependent *)
        state.address <- Int64.to_int (Read.u64 section);
        acc
      | 3 (* DW_LNE_define_file *) ->
        (* DW_LNE_define_file was deprecated in DWARF 5. *)
        assert (header.version < 5);
        state.filename <- read_filename_version_lt_5 section;
        acc
      | 4 (* DW_LNE_set_discriminator *) ->
        state.discriminator <- Read.uleb128 section;
        acc
      | _ -> (* Unsupported opcode *)
        advance section (insn_len - 1);
        acc
    end

  | opcode when opcode >= header.opcode_base (* Special opcode *) ->
    let opcode = opcode - header.opcode_base in
    let addr_adv = opcode / header.line_range in
    let line_adv = opcode mod header.line_range in
    let step = addr_adv * header.minimum_instruction_length in
    state.address <- state.address + step;
    state.line    <- state.line    + line_adv + header.line_base;
    flush_row header state f acc

  | opcode -> (* Unrecognised opcode *)
    let count = Char.code header.standard_opcode_lengths.[opcode - 1] in
    for _i = 0 to count - 1 do
      ignore (Read.uleb128 section : u128)
    done;
    acc

let rec fold_rows header section state f acc =
  if at_end section then
    acc
  else
    fold_rows header section state f
      (step header section state f acc)

let fold_rows (header,section) f acc =
  fold_rows header section (initial_state header) f acc

let copy state =
  { address = state.address;
    filename = state.filename;
    file = state.file;
    line = state.line;
    col = state.col;
    is_statement = state.is_statement;
    basic_block = state.basic_block;
    end_sequence = state.end_sequence;
    prologue_end = state.prologue_end;
    epilogue_begin = state.epilogue_begin;
    isa = state.isa;
    discriminator = state.discriminator;
  }
