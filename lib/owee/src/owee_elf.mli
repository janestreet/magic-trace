open Owee_buf

(** Minimalist ELF 64 decoder *)

type identification = {
  elf_class      : u8;
  elf_data       : u8;
  elf_version    : u8;
  elf_osabi      : u8;
  elf_abiversion : u8;
}

type header = {
  e_ident     : identification;
  e_type      : u16;
  e_machine   : u16;
  e_version   : u32;
  e_entry     : u64;
  e_phoff     : u64;
  e_shoff     : u64;
  e_flags     : u32;
  e_ehsize    : u16;
  e_phentsize : u16;
  e_phnum     : u16;
  e_shentsize : u16;
  e_shnum     : u16;
  e_shstrndx  : u16;
}

type section = {
  sh_name      : u32;
  sh_type      : u32;
  sh_flags     : u64;
  sh_addr      : u64;
  sh_offset    : u64;
  sh_size      : u64;
  sh_link      : u32;
  sh_info      : u32;
  sh_addralign : u64;
  sh_entsize   : u64;
  sh_name_str  : string;
}

(** From a buffer pointing to an ELF image, [read_elf] decodes the header and
    section table. *)
val read_elf : Owee_buf.t -> header * section array

(** From a buffer pointing to an ELF image, [section_body elf section] returns
    a sub-buffer with the contents of the [section] of the ELF image. *)
val section_body : Owee_buf.t -> section -> Owee_buf.t

(** Convenience function to find a section in the section table given its name. *)
val find_section : section array -> string -> section option

(** From a buffer pointing to an ELF image, find the body of a section given its name. *)
val find_section_body
   : Owee_buf.t
  -> section array
  -> section_name:string
  -> Owee_buf.t option

val debug_line_pointers
  : Owee_buf.t
  -> section array
  -> Owee_debug_line.pointers_to_other_sections

module String_table : sig
  type t

  (* CR-someday mshinwell: [index] should probably be [Int32.t] *)
  (** Extract a string from the string table at the given index. *)
  val get_string : t -> index:int -> string option
end

(** Fish out the string table from the given ELF buffer and section array. *)
val find_string_table : Owee_buf.t -> section array -> String_table.t option

module Symbol_table : sig
  (** One or more ELF symbol tables, conjoined. *)
  type t

  module Symbol : sig
    type t

    type type_attribute = private
      | Notype
      | Object
      | Func
      | Section
      | File
      | Common
      | TLS
      | GNU_ifunc
      | Other of int

    type binding_attribute = private
      | Local
      | Global
      | Weak
      | GNU_unique
      | Other of int

    type visibility = private
      | Default
      | Internal
      | Hidden
      | Protected

    val name : t -> String_table.t -> string option

    (** For avoidance of doubt, when [t] is a function symbol, [value]
        returns the address of the top of the function. *)
    val value : t -> Int64.t

    val size_in_bytes : t -> Int64.t
    val type_attribute : t -> type_attribute
    val binding_attribute : t -> binding_attribute
    val visibility : t -> visibility
    val section_header_table_index : t -> int
  end

  (** The symbols in the table whose value and size determine that they
      cover [address]. *)
  val symbols_enclosing_address
     : t
    -> address:Int64.t
    -> Symbol.t list

  (** As for [symbols_enclosing_address], but only returns function
      symbols. *)
  val functions_enclosing_address
     : t
    -> address:Int64.t
    -> Symbol.t list

  (** [iter t ~f] calls f on each symbol found in [t]. *)
  val iter : t -> f:(Symbol.t -> unit) -> unit
end

(** Fish out both the dynamic and static symbol tables (.dynsym and .symtab)
    from the given ELF buffer and section array. *)
val find_symbol_table : Owee_buf.t -> section array -> Symbol_table.t option
