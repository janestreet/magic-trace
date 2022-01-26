open! Core
open! Async

(*$
  open Magic_trace_lib_cinaps_helpers.Trace_decoding_interop;;

  gen_ocaml_record ~for_sig:true trace_meta;;
  gen_ocaml_record ~for_sig:true mmap;;
  gen_ocaml_record ~for_sig:true setup_info
*)
module Trace_meta : sig
  type t =
    { mutable time_shift : int
    ; mutable time_mult : int
    ; mutable time_zero : int
    ; mutable max_nonturbo_ratio : int
    }
  [@@deriving sexp]
end

module Mmap : sig
  type t =
    { mutable vaddr : int
    ; mutable length : int
    ; mutable offset : int
    ; mutable filename : string
    }
  [@@deriving sexp]
end

module Setup_info : sig
  type t =
    { mutable initial_maps : Mmap.t list
    ; mutable trace_meta : Trace_meta.t
    ; mutable pid : int
    }
  [@@deriving sexp]
end
(*$*)

module Tracing_state : sig
  type t

  val attach
    :  ?data_size:int
    -> ?aux_size:int
    -> ?filter:string
    -> pt_file:Filename.t
    -> sideband_file:Filename.t
    -> setup_file:Filename.t
    -> Pid.t
    -> t Or_error.t

  val take_snapshot : t -> unit Or_error.t
  val destroy : t -> unit
end
