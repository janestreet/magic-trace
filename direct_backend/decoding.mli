open! Core
open! Import

type t

val create : pt_file:Filename.t -> sideband_file:Filename.t -> setup_file:Filename.t -> t
val decode_one : t -> Backend_intf.Event.t option
