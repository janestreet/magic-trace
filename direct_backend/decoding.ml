open! Core
open! Import

module Generated_interop = struct
  (*$
    open Magic_trace_lib_cinaps_helpers.Trace_decoding_interop;;

    gen_ocaml_enum event_kinds;;
    gen_ocaml_enum decode_result;;
    gen_ocaml_record event_packet;;
    gen_ocaml_record add_section_packet;;
    gen_ocaml_record decoding_config
  *)
  module Event_kind = struct
    type t =
      | Other
      | Call
      | Ret
      | Start_trace
      | End_trace
      | End_trace_syscall
      | Install_handler
      | Raise_exception
      | Decode_error
      | Jump
    [@@deriving sexp]
  end

  module Decode_result = struct
    type t =
      | End_of_trace
      | Event
      | Add_section
    [@@deriving sexp]
  end

  module Event = struct
    type t =
      { mutable pid : int
      ; mutable tid : int
      ; mutable kind : Event_kind.t
      ; mutable addr : int
      ; mutable time : int
      ; mutable isid : int
      ; mutable symbol_begin : int
      ; mutable symbol_end : int
      }
    [@@deriving sexp]
  end

  module Add_section = struct
    type t =
      { mutable filename : string
      ; mutable offset : int
      ; mutable size : int
      ; mutable vaddr : int
      ; mutable isid : int
      }
    [@@deriving sexp]
  end

  module Config = struct
    type t =
      { mutable sideband_filename : string
      ; mutable pt_data_fd : int
      ; mutable setup_info : Manual_perf.Setup_info.t
      }
    [@@deriving sexp]
  end
  (*$*)
end

module Stub = struct
  include Generated_interop

  (* In event, [symbol_{begin,end}] are set by OCaml and used by C to check if a jump
     remained in the same symbol, so we don't have to look up symbols after every jump. *)

  let blank_event () : Event.t =
    { pid = 1
    ; tid = 1
    ; kind = Event_kind.Other
    ; addr = 0
    ; time = 0
    ; isid = 0
    ; symbol_begin = 0
    ; symbol_end = 0
    }
  ;;

  let blank_add_section () : Add_section.t =
    { filename = ""; offset = 0; size = 0; vaddr = 0; isid = 0 }
  ;;

  type c_decoding_state

  external init_decoder : Config.t -> c_decoding_state = "magic_pt_init_decoder_stub"

  external run_decoder
    :  c_decoding_state
    -> Event.t
    -> Add_section.t
    -> Decode_result.t
    = "magic_pt_run_decoder_stub"
end

type state =
  { elfs_by_filename : Elf.t Filename.Table.t
  ; resolver_by_isid : Elf.Symbol_resolver.t Int.Table.t
  ; mutable fallback_resolvers : (int * int * Elf.Symbol_resolver.t) list
  }

let handle_add_section (state : state) (add : Stub.Add_section.t) =
  (* Core.print_s [%message "handle_add_section" (add : Stub.Add_section.t)]; *)
  let elf =
    match Hashtbl.find state.elfs_by_filename add.filename with
    | Some elf -> Some elf
    | None ->
      (match Elf.create add.filename with
       | None -> None
       | Some elf ->
         Hashtbl.add_exn state.elfs_by_filename ~key:add.filename ~data:elf;
         Some elf)
  in
  match elf with
  | None -> ()
  | Some elf ->
    let resolver : Elf.Symbol_resolver.t =
      { elf; file_offset = add.offset; loaded_offset = add.vaddr }
    in
    state.fallback_resolvers
      <- (add.vaddr, add.size, resolver) :: state.fallback_resolvers;
    Hashtbl.add_exn state.resolver_by_isid ~key:add.isid ~data:resolver
;;

let convert_trace_event state (event : Stub.Event.t) =
  let resolved : Elf.Symbol_resolver.resolved =
    let resolver =
      match Hashtbl.find state.resolver_by_isid event.isid with
      | Some resolver -> Some resolver
      | None ->
        (* Tracing start/stop events don't have an isid so we need a fallback *)
        List.find state.fallback_resolvers ~f:(fun (vaddr, size, _) ->
          event.addr > vaddr && event.addr < vaddr + size)
        |> Option.map ~f:(fun (_, _, r) -> r)
    in
    match resolver with
    | None -> { name = "[unknown section]"; start_addr = 0; end_addr = 0 }
    | Some resolver ->
      Elf.Symbol_resolver.resolve resolver event.addr
      |> Option.value ~default:{ name = "[unknown symbol]"; start_addr = 0; end_addr = 0 }
  in
  event.symbol_begin <- resolved.start_addr;
  event.symbol_end <- resolved.end_addr;
  let symbol = resolved.name in
  (* print_s [%message (event : Stub.Event.t) (symbol : string)]; *)
  let thread : Backend_intf.Event.Thread.t =
    { pid = Pid.of_int event.pid; tid = event.tid }
  in
  let time = Time_ns.Span.of_int_ns event.time in
  let addr = event.addr in
  let kind =
    match event.kind with
    | Generated_interop.Event_kind.Other -> Backend_intf.Event.Unknown
    | Call -> Call
    | Ret -> Return
    | Start_trace -> Start
    | End_trace -> End None
    | End_trace_syscall -> End Syscall
    | Install_handler -> Other "Install_handler"
    | Raise_exception -> Other "Raise_exception"
    | Jump -> Jump
    | Decode_error -> Decode_error
  in
  let offset = event.addr - resolved.start_addr in
  { Backend_intf.Event.thread
  ; time
  ; addr
  ; kind
  ; symbol
  ; offset
  ; ip
  ; ip_symbol
  ; ip_offset
  }
;;

type t =
  { state : state
  ; decoder : Stub.c_decoding_state
  ; event : Stub.Event.t
  ; add_section : Stub.Add_section.t
  }

let create ~pt_file ~sideband_file ~setup_file =
  let setup_info =
    In_channel.read_all setup_file
    |> Sexp.of_string
    |> [%of_sexp: Manual_perf.Setup_info.t]
  in
  (* print_s [%sexp (setup_info : Manual_perf.Setup_info.t)]; *)
  let%bind.With pt_data_fd f = Core_unix.with_file pt_file ~mode:[ O_RDONLY ] ~f in
  let config : Stub.Config.t =
    { sideband_filename = sideband_file
    ; pt_data_fd = Core_unix.File_descr.to_int pt_data_fd
    ; setup_info
    }
  in
  let state =
    { elfs_by_filename = Filename.Table.create ()
    ; resolver_by_isid = Int.Table.create ()
    ; fallback_resolvers = []
    }
  in
  let event = Stub.blank_event () in
  let add_section = Stub.blank_add_section () in
  let decoder = Stub.init_decoder config in
  { state; decoder; event; add_section }
;;

let rec decode_one t =
  match Stub.run_decoder t.decoder t.event t.add_section with
  | End_of_trace -> None
  | Event -> Some (convert_trace_event t.state t.event)
  | Add_section ->
    handle_add_section t.state t.add_section;
    decode_one t
;;
