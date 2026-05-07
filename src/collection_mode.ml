open! Core

module Event = struct
  module Name = struct
    type t =
      | Branch_misses
      | Cache_misses
    [@@deriving compare, hash, sexp, bin_io]

    let to_string = function
      | Branch_misses -> "branch-misses"
      | Cache_misses -> "cache-misses"
    ;;
  end

  module When_to_sample = struct
    type t =
      | Frequency of int
      | Period of int
    [@@deriving of_sexp]
  end

  module Precision = struct
    type t =
      | Arbitrary_skid
      | Constant_skid
      | Request_zero_skid
      | Zero_skid
      | Maximum_possible
    [@@deriving of_sexp]
  end

  type t =
    { when_to_sample : When_to_sample.t
    ; name : Name.t
    ; precision : Precision.t
    }
  [@@deriving of_sexp]

  let of_string = function
    | "branch-misses" ->
      { when_to_sample = Period 50; name = Branch_misses; precision = Maximum_possible }
    | "cache-misses" ->
      { when_to_sample = Period 1; name = Cache_misses; precision = Maximum_possible }
    | str -> t_of_sexp (Sexp.of_string str)
  ;;

  let arg_type = Command.Arg_type.create of_string
end

type t =
  | Intel_processor_trace of { extra_events : Event.t list }
  | Stacktrace_sampling of { extra_events : Event.t list }

let extra_events = function
  | Intel_processor_trace { extra_events } | Stacktrace_sampling { extra_events } ->
    extra_events
;;

let hardware_trace_device_path () =
  let candidates =
    [ "/sys/bus/event_source/devices/intel_pt"; "/sys/bus/event_source/devices/cs_etm" ]
  in
  List.find candidates ~f:(fun path ->
    match Core_unix.access path [ `Exists ] with
    | Ok () -> true
    | Error _ -> false)
;;

let select_collection_mode ~extra_events ~use_sampling =
  match use_sampling with
  | true -> Stacktrace_sampling { extra_events }
  | false ->
    (match hardware_trace_device_path () with
     | Some _ -> Intel_processor_trace { extra_events }
     | None ->
       Core.eprintf
         "Hardware trace support not found. magic-trace will continue and use sampling \
          instead.\n";
       Stacktrace_sampling { extra_events })
;;

let param =
  let%map_open.Command extra_events =
    flag
      "-events"
      (optional_with_default
         []
         (Command.Arg_type.comma_separated ~unique_values:true Event.arg_type))
      ~doc:
        "EVENTS Select additional events which can be sampled as a comma separated list. \
         Valid options are [cache-misses] or [branch-misses]. For more info: \
         https://magic-trace.org/w/e"
    |> Util.experimental_flag ~default:[]
  and use_sampling =
    flag
      "-sampling"
      no_arg
      ~doc:
        "Use stacktrace sampling instead of hardware trace (Intel PT / CoreSight ETM). \
         If hardware trace is not available, magic-trace will default to this. For more \
         info: https://magic-trace.org/w/b"
  in
  select_collection_mode ~extra_events ~use_sampling
;;
