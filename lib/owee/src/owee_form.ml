open Owee_buf

type t =
  [ `addr
  | `block2
  | `block4
  | `data2
  | `data4
  | `data8
  | `string
  | `block
  | `block1
  | `data1
  | `flag
  | `sdata
  | `strp
  | `udata
  | `ref_addr
  | `ref1
  | `ref2
  | `ref4
  | `ref8
  | `ref_udata
  | `indirect
  | `sec_offset
  | `exprloc
  | `flag_present
  | `strx
  | `addrx
  | `ref_sup4
  | `strp_sup
  | `data16
  | `line_strp
  | `ref_sig8
  | `implicit_const
  | `loclistx
  | `rnglistx
  | `ref_sup8
  | `strx1
  | `strx2
  | `strx3
  | `strx4
  | `addrx1
  | `addrx2
  | `addrx3
  | `addrx4
  ]

let of_int_exn = function
  | 0x01 -> `addr
  | 0x03 -> `block2
  | 0x04 -> `block4
  | 0x05 -> `data2
  | 0x06 -> `data4
  | 0x07 -> `data8
  | 0x08 -> `string
  | 0x09 -> `block
  | 0x0a -> `block1
  | 0x0b -> `data1
  | 0x0c -> `flag
  | 0x0d -> `sdata
  | 0x0e -> `strp
  | 0x0f -> `udata
  | 0x10 -> `ref_addr
  | 0x11 -> `ref1
  | 0x12 -> `ref2
  | 0x13 -> `ref4
  | 0x14 -> `ref8
  | 0x15 -> `ref_udata
  | 0x16 -> `indirect
  | 0x17 -> `sec_offset
  | 0x18 -> `exprloc
  | 0x19 -> `flag_present
  | 0x1a -> `strx
  | 0x1b -> `addrx
  | 0x1c -> `ref_sup4
  | 0x1d -> `strp_sup
  | 0x1e -> `data16
  | 0x1f -> `line_strp
  | 0x20 -> `ref_sig8
  | 0x21 -> `implicit_const
  | 0x22 -> `loclistx
  | 0x23 -> `rnglistx
  | 0x24 -> `ref_sup8
  | 0x25 -> `strx1
  | 0x26 -> `strx2
  | 0x27 -> `strx3
  | 0x28 -> `strx4
  | 0x29 -> `addrx1
  | 0x2a -> `addrx2
  | 0x2b -> `addrx3
  | 0x2c -> `addrx4
  | _    -> failwith "invalid form code"

let read cursor =
  of_int_exn (Read.uleb128 cursor)

let rec skip t cursor ~is_64bit ~address_size =
  match t with
  | ( `flag_present
    | `implicit_const
    | `flag
    | `data1
    | `ref1
    | `strx1
    | `addrx1
    | `data2
    | `ref2
    | `strx2
    | `addrx2
    | `strx3
    | `addrx3
    | `data4
    | `ref4
    | `ref_sup4
    | `strx4
    | `addrx4
    | `data8
    | `ref8
    | `ref_sig8
    | `ref_sup8
    | `data16
    | `addr
    | `strp
    | `line_strp
    | `sec_offset
    | `strp_sup
    | `ref_addr
    | `exprloc
    | `block
    | `block1
    | `block2
    | `block4
    ) as form ->
    let size =
      match form with
      | `flag_present
      | `implicit_const
        -> 0
      | `flag
      | `data1
      | `ref1
      | `strx1
      | `addrx1
        -> 1
      | `data2
      | `ref2
      | `strx2
      | `addrx2
        -> 2
      | `strx3
      | `addrx3
        -> 3
      | `data4
      | `ref4
      | `ref_sup4
      | `strx4
      | `addrx4
        -> 4
      | `data8
      | `ref8
      | `ref_sig8
      | `ref_sup8
        -> 8
      | `data16
        -> 16
      | `addr
        -> address_size
      | `strp
      | `line_strp
      | `sec_offset
      | `strp_sup
      | `ref_addr
        -> if is_64bit then 8 else 4
      | `exprloc
      | `block
        -> Read.uleb128 cursor
      | `block1
        -> Read.u8 cursor
      | `block2
        -> Read.u16 cursor
      | `block4
        -> Read.u32 cursor
    in
    advance cursor size
  | `string ->
    ignore (Read.zero_string cursor () : string option)
  | `sdata ->
    ignore (Read.sleb128 cursor : s128)
  | `udata
  | `ref_udata
  | `strx
  | `addrx
  | `loclistx
  | `rnglistx ->
    ignore (Read.uleb128 cursor : u128)
  | `indirect ->
    let t = of_int_exn (Read.uleb128 cursor) in
    skip t cursor ~is_64bit ~address_size
