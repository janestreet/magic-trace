exception Error of string

let verbose = ref false

type entry =
  { addr : int64 (** start address of the segment *)
  ; offset : int64 (** file offset *)
  }

type t =
  { vma_offset_text : int64
  ; vma_offset_semaphores : int64
  }

let is_mapped_from_file (e : Owee_linux_maps.entry) =
  not (e.inode = 0L && e.device_major = 0 && e.device_minor = 0)
;;

(*
   The following calculation give the dynamic address of a symbol:
   sym_dynamic_addr
   "symbol's dynamic address"
   = "segment start"
   + "offset of symbol's static address from the start of its section"
   + "offset of its section from the base of the segment's offset in the file"
   = "segment start"
   + "symbol's static address" - "section start"
   + "section offset into the file" - "segment offset into the file"
   = seg_addr + (sym_static_addr - sec_addr) + (sec_offset - seg_offset)
   = seg_addr + sec_offset  - seg_offset - sec_addr + sym_static_addr
   Read "segment start" and "segment offset into file" from mmap.
   The rest is known from reading elf file.
   Precompute the offset of dynamic address from static address
   for each type of symbol, making sure it doesn't over/underflow.
*)
let vma_offset mmap_entry (elf_section : Elf.section) =
  if mmap_entry.addr < elf_section.addr || elf_section.offset < mmap_entry.offset
  then raise (Failure "Unexpected section sizes");
  Int64.sub
    (Int64.add (Int64.sub mmap_entry.addr mmap_entry.offset) elf_section.offset)
    elf_section.addr
;;

let read ~pid (elf : Elf.t) =
  let filename = elf.filename in
  let text = ref None in
  let data = ref None in
  let update p (e : Owee_linux_maps.entry) =
    match !p with
    | None -> p := Some { addr = e.address_start; offset = e.offset }
    | Some _ ->
      raise
        (Error
           (Printf.sprintf
              "Unexpected format of /proc/%d/maps: duplicate segment for %s\n"
              pid
              filename))
  in
  let owee_entries = Owee_linux_maps.scan_pid pid in
  List.iter
    (fun (e : Owee_linux_maps.entry) ->
       if is_mapped_from_file e && String.equal filename e.pathname
       then (
         match e.perm_read, e.perm_write, e.perm_execute, e.perm_shared with
         | true, false, true, false -> update text e
         | true, true, false, false -> update data e
         | _ -> ()))
    owee_entries;
  match !text, !data, elf.semaphores_section with
  | Some text, Some data, Some semaphores_section ->
    { vma_offset_semaphores = vma_offset data semaphores_section
    ; vma_offset_text = vma_offset text elf.text_section
    }
  | None, _, _ ->
    raise
      (Error
         (Printf.sprintf
            "Unexpected format of /proc/%d/maps: missing executable segment start"
            pid))
  | _, None, _ ->
    raise
      (Error
         (Printf.sprintf
            "Unexpected format of /proc/%d/maps: missing write segment start"
            pid))
  | _, _, None -> raise (Failure (Printf.sprintf "No .probes section in %s" elf.filename))
;;
