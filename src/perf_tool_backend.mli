(** A backend that uses the [perf] command line tool for recording and decoding *)
include Backend_intf.S

module For_testing : sig
  val perf_args_of_collection_mode
    :  capabilities:Perf_capabilities.t
    -> timer_resolution:Timer_resolution.t
    -> trace_scope:Trace_scope.t
    -> Collection_mode.t
    -> string list Or_error.t
end
