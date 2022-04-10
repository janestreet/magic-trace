open! Core
open! Import

(* Debounces `tr strt` and `tr end` transitions in perf's output. We need this because when perf
   outputs (for example) two `tr strt` transitions in a row, magic-trace needs to disbelieve the
   second one when constructing stack frames. 

   We suspect, but are not sure, that the root cause of those duplicate transitions are Intel PT
   bugs. See https://github.com/janestreet/magic-trace/issues/134 for more details. *)

type t [@@deriving sexp_of]

val create : unit -> t

val process_trace_state_change
  :  t
  -> Event.Trace_state_change.t option
  -> Event.Trace_state_change.t option
