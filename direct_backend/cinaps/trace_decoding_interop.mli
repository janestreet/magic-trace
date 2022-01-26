open! Core

type enum := string list * string
type record := (string * string) list * string

val event_kinds : enum
val decode_result : enum
val event_packet : record
val add_section_packet : record
val decoding_config : record
val recording_config : record
val mmap : record
val setup_info : record
val trace_meta : record
val gen_ocaml_enum : enum -> unit
val gen_ocaml_record : ?for_sig:bool -> record -> unit
val gen_c_enum : enum -> unit
val gen_c_record_enum : record -> unit
