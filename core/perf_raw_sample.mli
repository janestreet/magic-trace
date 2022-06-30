(** These types mirror those in [struct perf_dlfilter_sample] and others
   outputted from perf. These are constructed from C code in
   [src/perf_dlfilter/dlfilter_stubs.c] and passed to magic-trace. If you change
   this type, it is necessary to change the corresponding C code. *)

open! Core

module Address_location : sig
  type t =
    { symoff : int
    ; sym : string option
    ; dso : string option
    }
  [@@deriving bin_io, sexp]
end

type t =
  { ip : int64
  ; pid : int
  ; tid : int
  ; time : int64
  ; addr : int64
  ; period : int64
  ; cpu : int
  ; flags : int
  ; raw_size : int
  ; event : string option
  ; resolved_ip : Address_location.t option
  ; resolved_addr : Address_location.t option
  }
[@@deriving bin_io, sexp]
