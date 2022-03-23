open! Core

let[@inline] int_fits_in_int32 x = x < 1 lsl 31 && x >= -(1 lsl 31)
