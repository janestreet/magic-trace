open! Core

let[@inline] int_fits_in_int32 x = x < 1 lsl 31 && x >= -(1 lsl 31)

let[@inline] int64_fits_in_int32 x =
  Int64.(x < shift_left 1L 31 && x >= -shift_left 1L 31)
;;
