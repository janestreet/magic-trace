open Owee_buf

type magic =
  | MAGIC32
  | MAGIC64
  | CIGAM32
  | CIGAM64

val string_of_magic : magic -> string

type unknown = [ `Unknown of int ]

type cpu_type = [
  | `X86
  | `X86_64
  | `ARM
  | `POWERPC
  | `POWERPC64
  | unknown
]

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
  magic : magic;
  cpu_type : cpu_type;
  cpu_subtype : cpu_subtype;
  file_type : file_type;
  flags : header_flag list;
}

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

type scattered_relocation_info = {
  rs_pcrel   : bool;   (*  indicates if the item to be relocated is part of an instruction containing PC-relative addressing *)
  rs_length  : u32; (*  length of item containing address to be relocated (literal form (4) instead of power of two (2)) *)
  rs_type    : reloc_type; (*  relocation type *)
  rs_address : u32; (*  offset from start of section to place to be relocated *)
  rs_value   : s32;  (*  address of the relocatable expression for the item in the file that needs to be updated if the address is changed *)
}

type relocation = [
  | `Relocation_info of relocation_info
  | `Scattered_relocation_info of scattered_relocation_info
]

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

type sec_sys_attr = [
  (* section contains soem machine instructions *)
  | `SOME_INSTRUCTIONS
  (* section has external relocation entries *)
  | `EXT_RELOC
  (* section has local relocation entries *)
  | `LOC_RELOC
]

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

type seg_flag = [
  | `HIGHVM  (* The file contents for this segment is for the high part of the VM space, the low part is zero filled (for stacks in core files). *)
  | `NORELOC (* This segment has nothing that was relocated in it and nothing relocated to it, that is it may be safely replaced without relocation. *)
]

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

val read : Owee_buf.t -> header * command list

val section_body : Owee_buf.t -> segment -> section -> Owee_buf.t
