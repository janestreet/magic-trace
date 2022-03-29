(* Form codes are types for DWARF operators. In the spec, they all start with [DW_FORM_]. *)
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

(* [read cursor] reads a form code out of an Owee_buf, and advance the buffer past it. *)
val read : Owee_buf.cursor -> t

val of_int_exn : int -> t

(* Moves the given cursor past data of type [t]. *)
val skip : t -> Owee_buf.cursor -> is_64bit:bool -> address_size:int -> unit
