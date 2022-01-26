open! Core

module Location = struct
  type t =
    { filename : string option
    ; line : int
    ; col : int
    }
  [@@deriving sexp]
end

module Addr_table = struct
  type t = Location.t Int.Table.t
end

module Stop_info = struct
  type t =
    { name : string
    ; addr : int64
    ; filter : string
    }
end
