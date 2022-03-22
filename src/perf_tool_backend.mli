(** A backend that uses the [perf] command line tool for recording and decoding *)
open! Import

include Backend_intf.S

val create_decode_opts : perf_data_filename:string -> decode_opts
