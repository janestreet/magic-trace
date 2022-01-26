(* -*- mode: tuareg -*- *)

open! Core

let p x = print_string [%string "\n%{x}\n"]

let event_kinds =
  ( [ "other"
    ; "call"
    ; "ret"
    ; "start_trace"
    ; "end_trace"
    ; "end_trace_syscall"
    ; "install_handler"
    ; "raise_exception"
    ; "decode_error"
    ; "jump"
    ]
  , "event_kind" )
;;

let decode_result = [ "end_of_trace"; "event"; "add_section" ], "decode_result"

let gen_ocaml_enum (enum, name) =
  let body =
    List.map enum ~f:(fun n -> [%string "| %{String.capitalize n}"])
    |> String.concat ~sep:" "
  in
  p
    [%string
      {|module %{String.capitalize name} = 
          struct type t = %{body} 
          [@@deriving sexp]
       end|}]
;;

let gen_c_enum (enum, name) =
  let body =
    List.mapi enum ~f:(fun i n -> [%string "\t%{name}_%{n} = %{i#Int},\n"])
    |> String.concat
  in
  p [%string "enum %{name} {\n  %{name}_none = -1,\n%{body}\t};"]
;;

let event_packet =
  ( [ "pid", "int"
    ; "tid", "int"
    ; "kind", "Event_kind.t"
    ; "addr", "int"
    ; "time", "int"
    ; "isid", "int"
    ; "symbol_begin", "int"
    ; "symbol_end", "int"
    ]
  , "event" )
;;

let add_section_packet =
  ( [ "filename", "string"; "offset", "int"; "size", "int"; "vaddr", "int"; "isid", "int" ]
  , "add_section" )
;;

let decoding_config =
  ( [ "sideband_filename", "string"
    ; "pt_data_fd", "int"
    ; "setup_info", "Manual_perf.Setup_info.t"
    ]
  , "config" )
;;

let mmap =
  [ "vaddr", "int"; "length", "int"; "offset", "int"; "filename", "string" ], "mmap"
;;

let setup_info =
  ( [ "initial_maps", "Mmap.t list"; "trace_meta", "Trace_meta.t"; "pid", "int" ]
  , "setup_info" )
;;

let recording_config =
  ( [ "pid", "int"
    ; "data_size", "int"
    ; "aux_size", "int"
    ; "filter", "string option"
    ; "pt_fd", "int"
    ; "sb_fd", "int"
    ]
  , "recording_config" )
;;

let trace_meta =
  ( [ "time_shift", "int"
    ; "time_mult", "int"
    ; "time_zero", "int"
    ; "max_nonturbo_ratio", "int"
    ]
  , "trace_meta" )
;;

let gen_ocaml_record ?(for_sig = false) (pkt, name) =
  let body =
    List.map pkt ~f:(fun (f, t) -> [%string "mutable %{f} : %{t}"])
    |> String.concat ~sep:"; "
  in
  let joiner = if for_sig then ": sig" else "= struct" in
  p
    [%string
      {|module %{String.capitalize name} %{joiner} 
          type t = { %{body} } [@@deriving sexp] 
        end|}]
;;

let gen_c_record_enum (pkt, name) =
  let body =
    List.map pkt ~f:(fun (f, t) -> [%string "\t%{name}_field_%{f} /* %{t} */,\n"])
    |> String.concat
  in
  p [%string "enum %{name}_field {\n%{body}\t};"]
;;
