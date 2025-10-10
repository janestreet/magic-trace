open! Core
open Async

(* Points to a filesystem path will a copy of Perfetto. If provided, magic-trace will
   automatically start a local HTTP server for you to view the trace. You can use this
   "hidden" feature to serve a local copy of Perfetto if you don't want to copy trace
   files around. *)
let perfetto_dir = Unix.getenv "MAGIC_TRACE_PERFETTO_DIR"

(* Documentation string for [-share] *)
let share_doc = Unix.getenv "MAGIC_TRACE_SHARE_DOC"

(* Points to a filesystem path that will be invoked with a trace filename to implement
   [-share]. *)
let share_command_filename = Unix.getenv "MAGIC_TRACE_SHARE_COMMAND"

(* Override which [perf] to use. If this isn't set, magic-trace will use whatever's first
   in $PATH. *)
let perf_path = Option.value ~default:"perf" (Unix.getenv "MAGIC_TRACE_PERF_PATH")

(* Whether [perf] should be considered privileged when running as not-root. Bypasses error
   checks around kernel tracing when not root. *)
let perf_is_privileged = Option.is_some (Unix.getenv "MAGIC_TRACE_PERF_IS_PRIVILEGED")

(* Override whether kcore will be used (in the case that [perf] supports it at all). *)
let perf_no_kcore = Option.is_some (Unix.getenv "MAGIC_TRACE_PERF_NO_KCORE")

(* Turns on hidden command line options and attached "[inferred start time]" to functions
   with inferred start times.

   This helps magic-trace developers debug magic-trace, it's not generally useful. *)
let debug = Option.is_some (Unix.getenv "MAGIC_TRACE_DEBUG")

(* Turns on hidden command line options which are considered experimental
   features of magic-trace. *)
let experimental = Option.is_some (Unix.getenv "MAGIC_TRACE_EXPERIMENTAL")

(* When tracing the kernel on certain systems, perf only has root access when
   being run with a specific set of flags. Since this does not include
   [--dlfilter], this environment variable allows the user to forcibly disable
   filtering. *)
let no_dlfilter = Option.is_some (Unix.getenv "MAGIC_TRACE_NO_DLFILTER")

(* Demangle symbols in the fuzzy finder. This is currently slow on large binaries, so is
   disabled by default. *)
let fzf_demangle_symbols = Option.is_some (Unix.getenv "MAGIC_TRACE_FZF_DEMANGLE_SYMBOLS")

(* Use old-style trace generation for exceptions in all cases. *)
let no_ocaml_exception_debug_info =
  Option.is_some (Unix.getenv "MAGIC_TRACE_NO_OCAML_EXCEPTION_DEBUG_INFO")
;;

(* Skip any special case transaction handling, intended for debugging tx/tx_abrt. *)
let skip_transaction_handling =
  Option.is_some (Unix.getenv "MAGIC_TRACE_SKIP_TX_HANDLING")
;;
