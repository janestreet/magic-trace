open Owee_buf

let rec decode_flags n acc = function
  | [] -> acc
  | (index, flag) :: flags when n land (1 lsl index) <> 0 ->
    decode_flags n (flag :: acc) flags
  | _ :: flags ->
    decode_flags n acc flags

let read_lc_string buf t =
  let offset = Read.u32 t in
  match Read.zero_string (cursor buf ~at:offset) () with
  | None -> invalid_format "invalid lc_string"
  | Some s -> s

type magic =
  | MAGIC32
  | MAGIC64
  | CIGAM32
  | CIGAM64

let magic = function
  | 0xFEEDFACE -> MAGIC32
  | 0xFEEDFACF -> MAGIC64
  | 0xCEFAEDFE -> CIGAM32
  | 0xCFFAEDFE -> CIGAM64
  | _ -> invalid_format "magic"

let string_of_magic = function
  | MAGIC32 -> "MAGIC32"
  | MAGIC64 -> "MAGIC64"
  | CIGAM32 -> "CIGAM32"
  | CIGAM64 -> "CIGAM64"

type unknown = [ `Unknown of int ]

type cpu_type = [
  | `X86
  | `X86_64
  | `ARM
  | `POWERPC
  | `POWERPC64
  | unknown
]

let cpu_type = function
  | 0x00000007 -> `X86
  | 0x01000007 -> `X86_64
  | 0x0000000c -> `ARM
  | 0x00000012 -> `POWERPC
  | 0x01000012 -> `POWERPC64
  | n          -> `Unknown n

type cpu_subtype = [
  | `Intel
  | `I386_ALL
  | `I386
  | `I486
  | `I486SX
  | `PENT
  | `PENTPRO
  | `PENTII_M3
  | `PENTII_M5
  | `CELERON
  | `CELERON_MOBILE
  | `PENTIUM_3
  | `PENTIUM_3_M
  | `PENTIUM_3_XEON
  | `PENTIUM_M
  | `PENTIUM_4
  | `PENTIUM_4_M
  | `ITANIUM
  | `ITANIUM_2
  | `XEON
  | `XEON_MP
  | `INTEL_FAMILY
  | `INTEL_FAMILY_MAX
  | `INTEL_MODEL
  | `INTEL_MODEL_ALL
  | `X86_ALL
  | `X86_64_ALL
  | `X86_ARCH1
  | `POWERPC_ALL
  | `POWERPC_601
  | `POWERPC_602
  | `POWERPC_603
  | `POWERPC_603e
  | `POWERPC_603ev
  | `POWERPC_604
  | `POWERPC_604e
  | `POWERPC_620
  | `POWERPC_750
  | `POWERPC_7400
  | `POWERPC_7450
  | `POWERPC_970
  | `ARM_ALL
  | `ARM_V4T
  | `ARM_V6
  | unknown
]

let cpu_subtype ty tag = match ty, tag with
  | `X86       , 132 -> `I486SX
  | `X86       , 5   -> `PENT
  | `X86       , 22  -> `PENTPRO
  | `X86       , 54  -> `PENTII_M3
  | `X86       , 86  -> `PENTII_M5
  | `X86       , 103 -> `CELERON
  | `X86       , 119 -> `CELERON_MOBILE
  | `X86       , 8   -> `PENTIUM_3
  | `X86       , 24  -> `PENTIUM_3_M
  | `X86       , 40  -> `PENTIUM_3_XEON
  | `X86       , 9   -> `PENTIUM_M
  | `X86       , 10  -> `PENTIUM_4
  | `X86       , 26  -> `PENTIUM_4_M
  | `X86       , 11  -> `ITANIUM
  | `X86       , 27  -> `ITANIUM_2
  | `X86       , 12  -> `XEON
  | `X86       , 28  -> `XEON_MP
  | `X86       , 3   -> `X86_ALL
  | `X86       , 4   -> `X86_ARCH1
  | `X86_64    , 3   -> `X86_64_ALL
  | `POWERPC   , 0   -> `POWERPC_ALL
  | `POWERPC   , 1   -> `POWERPC_601
  | `POWERPC   , 2   -> `POWERPC_602
  | `POWERPC   , 3   -> `POWERPC_603
  | `POWERPC   , 4   -> `POWERPC_603e
  | `POWERPC   , 5   -> `POWERPC_603ev
  | `POWERPC   , 6   -> `POWERPC_604
  | `POWERPC   , 7   -> `POWERPC_604e
  | `POWERPC   , 8   -> `POWERPC_620
  | `POWERPC   , 9   -> `POWERPC_750
  | `POWERPC   , 10  -> `POWERPC_7400
  | `POWERPC   , 11  -> `POWERPC_7450
  | `POWERPC   , 100 -> `POWERPC_970
  | `POWERPC64 , 0   -> `POWERPC_ALL
  | `POWERPC64 , 1   -> `POWERPC_601
  | `POWERPC64 , 2   -> `POWERPC_602
  | `POWERPC64 , 3   -> `POWERPC_603
  | `POWERPC64 , 4   -> `POWERPC_603e
  | `POWERPC64 , 5   -> `POWERPC_603ev
  | `POWERPC64 , 6   -> `POWERPC_604
  | `POWERPC64 , 7   -> `POWERPC_604e
  | `POWERPC64 , 8   -> `POWERPC_620
  | `POWERPC64 , 9   -> `POWERPC_750
  | `POWERPC64 , 10  -> `POWERPC_7400
  | `POWERPC64 , 11  -> `POWERPC_7450
  | `POWERPC64 , 100 -> `POWERPC_970
  | `ARM       , 0   -> `ARM_ALL
  | `ARM       , 5   -> `ARM_V4T
  | `ARM       , 6   -> `ARM_V6
  | _         , n    -> `Unknown n

type file_type = [
  | `OBJECT
  | `EXECUTE
  | `CORE
  | `PRELOAD
  | `DYLIB
  | `DYLINKER
  | `BUNDLE
  | `DYLIB_STUB
  | `DSYM
  | unknown
]

let file_type = function
  | 0x1 -> `OBJECT
  | 0x2 -> `EXECUTE
  | 0x4 -> `CORE
  | 0x5 -> `PRELOAD
  | 0x6 -> `DYLIB
  | 0x7 -> `DYLINKER
  | 0x8 -> `BUNDLE
  | 0x9 -> `DYLIB_STUB
  | 0xA -> `DSYM
  | n   -> `Unknown n

