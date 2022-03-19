open! Core
open! Async

(* JITed lanaguages like java and javascript can write perf map files which provide a mapping of
   address to symbol name.
   
   They're documented here:

   https://github.com/torvalds/linux/blob/master/tools/perf/Documentation/jit-interface.txt

   Like perf, magic-trace will automatically detect and load these maps, if available, and use them
   for symbol resolution. *)
type t

val default_filename : pid:Pid.t -> Filename.t

(* Returns `None` if there is no perf-map file in /tmp. *)
val load : Filename.t -> t option Deferred.t

(* Looks up an address, returning the function that address is for. Returns `None` if that address
   is not in the perf-map file. *)
val symbol : t -> addr:int64 -> Perf_map_location.t option
