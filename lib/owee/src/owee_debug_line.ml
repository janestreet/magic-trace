open Owee_buf

type header = {
  is_64bit                   : bool;
  total_length               : u64;
  version                    : u16;
  prologue_length            : u32;
  minimum_instruction_length : u8;
  default_is_stmt            : u8;
  line_base                  : u8;
  line_range                 : u8;
  opcode_base                : u8;
  standard_opcode_lengths    : string;
  filenames                  : string array;
}

let read_filename t =
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

let rec skip_directories t =
  match Read.zero_string t () with
  | None -> invalid_format "Unterminated directory list"
  | Some s ->
    match s with
    | "" -> ()
    | _dir ->
      (*print_endline _dir;*)
      skip_directories t

let rec read_filenames acc t = match read_filename t with
  | "" -> Array.of_list (List.rev acc)
  | fname ->
    (*Printf.eprintf "%S\n%!" fname;*)
    read_filenames (fname :: acc) t


let read_header t =
  ensure t 24 ".debug_line header truncated";
  let total_length = Read.u32 t in
  let is_64bit     = total_length = 0xFFFF_FFFF in
  let total_length =
    if is_64bit then Read.u64 t else Int64.of_int (total_length) in
  let chunk = sub t (Int64.to_int total_length) in
  let version = Read.u16 chunk in
  assert_format (version >= 2 && version <= 4)
    "unknown .debug_line version";
  let prologue_length = Read.u32 chunk in
  ensure chunk prologue_length "prologue length too big";
  let prologue = sub chunk prologue_length in
  let minimum_instruction_length = Read.u8 prologue in
  if version = 4 then begin
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
  skip_directories prologue;
  let filenames = read_filenames [] prologue in
  { is_64bit; total_length; version; prologue_length;
    minimum_instruction_length; default_is_stmt;
    line_base; line_range; opcode_base;
    standard_opcode_lengths; filenames }, chunk

let read_chunk t =
  if at_end t
  then None
  else Some (read_header t)

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
        state.filename <- read_filename section;
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
