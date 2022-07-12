open! Core
open! Import

module Generated_interop = struct
  [@@@disable_unused_warnings]

  (*$
    open Magic_trace_lib_cinaps_helpers.Trace_decoding_interop;;

    gen_ocaml_record recording_config;;
    gen_ocaml_record trace_meta;;
    gen_ocaml_record mmap;;
    gen_ocaml_record setup_info
  *)
  module Recording_config = struct
    type t =
      { mutable pid : int
      ; mutable data_size : int
      ; mutable aux_size : int
      ; mutable filter : string option
      ; mutable pt_fd : int
      ; mutable sb_fd : int
      }
    [@@deriving sexp]
  end

  module Trace_meta = struct
    type t =
      { mutable time_shift : int
      ; mutable time_mult : int
      ; mutable time_zero : int
      ; mutable max_nonturbo_ratio : int
      }
    [@@deriving sexp]
  end

  module Mmap = struct
    type t =
      { mutable vaddr : int
      ; mutable length : int
      ; mutable offset : int
      ; mutable filename : string
      }
    [@@deriving sexp]
  end

  module Setup_info = struct
    type t =
      { mutable initial_maps : Mmap.t list
      ; mutable trace_meta : Trace_meta.t
      ; mutable pid : int
      }
    [@@deriving sexp]
  end
  (*$*)
end

module Stub = struct
  include Generated_interop

  type c_tracing_state

  external create_empty_state
    :  unit
    -> c_tracing_state
    = "magic_recording_create_state_stub"

  external take_snapshot : c_tracing_state -> int = "magic_recording_take_snapshot_stub"

  external destroy_tracing_state
    :  c_tracing_state
    -> unit
    = "magic_recording_destroy_stub"

  external attach
    :  c_tracing_state
    -> Recording_config.t
    -> Trace_meta.t
    -> int
    = "magic_recording_attach_stub"
end

module Mmap = Stub.Mmap
module Trace_meta = Stub.Trace_meta
module Setup_info = Stub.Setup_info

let read_current_maps pid =
  Owee_linux_maps.scan_pid (Pid.to_int pid)
  |> List.filter_map
       ~f:(fun { address_start; address_end; pathname; offset; perm_execute; _ } ->
       match perm_execute with
       | false -> None
       | true ->
         let open Int64 in
         Some
           { Mmap.vaddr = to_int_exn address_start
           ; length = address_end - address_start |> to_int_exn
           ; offset = to_int_exn offset
           ; filename = pathname
           })
;;

module Tracing_state = struct
  type t = Stub.c_tracing_state

  let attach
    ?(data_size = 0x400000)
    ?(aux_size = 0x400000)
    ?filter
    ~pt_file
    ~sideband_file
    ~setup_file
    pid
    =
    let state = Stub.create_empty_state () in
    let trace_meta : Stub.Trace_meta.t =
      { time_shift = 0; time_mult = 0; time_zero = 0; max_nonturbo_ratio = 0 }
    in
    let open_fd name =
      Core_unix.openfile ~mode:[ O_RDWR; O_CREAT; O_TRUNC ] name
      |> Core_unix.File_descr.to_int
    in
    let pt_fd = open_fd pt_file in
    let sb_fd = open_fd sideband_file in
    let config : Stub.Recording_config.t =
      { pid = Pid.to_int pid; data_size; aux_size; filter; pt_fd; sb_fd }
    in
    let%map.Result () = Stub.attach state config trace_meta |> Errno.to_result in
    Out_channel.write_all
      setup_file
      ~data:
        ([%sexp
           ({ initial_maps = read_current_maps pid; trace_meta; pid = Pid.to_int pid }
             : Setup_info.t)]
        |> Sexp.to_string);
    state
  ;;

  let destroy t = Stub.destroy_tracing_state t
  let take_snapshot t = Stub.take_snapshot t |> Errno.to_result
end
