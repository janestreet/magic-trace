open! Core
open! Import
open Trace_writer_intf

(* Creates an abstract [S_trace] out of a real [Tracing] backend. I know this isn't a great reason,
   but this function is in its own file because returning a module breaks syntax highlighting in
   vscode. *)
val create : Tracing.Trace.t -> (module S_trace with type thread = Tracing.Trace.Thread.t)
