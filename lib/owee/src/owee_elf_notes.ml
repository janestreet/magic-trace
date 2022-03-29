type header = {
  owner : string;
  typ : int;  (** each owner defines its own types *)
  size : int;
}

module Read = Owee_buf.Read

(* Align size to 4 bytes as needed for note name and descriptor data. *)
let padding n = (4 - (n land 3)) land 3

(* Advance the cursor over padding.

   "Padding is present, if necessary, to ensure 4-byte alignment for
   the descriptor. Such padding is not included in namesz. [...]
   Padding is present, if necessary, to ensure 4-byte alignment for
   the next note entry. Such padding is not included in descsz."
   From "Tool Interface Standard (TIS)
   Executable and Linking Format (ELF) Specification" *)
let gulp_padding cursor size =
  let unread = padding size in
  if unread > 0 then begin
    Owee_buf.ensure cursor unread "Not found padding after note name";
    Owee_buf.advance cursor unread
  end

let check_string_length size str =
  let len = String.length str + (* terminating zero char *) 1 in
  if not (len = size) then
    Owee_buf.invalid_format
      (Printf.sprintf "Unexpected length of %s instead of %d\n" str size)

let read_desc_size cursor ~expected_owner ~expected_type =
  Owee_buf.ensure cursor (4 * 3) "Note header truncated";
  let namesz = Read.u32 cursor in
  check_string_length namesz expected_owner;
  let descsz = Read.u32 cursor in
  let typ = Read.u32 cursor in
  if not (typ = expected_type) then
    Owee_buf.invalid_format
      (Printf.sprintf "Unexpected note type %d instead of %d\n"
         typ expected_type);
  Owee_buf.ensure cursor namesz "Note owner name truncated";
  (match Read.zero_string cursor ~maxlen:namesz () with
   | None ->
     Owee_buf.invalid_format
       (Printf.sprintf "Cannot read note owner of length %d\n" namesz)
   | Some owner ->
     if not (String.equal owner expected_owner) then
       Owee_buf.invalid_format
         (Printf.sprintf "Unexpected note owner %s instead of %s\n"
            owner expected_owner));
  gulp_padding cursor namesz;
  Owee_buf.ensure cursor descsz
    (Printf.sprintf "Cannot read note description of size %d\n" descsz);
  descsz

let read_header cursor =
  Owee_buf.ensure cursor (4 * 3) "Note header truncated";
  let namesz = Read.u32 cursor in
  let descsz = Read.u32 cursor in
  let typ = Read.u32 cursor in
  Owee_buf.ensure cursor namesz "Note owner name truncated";
  let owner =
    match Read.zero_string cursor ~maxlen:namesz () with
   | None ->
     Owee_buf.invalid_format
       (Printf.sprintf "Cannot read owner of length %d\n" namesz)
   | Some str ->
     check_string_length namesz str;
     str
  in
  gulp_padding cursor namesz;
  Owee_buf.ensure cursor descsz
    (Printf.sprintf "Cannot read note description of size %d\n" descsz);
  { owner;
    size = descsz;
    typ;
  }

exception Section_not_found of string

let find_notes_section sections name =
  match Owee_elf.find_section sections name with
  | None -> raise (Section_not_found name)
  | Some s ->
    match s.sh_type with
    | 7 (* SHT_NOTE *) -> s
    | _ ->
      Owee_buf.invalid_format
        (Printf.sprintf "Unexpected type %d of %s section, instead of SHT_NOTE=7\n"
           s.sh_type s.sh_name_str)

module Stapsdt = struct
  type t =
    { addr : int64 (** address of the probe site *)
    ; semaphore : int64 option (** address of the semaphore corresponding to the probe *)
    ; provider : string
    ; name : string
    ; args : string (** probe arguments  *)
    }

  (* Arguments can be tricky to parse: [s] can be empty or ":" or space separated list of
     N@OP, but OP can have spaces in it and "N@" may be missing.

     CR-someday gyorsh: implement full parsing? *)

  let adjust addr ~actual_base ~recorded_base =
    Int64.add (Int64.sub actual_base recorded_base) addr

  let read cursor ~actual_base =
    let descsz = read_desc_size
                 ~expected_owner:"stapsdt"
                 ~expected_type:3 (* stapsdt v3 *)
                 cursor
    in
    if descsz < 8 * 3
    then Owee_buf.invalid_format
           (Printf.sprintf "Too small size of note %d\n" descsz);
    let addr = Read.u64 cursor in
    let recorded_base = Read.u64 cursor in
    let semaphore =
      let n = Read.u64 cursor in
      if Int64.equal n 0L then None else Some n
    in
    let maxlen = descsz - (8 * 3) in
    let provider =
      match Read.zero_string cursor ~maxlen () with
      | None -> Owee_buf.invalid_format "Cannot read probe provider"
      | Some s -> s
    in
    let maxlen = maxlen - String.length provider - 1 in
    let name =
      match Read.zero_string cursor ~maxlen () with
      | None -> Owee_buf.invalid_format "Cannot read probe name"
      | Some s -> s
    in
    let maxlen = maxlen - String.length name - 1 in
    let args =
      match Read.zero_string cursor ~maxlen () with
      | None -> Owee_buf.invalid_format "Cannot read probe's arguments"
      | Some s -> s
    in
    (* skip padding of description to 4-byte boundary *)
    gulp_padding cursor descsz;
    { addr = adjust addr ~actual_base ~recorded_base
    ; semaphore = begin match semaphore with
        | None -> None
        | Some s -> Some (adjust s ~actual_base ~recorded_base)
      end
    ; provider
    ; name
    ; args
    }

  let find_base_address sections =
    match Owee_elf.find_section sections ".stapsdt.base" with
    | None -> None
    | Some base_section -> Some base_section.sh_addr

  let iter map sections ~f =
    let s = find_notes_section sections ".note.stapsdt" in
    match find_base_address sections with
    | None ->
      Owee_buf.invalid_format
        (Printf.sprintf
           "Found .note.stapsdt but not .stapsdt.base section\n")
    | Some actual_base ->
      let body = Owee_elf.section_body map s in
      let cursor = Owee_buf.cursor body in
      while not (Owee_buf.at_end cursor) do
        let note = read cursor ~actual_base in
        f note
      done
end

let char_hex n =
  Char.unsafe_chr (n + if n < 10 then Char.code '0' else (Char.code 'a' - 10))

let hex_to_string cursor size =
  (* read desc byte by byte and convert hex to string *)
  let result = Bytes.create (size*2) in
  for i = 0 to size - 1 do
    let x = Read.u8 cursor in
    Bytes.unsafe_set result (i*2) (char_hex (x lsr 4));
    Bytes.unsafe_set result (i*2+1) (char_hex (x land 0x0f));
  done;
  Bytes.unsafe_to_string result

let read_buildid map sections =
  let s = find_notes_section sections ".note.gnu.build-id" in
  let body = Owee_elf.section_body map s in
  let cursor = Owee_buf.cursor body in
  let descsz = read_desc_size cursor
                 ~expected_owner:"GNU"
                 ~expected_type:(* NT_GNU_BUILD_ID *) 3 in
  let buildid = hex_to_string cursor descsz in
  gulp_padding cursor descsz;
  if not (Owee_buf.at_end cursor) then
    Owee_buf.invalid_format "Unexpected data after buildid";
  buildid



