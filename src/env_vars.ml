open! Core
open Async

(* Points to a filesystem path with a copy of Perfetto. If provided, magic-trace will
   automatically start a local HTTP server for you to view the trace. You can use this
   "hidden" feature to serve a local copy of Perfetto if you don't want to copy trace
   files around. *)
let perfetto_dir = Unix.getenv "MAGIC_TRACE_PERFETTO_DIR"

(* Whether [perf] should be considered privileged when running as not-root. Bypasses error
   checks around kernel tracing when not root. *)
let perf_is_privileged = Option.is_some (Unix.getenv "MAGIC_TRACE_PERF_IS_PRIVILEGED")

(* Turns on hidden command line options and attached "[inferred start time]" to functions
   with inferred start times.

   This helps magic-trace developers debug magic-trace, it's not generally useful. *)
let debug = Option.is_some (Unix.getenv "MAGIC_TRACE_DEBUG")

(* When tracing the kernel on certain systems, perf only has root access when
   being run with a specific set of flags. Since this does not include
   [--dlfilter], this environment variable allows the user to forcibly disable
   filtering. *)
let no_dlfilter = Option.is_some (Unix.getenv "MAGIC_TRACE_NO_DLFILTER")

(* Points to a filesystem path with a trace processor executable. 
   If provided, the flag can be indicated to automatically run the processor 
   at the path once the trace file is created *)
let processor_path = Unix.getenv "MAGIC_TRACE_PROCESSOR_SHELL_PATH"