type header_flag = [
  (*  the object file has no undefined references *)
  | `NOUNDEFS
  (*  the object file is the output of an incremental link against a base file and can't be link edited again *)
  | `INCRLINK
  (*  the object file is input for the dynamic linker and can't be staticly link edited again *)
  | `DYLDLINK
  (*  the object file's undefined references are bound by the dynamic linker when loaded. *)
  | `BINDATLOAD
  (*  the file has its dynamic undefined references prebound. *)
  | `PREBOUND
  (*  the file has its read-only and read-write segments split *)
  | `SPLIT_SEGS
  (*  the image is using two-level name space bindings *)
  | `TWOLEVEL
  (*  the executable is forcing all images to use flat name space bindings *)
  | `FORCE_FLAT
  (*  this umbrella guarantees no multiple defintions of symbols in its sub-images so the two-level namespace hints can always be used. *)
  | `NOMULTIDEFS
  (*  do not have dyld notify the prebinding agent about this executable *)
  | `NOFIXPREBINDING
  (*  the binary is not prebound but can have its prebinding redone. only used when `PREBOUND is not set. *)
  | `PREBINDABLE
  (*  indicates that this binary binds to all two-level namespace modules of its dependent libraries. only used when `PREBINDABLE and `TWOLEVEL are both set. *)
  | `ALLMODSBOUND
  (*  safe to divide up the sections into sub-sections via symbols for dead code stripping *)
  | `SUBSECTIONS_VIA_SYMBOLS
  (*  the binary has been canonicalized via the unprebind operation *)
  | `CANONICAL
  (*  the final linked image contains external weak symbols *)
  | `WEAK_DEFINES
  (*  the final linked image uses weak symbols *)
  | `BINDS_TO_WEAK
  (*  When this bit is set, all stacks  in the task will be given stack execution privilege.  Only used in `EXECUTE filetypes. *)
  | `ALLOW_STACK_EXECUTION
  (*  When this bit is set, the binary  declares it is safe for use in processes with uid zero *)
  | `ROOT_SAFE
  (*  When this bit is set, the binary  declares it is safe for use in processes when issetugid() is true *)
  | `SETUID_SAFE
  (*  When this bit is set on a dylib,  the static linker does not need to examine dependent dylibs to see if any are re-exported *)
  | `NO_REEXPORTED_DYLIBS
  (*  When this bit is set, the OS will load the main executable at a random address.  Only used in `EXECUTE filetypes. *)
  | `PIE
]

type header = {
  magic       : magic;
  cpu_type    : cpu_type;
  cpu_subtype : cpu_subtype;
  file_type   : file_type;
  flags       : header_flag list;
}

let is64bit header = match header.magic with
  | MAGIC32 | CIGAM32 -> false
  | MAGIC64 | CIGAM64 -> true

let header_flags = [
  00 , `NOUNDEFS;
  01 , `INCRLINK;
  02 , `DYLDLINK;
  03 , `BINDATLOAD;
  04 , `PREBOUND;
  05 , `SPLIT_SEGS;
  07 , `TWOLEVEL;
  08 , `FORCE_FLAT;
  09 , `NOMULTIDEFS;
  10 , `NOFIXPREBINDING;
  11 , `PREBINDABLE;
  12 , `ALLMODSBOUND;
  13 , `SUBSECTIONS_VIA_SYMBOLS;
  14 , `CANONICAL;
  15 , `WEAK_DEFINES;
  16 , `BINDS_TO_WEAK;
  17 , `ALLOW_STACK_EXECUTION;
  18 , `ROOT_SAFE;
  19 , `SETUID_SAFE;
  20 , `NO_REEXPORTED_DYLIBS;
  21 , `PIE;
]

let read_header buf =
  let start = buf.position in
  let magic       = magic (Read.u32 buf) in
  let cpu_type    = cpu_type (Read.u32 buf) in
  let cpu_subtype = cpu_subtype cpu_type (Read.u32 buf) in
  let file_type   = file_type (Read.u32 buf) in
  let _nb_cmds    = Read.u32 buf in
  let size_of_cmds = Read.u32 buf in
  let flags       = decode_flags (Read.u32 buf) [] header_flags in
  let _reserved   = match magic with
    | MAGIC64 | CIGAM64 -> Read.u32 buf
    | _ -> 0
  in
  let _header_size = buf.position - start in
  size_of_cmds, {magic; cpu_type; cpu_subtype; file_type; flags}

(* Platform-specific relocation types. *)
type reloc_type = [
  | `GENERIC_RELOC_VANILLA
  | `GENERIC_RELOC_PAIR
  | `GENERIC_RELOC_SECTDIFF
  | `GENERIC_RELOC_LOCAL_SECTDIFF
  | `GENERIC_RELOC_PB_LA_PTR
  | `X86_64_RELOC_BRANCH
  | `X86_64_RELOC_GOT_LOAD
  | `X86_64_RELOC_GOT
  | `X86_64_RELOC_SIGNED
  | `X86_64_RELOC_UNSIGNED
  | `X86_64_RELOC_SUBTRACTOR
  | `X86_64_RELOC_SIGNED_1
  | `X86_64_RELOC_SIGNED_2
  | `X86_64_RELOC_SIGNED_4
  | `PPC_RELOC_VANILLA
  | `PPC_RELOC_PAIR
  | `PPC_RELOC_BR14
  | `PPC_RELOC_BR24
  | `PPC_RELOC_HI16
  | `PPC_RELOC_LO16
  | `PPC_RELOC_HA16
  | `PPC_RELOC_LO14
  | `PPC_RELOC_SECTDIFF
  | `PPC_RELOC_LOCAL_SECTDIFF
  | `PPC_RELOC_PB_LA_PTR
  | `PPC_RELOC_HI16_SECTDIFF
  | `PPC_RELOC_LO16_SECTDIFF
  | `PPC_RELOC_HA16_SECTDIFF
  | `PPC_RELOC_JBSR
  | `PPC_RELOC_LO14_SECTDIFF
  | unknown
]

let reloc_type cpu_type n = match cpu_type, n with
  | `X86       , 00   -> `GENERIC_RELOC_VANILLA
  | `X86       , 01   -> `GENERIC_RELOC_PAIR
  | `X86       , 02   -> `GENERIC_RELOC_SECTDIFF
  | `X86       , 03   -> `GENERIC_RELOC_LOCAL_SECTDIFF
  | `X86       , 04   -> `GENERIC_RELOC_PB_LA_PTR
  | `X86_64    , 00   -> `X86_64_RELOC_UNSIGNED
  | `X86_64    , 01   -> `X86_64_RELOC_SIGNED
  | `X86_64    , 02   -> `X86_64_RELOC_BRANCH
  | `X86_64    , 03   -> `X86_64_RELOC_GOT_LOAD
  | `X86_64    , 04   -> `X86_64_RELOC_GOT
  | `X86_64    , 05   -> `X86_64_RELOC_SUBTRACTOR
  | `X86_64    , 06   -> `X86_64_RELOC_SIGNED_1
  | `X86_64    , 07   -> `X86_64_RELOC_SIGNED_2
  | `X86_64    , 08   -> `X86_64_RELOC_SIGNED_4
  | `POWERPC   , 00   -> `PPC_RELOC_VANILLA
  | `POWERPC   , 01   -> `PPC_RELOC_PAIR
  | `POWERPC   , 02   -> `PPC_RELOC_BR14
  | `POWERPC   , 03   -> `PPC_RELOC_BR24
  | `POWERPC   , 04   -> `PPC_RELOC_HI16
  | `POWERPC   , 05   -> `PPC_RELOC_LO16
  | `POWERPC   , 06   -> `PPC_RELOC_HA16
  | `POWERPC   , 07   -> `PPC_RELOC_LO14
  | `POWERPC   , 08   -> `PPC_RELOC_SECTDIFF
  | `POWERPC   , 09   -> `PPC_RELOC_PB_LA_PTR
  | `POWERPC   , 10   -> `PPC_RELOC_HI16_SECTDIFF
  | `POWERPC   , 11   -> `PPC_RELOC_LO16_SECTDIFF
  | `POWERPC   , 12   -> `PPC_RELOC_HA16_SECTDIFF
  | `POWERPC   , 13   -> `PPC_RELOC_JBSR
  | `POWERPC   , 14   -> `PPC_RELOC_LO14_SECTDIFF
  | `POWERPC   , 15   -> `PPC_RELOC_LOCAL_SECTDIFF
  | `POWERPC64 , 00   -> `PPC_RELOC_VANILLA
  | `POWERPC64 , 01   -> `PPC_RELOC_PAIR
  | `POWERPC64 , 02   -> `PPC_RELOC_BR14
  | `POWERPC64 , 03   -> `PPC_RELOC_BR24
  | `POWERPC64 , 04   -> `PPC_RELOC_HI16
  | `POWERPC64 , 05   -> `PPC_RELOC_LO16
  | `POWERPC64 , 06   -> `PPC_RELOC_HA16
  | `POWERPC64 , 07   -> `PPC_RELOC_LO14
  | `POWERPC64 , 08   -> `PPC_RELOC_SECTDIFF
  | `POWERPC64 , 09   -> `PPC_RELOC_PB_LA_PTR
  | `POWERPC64 , 10   -> `PPC_RELOC_HI16_SECTDIFF
  | `POWERPC64 , 11   -> `PPC_RELOC_LO16_SECTDIFF
  | `POWERPC64 , 12   -> `PPC_RELOC_HA16_SECTDIFF
  | `POWERPC64 , 13   -> `PPC_RELOC_JBSR
  | `POWERPC64 , 14   -> `PPC_RELOC_LO14_SECTDIFF
  | `POWERPC64 , 15   -> `PPC_RELOC_LOCAL_SECTDIFF
  | _         , n     -> `Unknown n

type relocation_info = {
  (* offset from start of section to place to be relocated *)
  ri_address   : int;
  (* index into symbol or section table *)
  ri_symbolnum : u32;
  (* indicates if the item to be relocated is part of an instruction containing PC-relative addressing *)
  ri_pcrel     : bool;
  (* length of item containing address to be relocated (literal form (4) instead of power of two (2)) *)
  ri_length    : u32;
  (* indicates whether symbolnum is an index into the symbol table (True) or section table (False) *)
  ri_extern    : bool;
  (* relocation type *)
  ri_type      : reloc_type;
}

let bits ofs sz n = (n lsl (32 - ofs - sz)) lsr (32 - sz)

let read_relocation_info _t header ri_address value = {
  ri_address;
  ri_symbolnum = bits 0 24 value;
  ri_pcrel     = bits 24 1 value = 1;
  ri_length    = 1 lsl (bits 25 2 value);
  ri_extern    = bits 27 1 value = 1;
  ri_type      = reloc_type header.cpu_type (bits 28 4 value);
}

type scattered_relocation_info = {
  rs_pcrel   : bool;   (*  indicates if the item to be relocated is part of an instruction containing PC-relative addressing *)
  rs_length  : u32; (*  length of item containing address to be relocated (literal form (4) instead of power of two (2)) *)
  rs_type    : reloc_type; (*  relocation type *)
  rs_address : u32; (*  offset from start of section to place to be relocated *)
  rs_value   : s32;  (*  address of the relocatable expression for the item in the file that needs to be updated if the address is changed *)
}

let read_scattered_relocation_info _t header address value = {
  rs_pcrel   = bits 1 1 address = 1;
  rs_length  = 1 lsl (bits 2 2 address);
  rs_type    = reloc_type header.cpu_type (bits 4 4 address);
  rs_address = bits 8 24 address;
  rs_value   = value;
}

type relocation = [
  | `Relocation_info of relocation_info
  | `Scattered_relocation_info of scattered_relocation_info
]

let read_relocation header t =
  let address = Read.u32 t in
  let value   = Read.u32 t in
  if (address land 0x80000000) = 0
  then `Relocation_info
      (read_relocation_info t header address value)
  else `Scattered_relocation_info
      (read_scattered_relocation_info t header address value)

type sec_type = [
  (* regular section *)
  | `S_REGULAR
  (* zero fill on demand section *)
  | `S_ZEROFILL
  (* section with only literal C strings *)
  | `S_CSTRING_LITERALS
  (* section with only 4 byte literals *)
  | `S_4BYTE_LITERALS
  (* section with only 8 byte literals *)
  | `S_8BYTE_LITERALS
  (* section with only pointers to literals *)
  | `S_LITERAL_POINTERS
  (* section with only non-lazy symbol pointers *)
  | `S_NON_LAZY_SYMBOL_POINTERS
  (* section with only lazy symbol pointers *)
  | `S_LAZY_SYMBOL_POINTERS
  (* section with only symbol stubs, bte size of stub in the reserved2 field *)
  | `S_SYMBOL_STUBS
  (* section with only function pointers for initialization *)
  | `S_MOD_INIT_FUNC_POINTERS
  (* section with only function pointers for termination *)
  | `S_MOD_TERM_FUNC_POINTERS
  (* section contains symbols that are to be coalesced *)
  | `S_COALESCED
  (* zero fill on demand section (that can be larger than 4 gigabytes) *)
  | `S_GB_ZEROFILL
  (* section with only pairs of function pointers for interposing *)
  | `S_INTERPOSING
  (* section with only 16 byte literals *)
  | `S_16BYTE_LITERALS
  (* section contains DTrace Object Format *)
  | `S_DTRACE_DOF
  (* section with only lazy symbol pointers to lazy loaded dylibs *)
  | `S_LAZY_DYLIB_SYMBOL_POINTERS
  | unknown
]

let sec_type flags = match flags land 0x000000ff with
  | 0x00 -> `S_REGULAR
  | 0x01 -> `S_ZEROFILL
  | 0x02 -> `S_CSTRING_LITERALS
  | 0x03 -> `S_4BYTE_LITERALS
  | 0x04 -> `S_8BYTE_LITERALS
  | 0x05 -> `S_LITERAL_POINTERS
  | 0x06 -> `S_NON_LAZY_SYMBOL_POINTERS
  | 0x07 -> `S_LAZY_SYMBOL_POINTERS
  | 0x08 -> `S_SYMBOL_STUBS
  | 0x09 -> `S_MOD_INIT_FUNC_POINTERS
  | 0x0a -> `S_MOD_TERM_FUNC_POINTERS
  | 0x0b -> `S_COALESCED
  | 0x0c -> `S_GB_ZEROFILL
  | 0x0d -> `S_INTERPOSING
  | 0x0e -> `S_16BYTE_LITERALS
  | 0x0f -> `S_DTRACE_DOF
  | 0x10 -> `S_LAZY_DYLIB_SYMBOL_POINTERS
  | n    -> `Unknown n

type sec_user_attr = [
  (* section contains only true machine instructions *)
  | `PURE_INSTRUCTIONS
  (* section contains coalesced symbols that are not to be in a ranlib table of contents *)
  | `NO_TOC
  (* ok to strip static symbols in this section in files with the MH_DYLDLINK flag *)
  | `STRIP_STATIC_SYMS
  (* no dead stripping *)
  | `NO_DEAD_STRIP
  (* blocks are live if they reference live blocks *)
  | `LIVE_SUPPORT
  (* used with i386 code stubs written on by dyld *)
  | `SELF_MODIFYING_CODE
  (* a debug section *)
  | `DEBUG
]

let sec_user_attr n = decode_flags n []
    [30, `PURE_INSTRUCTIONS;
     29, `NO_TOC;
     28, `STRIP_STATIC_SYMS;
     27, `NO_DEAD_STRIP;
     26, `LIVE_SUPPORT;
     25, `SELF_MODIFYING_CODE]

type sec_sys_attr = [
  (* section contains soem machine instructions *)
  | `SOME_INSTRUCTIONS
  (* section has external relocation entries *)
  | `EXT_RELOC
  (* section has local relocation entries *)
  | `LOC_RELOC
]

let sec_sys_attr n = decode_flags n []
    [7, `LOC_RELOC;
     8, `EXT_RELOC;
     9, `SOME_INSTRUCTIONS]

type section = {
  (* name of section *)
  sec_sectname   : string;
  (* name of segment that should own this section *)
    sec_segname    : string;
  (* virtual memoy address for section *)
  sec_addr       : u64;
  (* size of section *)
  sec_size       : u64;
  (* alignment required by section (literal form, not power of two, e.g. 8 not 3) *)
  sec_align      : int;
  (* relocations for this section *)
  sec_relocs     : relocation array;
  (* type of section *)
  sec_type       : sec_type;
  (* user attributes of section *)
  sec_user_attrs : sec_user_attr list;
  (* system attibutes of section *)
  sec_sys_attrs  : sec_sys_attr list;
}

type vm_prot = [ `READ | `WRITE | `EXECUTE ]

let read_vm_prot t = decode_flags (Read.u32 t) []
    [0, `READ; 1, `WRITE; 2, `EXECUTE]

type seg_flag = [
  | `HIGHVM  (* The file contents for this segment is for the high part of the VM space, the low part is zero filled (for stacks in core files). *)
  | `NORELOC (* This segment has nothing that was relocated in it and nothing relocated to it, that is it may be safely replaced without relocation. *)
]

let read_seg_flag t = decode_flags (Read.u32 t) []
    [0, `HIGHVM; 2, `NORELOC]

type segment = {
  (* segment name *)
  seg_segname  : string;
  (* virtual address where the segment is loaded *)
  seg_vmaddr   : u64;
  (* size of segment at runtime *)
  seg_vmsize   : u64;
  (* file offset of the segment *)
  seg_fileoff  : u64;
  (* size of segment in file *)
  seg_filesize : u64;
  (* maximum virtual memory protection *)
  seg_maxprot  : vm_prot list;
  (* initial virtual memory protection *)
  seg_initprot : vm_prot list;
  (* segment flags *)
  seg_flags    : seg_flag list;
  (* sections owned by this segment *)
  seg_sections : section array;
}

type sym_type = [
  (* undefined symbol, n_sect is 0 *)
  | `UNDF
  (* absolute symbol, does not need relocation, n_sect is 0 *)
  | `ABS
  (* symbol is defined in section n_sect *)
  | `SECT
  (* symbol is undefined and the image is using a prebound value for the symbol, n_sect is 0 *)
  | `PBUD
  (* symbol is defined to be the same as another symbol. n_value is a string table offset indicating the name of that symbol *)
  | `INDR
  (* stab global symbol: name,,0,type,0 *)
  | `GSYM
  (* stab procedure name (f77 kludge): name,,0,0,0 *)
  | `FNAME
  (* stab procedure: name,,n_sect,linenumber,address *)
  | `FUN
  (* stab static symbol: name,,n_sect,type,address *)
  | `STSYM
  (* stab .lcomm symbol: name,,n_sect,type,address *)
  | `LCSYM
  (* stab begin nsect sym: 0,,n_sect,0,address *)
  | `BNSYM
  (* stab emitted with gcc2_compiled and in gcc source *)
  | `OPT
  (* stab register sym: name,,0,type,register *)
  | `RSYM
  (* stab src line: 0,,n_sect,linenumber,address *)
  | `SLINE
  (* stab end nsect sym: 0,,n_sect,0,address *)
  | `ENSYM
  (* stab structure elt: name,,0,type,struct_offset *)
  | `SSYM
  (* stab source file name: name,,n_sect,0,address *)
  | `SO
  (* stab object file name: name,,0,0,st_mtime *)
  | `OSO
  (* stab local sym: name,,0,type,offset *)
  | `LSYM
  (* stab include file beginning: name,,0,0,sum *)
  | `BINCL
  (* stab #included file name: name,,n_sect,0,address *)
  | `SOL
  (* stab compiler parameters: name,,0,0,0 *)
  | `PARAMS
  (* stab compiler version: name,,0,0,0 *)
  | `VERSION
  (* stab compiler -O level: name,,0,0,0 *)
  | `OLEVEL
  (* stab parameter: name,,0,type,offset *)
  | `PSYM
  (* stab include file end: name,,0,0,0 *)
  | `EINCL
  (* stab alternate entry: name,,n_sect,linenumber,address *)
  | `ENTRY
  (* stab left bracket: 0,,0,nesting level,address *)
  | `LBRAC
  (* stab deleted include file: name,,0,0,sum *)
  | `EXCL
  (* stab right bracket: 0,,0,nesting level,address *)
  | `RBRAC
  (* stab begin common: name,,0,0,0 *)
  | `BCOMM
  (* stab end common: name,,n_sect,0,0 *)
  | `ECOMM
  (* stab end common (local name): 0,,n_sect,0,address *)
  | `ECOML
  (* stab second stab entry with length information *)
  | `LENG
  (* stab global pascal symbol: name,,0,subtype,line *)
  | `PC
  | unknown
]

let sym_type = function
  | 0x00 -> `UNDF
  | 0x01 -> `ABS
  | 0x07 -> `SECT
  | 0x06 -> `PBUD
  | 0x05 -> `INDR
  | 0x20 -> `GSYM
  | 0x22 -> `FNAME
  | 0x24 -> `FUN
  | 0x26 -> `STSYM
  | 0x28 -> `LCSYM
  | 0x2e -> `BNSYM
  | 0x3c -> `OPT
  | 0x40 -> `RSYM
  | 0x44 -> `SLINE
  | 0x4e -> `ENSYM
  | 0x60 -> `SSYM
  | 0x64 -> `SO
  | 0x66 -> `OSO
  | 0x80 -> `LSYM
  | 0x82 -> `BINCL
  | 0x84 -> `SOL
  | 0x86 -> `PARAMS
  | 0x88 -> `VERSION
  | 0x8A -> `OLEVEL
  | 0xa0 -> `PSYM
  | 0xa2 -> `EINCL
  | 0xa4 -> `ENTRY
  | 0xc0 -> `LBRAC
  | 0xc2 -> `EXCL
  | 0xe0 -> `RBRAC
  | 0xe2 -> `BCOMM
  | 0xe4 -> `ECOMM
  | 0xe8 -> `ECOML
  | 0xfe -> `LENG
  | 0x30 -> `PC
  | n    -> `Unknown n

type reference_flag = [
  (* reference to an external non-lazy symbol *)
  | `UNDEFINED_NON_LAZY
  (* reference to an external lazy symbol *)
  | `UNDEFINED_LAZY
  (* symbol is defined in this module *)
  | `DEFINED
  (* symbol is defined in this module and visible only to modules within this shared library *)
  | `PRIVATE_DEFINED
  (* reference to an external non-lazy symbol and visible only to modules within this shared library *)
  | `PRIVATE_UNDEFINED_NON_LAZY
  (* reference to an external lazy symbol and visible only to modules within this shared library *)
  | `PRIVATE_UNDEFINED_LAZY
  (* set for all symbols referenced by dynamic loader APIs *)
  | `REFERENCED_DYNAMICALLY
  (* indicates the symbol is a weak reference, set to 0 if definition cannot be found *)
  | `SYM_WEAK_REF
  (* indicates the symbol is a weak definition, will be overridden by a strong definition at link-time *)
  | `SYM_WEAK_DEF
  (* for two-level mach-o objects, specifies the index of the library in which this symbol is defined. zero specifies current image. *)
  | `LIBRARY_ORDINAL of u16
  | unknown
]

let reference_flag_lo16 = function
  | 0 -> `UNDEFINED_NON_LAZY
  | 1 -> `UNDEFINED_LAZY
  | 2 -> `DEFINED
  | 3 -> `PRIVATE_DEFINED
  | 4 -> `PRIVATE_UNDEFINED_NON_LAZY
  | 5 -> `PRIVATE_UNDEFINED_LAZY
  | n -> `Unknown n

let reference_flag_hi16 n = decode_flags n []
    [0, `REFERENCED_DYNAMICALLY;
     2, `SYM_WEAK_REF;
     3, `SYM_WEAK_DEF]

let reference_flags header v =
  if List.mem `TWOLEVEL header.flags then
    (* Something fishy here, check spec FIXME *)
    [reference_flag_lo16 (v land 0xF); `LIBRARY_ORDINAL (v land 0xf0)]
  else
    reference_flag_lo16 (v land 0xF) :: reference_flag_hi16 v

let sym_types n =
  if n land 0xe0 = 0 then
    let npext = n land 0x10 <> 0 in
    let ntype = sym_type ((n land 0x0e) lsr 1) in
    let next  = n land 0x01 <> 0 in
    (false, npext, ntype, next)
  else
    (true, false, sym_type n, false)

type symbol = {
  (* symbol name *)
  sym_name  : string;
  (* symbol type *)
  sym_type  : sym_type;
  (* true if limited global scope *)
  sym_pext  : bool;
  (* true if external symbol *)
  sym_ext   : bool;
  (* section index where the symbol can be found *)
  sym_sect  : u8;
  (* for stab entries, Left Word16 is the uninterpreted flags field, otherwise Right [REFERENCE_FLAG] are the symbol flags *)
  sym_flags : [`Uninterpreted of u16 | `Flags of reference_flag list];
  (* symbol value, 32-bit symbol values are promoted to 64-bit for simpliciy *)
  sym_value : u64;
}

let read_symbol_name t buf =
  let offset = Read.u32 t in
  match Read.zero_string (cursor buf ~at:offset) () with
  | None -> invalid_format "invalid symbol name"
  | Some s -> s

type dylib_module = {
  (*  module name string table offset *)
  dylib_module_name_offset    : u32;
  (*  (initial, count) pair of symbol table indices for externally defined symbols *)
  dylib_ext_def_sym           : u32 * u32;
  (*  (initial, count) pair of symbol table indices for referenced symbols *)
  dylib_ref_sym               : u32 * u32;
  (*  (initial, count) pair of symbol table indices for local symbols *)
  dylib_local_sym             : u32 * u32;
  (*  (initial, count) pair of symbol table indices for externally referenced symbols *)
  dylib_ext_rel               : u32 * u32;
  (*  (initial, count) pair of symbol table indices for the index of the module init section and the number of init pointers *)
  dylib_init                  : u32 * u32;
  (*  (initial, count) pair of symbol table indices for the index of the module term section and the number of term pointers *)
  dylib_term                  : u32 * u32;
  (*  statically linked address of the start of the data for this module in the __module_info section in the __OBJC segment *)
  dylib_objc_module_info_addr : u32;
  (*  number of bytes of data for this module that are used in the __module_info section in the __OBJC segment *)
  dylib_objc_module_info_size : u64;
}

type toc_entry = {
  symbol_index: u32;
  module_index: u32;
}

let read_toc t =
  let symbol_index = Read.u32 t in
  let module_index = Read.u32 t in
  { symbol_index; module_index }

let read_n_times f t n =
  Array.init n (fun _ -> f t)

type dynamic_symbol_table = {
  (*  symbol table index and count for local symbols *)
  localSyms    : u32 * u32;
  (*  symbol table index and count for externally defined symbols *)
  extDefSyms   : u32 * u32;
  (*  symbol table index and count for undefined symbols *)
  undefSyms    : u32 * u32;
  (*  list of symbol index and module index pairs *)
  toc_entries  : toc_entry array;
  (*  modules *)
  modules      : dylib_module array;
  (*  list of external reference symbol indices *)
  extRefSyms   : u32 array;
  (*  list of indirect symbol indices *)
  indirectSyms : u32 array;
  (*  external locations *)
  extRels      : relocation array;
  (*  local relocations *)
  locRels      : relocation array;
}

type dylib = {
  dylib_name : string;
  dylib_timestamp : u32;
  dylib_current_version : u32;
  dylib_compatibility_version: u32;
}

let read_dylib_command t lc =
  let dylib_name                  = read_lc_string lc t in
  let dylib_timestamp             = Read.u32 t in
  let dylib_current_version       = Read.u32 t in
  let dylib_compatibility_version = Read.u32 t in
  { dylib_name; dylib_timestamp;
    dylib_current_version; dylib_compatibility_version }

type command =
  (* segment of this file to be mapped *)
  | LC_SEGMENT_32 of segment lazy_t
  (* static link-edit symbol table and stab info *)
  | LC_SYMTAB of (symbol array * Owee_buf.t) lazy_t
  (* thread state information (list of (flavor, [long]) pairs) *)
  | LC_THREAD of (u32 * u32 array) list lazy_t
  (* unix thread state information (includes a stack) (list of (flavor, [long] pairs) *)
  | LC_UNIXTHREAD of (u32 * u32 array) list lazy_t
  (* dynamic link-edit symbol table info *)
  | LC_DYSYMTAB of dynamic_symbol_table lazy_t
  (* load a dynamically linked shared library (name, timestamp, current version, compatibility version) *)
  | LC_LOAD_DYLIB of dylib lazy_t
  (* dynamically linked shared lib ident (name, timestamp, current version, compatibility version) *)
  | LC_ID_DYLIB of dylib lazy_t
  (* load a dynamic linker (name of dynamic linker) *)
  | LC_LOAD_DYLINKER of string
  (* dynamic linker identification (name of dynamic linker) *)
  | LC_ID_DYLINKER of string
  (* modules prebound for a dynamically linked shared library (name, list of module indices) *)
  | LC_PREBOUND_DYLIB of (string * u8 array) lazy_t
  (* image routines (virtual address of initialization routine, module index where it resides) *)
  | LC_ROUTINES_32 of u32 * u32
  (* sub framework (name) *)
  | LC_SUB_FRAMEWORK of string
  (* sub umbrella (name) *)
  | LC_SUB_UMBRELLA of string
  (* sub client (name) *)
  | LC_SUB_CLIENT of string
  (* sub library (name) *)
  | LC_SUB_LIBRARY of string
  (* two-level namespace lookup hints (list of (subimage index, symbol table index) pairs *)
  | LC_TWOLEVEL_HINTS of ((u32 * u32) array) lazy_t
  (* prebind checksum (checksum) *)
  | LC_PREBIND_CKSUM of u32
  (* load a dynamically linked shared library that is allowed to be missing (symbols are weak imported) (name, timestamp, current version, compatibility version) *)
  | LC_LOAD_WEAK_DYLIB of dylib lazy_t
  (* 64-bit segment of this file to mapped *)
  | LC_SEGMENT_64 of segment lazy_t
  (* 64-bit image routines (virtual address of initialization routine, module index where it resides) *)
  | LC_ROUTINES_64 of u64 * u64
  (* the uuid for an image or its corresponding dsym file (8 element list of bytes) *)
  | LC_UUID of string
  (* runpath additions (path) *)
  | LC_RPATH of string
  (* local of code signature *)
  | LC_CODE_SIGNATURE of u32 * u32
  (* local of info to split segments *)
  | LC_SEGMENT_SPLIT_INFO of u32 * u32
  | LC_UNHANDLED of int * Owee_buf.t

let read_twolevelhint t =
  let word = Read.u32 t in
  let isub_image = bits 0 8 word and itoc = bits 8 24 word in
  (isub_image, itoc)

let read_twolevelhints buf t =
  let offset = Read.u32 t in
  let nhints = Read.u32 t in
  read_n_times read_twolevelhint (cursor buf ~at:offset) nhints

let rec read_thread t =
  if at_end t then
    []
  else
    let flavor = Read.u32 t in
    let count  = Read.u32 t in
    let state  = read_n_times Read.u32 t count in
    (flavor, state) :: read_thread t

let read_module_32 t =
  let module_name           = Read.u32 t in
  let iextdefsym            = Read.u32 t in
  let nextdefsym            = Read.u32 t in
  let irefsym               = Read.u32 t in
  let nrefsym               = Read.u32 t in
  let ilocalsym             = Read.u32 t in
  let nlocalsym             = Read.u32 t in
  let iextrel               = Read.u32 t in
  let nextrel               = Read.u32 t in
  let iinit_iterm           = Read.u32 t in
  let iinit                 = (iinit_iterm land 0x0000ffff) in
  let iterm                 = (iinit_iterm land 0xffff0000) lsr 16 in
  let ninit_nterm           = Read.u32 t in
  let ninit                 = (ninit_nterm land 0x0000ffff) in
  let nterm                 = (ninit_nterm land 0xffff0000) lsr 16 in
  let objc_module_info_addr = Read.u32 t in
  let objc_module_info_size = Read.u32 t in
  {
    dylib_module_name_offset    = module_name;
    dylib_ext_def_sym           = (iextdefsym, nextdefsym);
    dylib_ref_sym               = (irefsym, nrefsym);
    dylib_local_sym             = (ilocalsym, nlocalsym);
    dylib_ext_rel               = (iextrel, nextrel);
    dylib_init                  = (iinit, ninit);
    dylib_term                  = (iterm, nterm);
    dylib_objc_module_info_addr = objc_module_info_addr;
    dylib_objc_module_info_size = Int64.of_int objc_module_info_size;
  }

let read_module_64 t =
  let module_name           = Read.u32 t in
  let iextdefsym            = Read.u32 t in
  let nextdefsym            = Read.u32 t in
  let irefsym               = Read.u32 t in
  let nrefsym               = Read.u32 t in
  let ilocalsym             = Read.u32 t in
  let nlocalsym             = Read.u32 t in
  let iextrel               = Read.u32 t in
  let nextrel               = Read.u32 t in
  let iinit_iterm           = Read.u32 t in
  let iinit                 = (iinit_iterm land 0x0000ffff) in
  let iterm                 = (iinit_iterm land 0xffff0000) lsr 16 in
  let ninit_nterm           = Read.u32 t in
  let ninit                 = (ninit_nterm land 0x0000ffff) in
  let nterm                 = (ninit_nterm land 0xffff0000) lsr 16 in
  let objc_module_info_addr = Read.u32 t in
  let objc_module_info_size = Read.u64 t in
  {
    dylib_module_name_offset    = module_name;
    dylib_ext_def_sym           = (iextdefsym, nextdefsym);
    dylib_ref_sym               = (irefsym, nrefsym);
    dylib_local_sym             = (ilocalsym, nlocalsym);
    dylib_ext_rel               = (iextrel, nextrel);
    dylib_init                  = (iinit, ninit);
    dylib_term                  = (iterm, nterm);
    dylib_objc_module_info_addr = objc_module_info_addr;
    dylib_objc_module_info_size = objc_module_info_size;
  }

let read_dynamic_symbol_table header t buf =
  let ilocalsym  = Read.u32 t in
  let nlocalsym  = Read.u32 t in
  let iextdefsym = Read.u32 t in
  let nextdefsym = Read.u32 t in
  let iundefsym  = Read.u32 t in
  let nundefsym  = Read.u32 t in
  let tocoff     = Read.u32 t in
  let ntoc       = Read.u32 t in
  let toc        = read_n_times read_toc (cursor buf ~at:tocoff) ntoc in
  let modtaboff  = Read.u32 t in
  let nmodtab    = Read.u32 t in
  let modtab     = read_n_times
      (if is64bit header then read_module_64 else read_module_32)
      (cursor buf ~at:modtaboff) nmodtab
  in
  let extrefsymoff = Read.u32 t in
  let nextrefsyms  = Read.u32 t in
  let extrefsyms   = read_n_times Read.u32 (cursor buf ~at:extrefsymoff) nextrefsyms  in
  let indirectsymoff = Read.u32 t in
  let nindirectsyms  = Read.u32 t in
  let indirectsyms   = read_n_times Read.u32 (cursor buf ~at:indirectsymoff) nindirectsyms in
  let extreloff      = Read.u32 t in
  let nextrel        = Read.u32 t in
  let extrels        =
    read_n_times (read_relocation header) (cursor buf ~at:extreloff) nextrel in
  let locreloff      = Read.u32 t in
  let nlocrel        = Read.u32 t in
  let locrels        =
    read_n_times (read_relocation header) (cursor buf ~at:locreloff) nlocrel in
  {
    localSyms    = (ilocalsym, nlocalsym);
    extDefSyms   = (iextdefsym, nextdefsym);
    undefSyms    = (iundefsym, nundefsym);
    toc_entries  = toc;
    modules      = modtab;
    extRefSyms   = extrefsyms;
    indirectSyms = indirectsyms;
    extRels      = extrels;
    locRels      = locrels;
  }

let fixed_0_string t n =
  let result = Read.fixed_string t n in
  try String.sub result 0 (String.index result '\000')
  with Not_found -> result

let read_section_32 header buf t =
  let sectname = fixed_0_string t 16 in
  let segname  = fixed_0_string t 16 in
  let addr     = Read.u32 t in
  let size     = Read.u32 t in
  let _offset  = Read.u32 t in
  let align    = 1 lsl Read.u32 t in
  let reloff   = Read.u32 t in
  let nreloc   = Read.u32 t in
  let relocs   =
    read_n_times (read_relocation header) (cursor buf ~at:reloff) nreloc in
  let flags     = Read.u32 t in
  let _reserved = Read.u32 t in
  let _reserved = Read.u32 t in
  let sec_type   = sec_type flags in
  let user_attrs = sec_user_attr flags in
  let sys_attrs   = sec_sys_attr flags in
  {
    sec_sectname   = sectname;
    sec_segname    = segname;
    sec_addr       = Int64.of_int addr;
    sec_size       = Int64.of_int size;
    sec_align      = align;
    sec_relocs     = relocs;
    sec_type       = sec_type;
    sec_user_attrs = user_attrs;
    sec_sys_attrs  = sys_attrs;
  }

let read_segment_32 header buf t =
  let segname = fixed_0_string t 16 in
  let vmaddr   = Read.u32 t in
  let vmsize   = Read.u32 t in
  let fileoff  = Read.u32 t in
  let filesize = Read.u32 t in
  let maxprot  = read_vm_prot t in
  let initprot = read_vm_prot t in
  let nsects   = Read.u32 t in
  let flags    = read_seg_flag t in
  let sects    = read_n_times (read_section_32 header buf) t nsects in
  {
    seg_segname = segname;
    seg_vmaddr  = Int64.of_int vmaddr;
    seg_vmsize  = Int64.of_int vmsize;
    seg_fileoff = Int64.of_int fileoff;
    seg_filesize = Int64.of_int filesize;
    seg_maxprot  = maxprot;
    seg_initprot = initprot;
    seg_flags    = flags;
    seg_sections = sects;
  }

let read_section_64 header buf t =
  let sectname = fixed_0_string t 16 in
  let segname  = fixed_0_string t 16 in
  let addr     = Read.u64 t in
  let size     = Read.u64 t in
  let _offset  = Read.u32 t in
  let align    = 1 lsl Read.u32 t in
  let reloff   = Read.u32 t in
  let nreloc   = Read.u32 t in
  let relocs   =
    read_n_times (read_relocation header) (cursor buf ~at:reloff) nreloc in
  let flags     = Read.u32 t in
  let _reserved = Read.u32 t in
  let _reserved = Read.u32 t in
  let _reserved = Read.u32 t in
  let sec_type   = sec_type flags in
  let user_attrs = sec_user_attr flags in
  let sys_attrs   = sec_sys_attr flags in
  {
    sec_sectname   = sectname;
    sec_segname    = segname;
    sec_addr       = addr;
    sec_size       = size;
    sec_align      = align;
    sec_relocs     = relocs;
    sec_type       = sec_type;
    sec_user_attrs = user_attrs;
    sec_sys_attrs  = sys_attrs;
  }

let read_segment_64 header buf t =
  let segname = fixed_0_string t 16 in
  let vmaddr   = Read.u64 t in
  let vmsize   = Read.u64 t in
  let fileoff  = Read.u64 t in
  let filesize = Read.u64 t in
  let maxprot  = read_vm_prot t in
  let initprot = read_vm_prot t in
  let nsects   = Read.u32 t in
  let flags    = read_seg_flag t in
  let sects    = read_n_times (read_section_64 header buf) t nsects in
  {
    seg_segname = segname;
    seg_vmaddr  = vmaddr;
    seg_vmsize  = vmsize;
    seg_fileoff = fileoff;
    seg_filesize = filesize;
    seg_maxprot  = maxprot;
    seg_initprot = initprot;
    seg_flags    = flags;
    seg_sections = sects;
  }

let read_routines_command_32 t =
  let init_address = Read.u32 t in
  let init_module  = Read.u32 t in
  let _reserved1   = Read.u32 t in
  let _reserved2   = Read.u32 t in
  let _reserved3   = Read.u32 t in
  let _reserved4   = Read.u32 t in
  let _reserved5   = Read.u32 t in
  let _reserved6   = Read.u32 t in
  LC_ROUTINES_32 (init_address, init_module)

let read_routines_command_64 t =
  let init_address = Read.u64 t in
  let init_module  = Read.u64 t in
  let _reserved1   = Read.u64 t in
  let _reserved2   = Read.u64 t in
  let _reserved3   = Read.u64 t in
  let _reserved4   = Read.u64 t in
  let _reserved5   = Read.u64 t in
  let _reserved6   = Read.u64 t in
  LC_ROUTINES_64 (init_address, init_module)


let read_uuid_command t =
  LC_UUID (Read.fixed_string t 8)

let read_rpath_command buf t =
  let offset = Read.u32 t in
  match Read.zero_string (cursor buf ~at:offset) () with
  | None -> invalid_format "invalid rpath"
  | Some s -> LC_RPATH s

let read_link_edit t k =
  let dataoff  = Read.u32 t in
  let datasize = Read.u32 t in
  k dataoff datasize

let read_prebound_dylib buf t =
  let name = read_lc_string buf t in
  let nmodules = Read.u32 t in
  let modulesoff = Read.u32 t in
  let modules = read_n_times Read.u8 (cursor ~at:modulesoff buf)
      (nmodules / 8 + nmodules mod 8)
  in
  (name, modules)

let read_symbol read_value header buf t =
  let sym_name = read_symbol_name t buf in
  let sym_type = Read.u8 t in
  let stabs, sym_pext, sym_type, sym_ext = sym_types sym_type in
  let sym_sect = Read.u8 t in
  let sym_flags = Read.u16 t in
  let sym_flags = if stabs
    then `Uninterpreted sym_flags
    else `Flags (reference_flags header sym_flags)
  in
  let sym_value = read_value t in
  {
    sym_name;
    sym_type;
    sym_pext;
    sym_ext;
    sym_sect;
    sym_flags;
    sym_value;
  }

let read_symbol_table header buf t =
  let symoff  = Read.u32 t in
  let nsyms   = Read.u32 t in
  let stroff  = Read.u32 t in
  let strsize = Read.u32 t in
  Printf.eprintf "symoff: %d, nsyms: %d, stroff: %d, strsize: %d\n"
    symoff nsyms stroff strsize;
  Printf.eprintf "buffer size: %d\n%!"
    (Bigarray.Array1.dim buf);
  let strsect = sub (cursor buf ~at:stroff) strsize in
  let f =
    if is64bit header then Read.u64
    else (fun x -> Int64.of_int (Read.u32 x)) in
  let read_symbol = read_symbol f in
  let symcursor = cursor buf ~at:symoff in
  let symbols = read_n_times (read_symbol header strsect.buffer) symcursor nsyms in
  (symbols, strsect.buffer)

let read_load_command header buf t =
  let cmd     = Read.u32 t in
  let cmdsize = Read.u32 t in
  let t       = sub t (cmdsize - 8) in
  match cmd with
  | 0x00000001 -> LC_SEGMENT_32 (lazy (read_segment_32 header buf t))
  | 0x00000002 -> LC_SYMTAB (lazy (read_symbol_table header buf t))
  | 0x00000004 -> LC_THREAD (lazy (read_thread t))
  | 0x00000005 -> LC_UNIXTHREAD (lazy (read_thread t))
  | 0x0000000b -> LC_DYSYMTAB (lazy (read_dynamic_symbol_table header t buf))
  | 0x0000000e -> LC_LOAD_DYLINKER (read_lc_string t.buffer t)
  | 0x0000000f -> LC_ID_DYLINKER (read_lc_string t.buffer t)
  | 0x00000010 -> LC_PREBOUND_DYLIB (lazy (read_prebound_dylib t.buffer t))
  | 0x00000011 -> read_routines_command_32 t
  | 0x00000012 -> LC_SUB_FRAMEWORK (read_lc_string t.buffer t)
  | 0x00000013 -> LC_SUB_UMBRELLA  (read_lc_string t.buffer t)
  | 0x00000014 -> LC_SUB_CLIENT    (read_lc_string t.buffer t)
  | 0x00000015 -> LC_SUB_LIBRARY   (read_lc_string t.buffer t)
  | 0x00000016 -> LC_TWOLEVEL_HINTS (lazy (read_twolevelhints t.buffer t))
  | 0x00000017 -> LC_PREBIND_CKSUM (Read.u32 t)
  | 0x00000019 -> LC_SEGMENT_64 (lazy (read_segment_64 header buf t))
  | 0x0000001a -> read_routines_command_64 t
  | 0x0000001b -> read_uuid_command t
  | 0x0000001d -> read_link_edit t (fun a b -> LC_CODE_SIGNATURE (a,b))
  | 0x0000001e -> read_link_edit t (fun a b -> LC_SEGMENT_SPLIT_INFO (a,b))
  | 0x0000000c -> LC_LOAD_DYLIB (lazy (read_dylib_command t t.buffer))
  | 0x0000000d -> LC_ID_DYLIB (lazy (read_dylib_command t t.buffer))
  | 0x80000018 -> LC_LOAD_WEAK_DYLIB (lazy (read_dylib_command t t.buffer))
  | 0x8000001c -> read_rpath_command buf t
  | n -> LC_UNHANDLED (n, t.buffer)

let rec read_load_commands header buf t =
  if at_end t then []
  else
    let lc = read_load_command header buf t in
    lc :: read_load_commands header buf t

let read buf =
  let t = cursor buf in
  let size_of_commands, header = read_header t in
  let t = sub t size_of_commands in
  let commands = read_load_commands header buf t  in
  (header, commands)

let section_body buffer seg sec =
  let addr = Int64.add seg.seg_fileoff sec.sec_addr in
  Bigarray.Array1.sub buffer  (Int64.to_int addr) (Int64.to_int sec.sec_size)
