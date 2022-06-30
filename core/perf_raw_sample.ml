open! Core

module Address_location = struct
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
