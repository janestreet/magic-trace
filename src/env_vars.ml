open! Core
open Async

(* Points to a filesystem path will a copy of Perfetto. If provided, magic-trace will automatically
  start a local HTTP server for you to view the trace. You can use this "hidden" feature to serve
  a local copy of Perfetto if you don't want to copy trace files around. *)
let perfetto_ui_base_directory = Unix.getenv "MAGIC_TRACE_PERFETTO_DIR"

(* Points to a filesystem path that will be invoked with a trace filename to implement
   [-share]. *)
let share_command_filename = Unix.getenv "MAGIC_TRACE_SHARE_COMMAND"

(* Turns on hidden command line options. These options are to help magic-trace developers debug
   magic-trace, they're not generally useful. *)
let enable_debug_options = Option.is_some (Unix.getenv "MAGIC_TRACE_DEBUG")
