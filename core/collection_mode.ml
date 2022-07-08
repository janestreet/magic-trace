open! Core

type t =
  | Intel_processor_trace
  | Stacktrace_sampling

let select_collection_mode ~use_sampling =
  match use_sampling with
  | true -> Stacktrace_sampling
  | false ->
    (match Core_unix.access "/sys/bus/event_source/devices/intel_pt" [ `Exists ] with
    | Ok () -> Intel_processor_trace
    | Error _ ->
      Core.printf
        "Intel PT support not found. magic-trace will continue and use sampling instead.";
      Stacktrace_sampling)
;;

let param =
  Command.Param.(
    flag
      "-sampling"
      no_arg
      ~doc:
        "Use stacktrace sampling instead of Intel PT. If Intel PT is not available, \
         magic-trace will default to this. For more info: https://magic-trace.org/w/b"
    |> map ~f:(fun use_sampling -> select_collection_mode ~use_sampling))
;;
