open! Core
open! Magic_trace_core

(* Runs some perf script end-to-end through the perf_tool_backend and the trace_writer, printing
   out generated traces as a string.

   To generate these scripts, run magic-trace with a working directory (say, /tmp/wd). Then, run:

   $ perf script -i /tmp/wd/perf.data/data --ns --itrace=b -F pid,tid,time,flags,ip,addr,sym,symoff

   and save that output to a file in test/. See hello_world_with_kernel_tracing.ml for an example
   of turning that saved perf output into an expect test that you can play around with.

   If you're trying to demonstrate a bug, reduce your perf output to just the problematic section.
   It's hard to keep people engaged when reading diffs of massive tests. *)
val run : ?debug:bool -> trace_mode:Trace_mode.t -> Filename.t -> unit
