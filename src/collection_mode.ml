open! Core

module Aux_action = struct
  type t =
    | Start_paused
    | Resume
    | Pause
  [@@deriving compare, sexp]

  let to_string = function
    | Start_paused -> "start-paused"
    | Resume -> "resume"
    | Pause -> "pause"
  ;;

  let add_to_perf_config t config =
    let aux_action = to_string t in
    if String.is_empty config
    then [%string "aux-action=%{aux_action}"]
    else [%string "%{config},aux-action=%{aux_action}"]
  ;;
end

module Aux_control_event = struct
  type t =
    { address : int64
    ; action : Aux_action.t
    }
  [@@deriving sexp]

  let to_perf_event { address; action } =
    let action = Aux_action.to_string action in
    Printf.sprintf "mem:0x%Lx:x/aux-action=%s/" address action
  ;;
end

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
  | Intel_processor_trace of
      { extra_events : Event.t list
      ; aux_action : Aux_action.t option
      ; aux_control_events : Aux_control_event.t list
      }
  | Stacktrace_sampling of { extra_events : Event.t list }

let extra_events = function
  | Intel_processor_trace { extra_events; _ } | Stacktrace_sampling { extra_events } ->
    extra_events
;;

let aux_action = function
  | Intel_processor_trace { aux_action; _ } -> aux_action
  | Stacktrace_sampling _ -> None
;;

let aux_control_events = function
  | Intel_processor_trace { aux_control_events; _ } -> aux_control_events
  | Stacktrace_sampling _ -> []
;;

let with_aux_control t ~start_address ~stop_address =
  match t with
  | Intel_processor_trace { extra_events; _ } ->
    Ok
      (Intel_processor_trace
         { extra_events
         ; aux_action = Some Aux_action.Start_paused
         ; aux_control_events =
             [ { Aux_control_event.address = start_address; action = Aux_action.Resume }
             ; { Aux_control_event.address = stop_address; action = Aux_action.Pause }
             ]
         })
  | Stacktrace_sampling _ ->
    Or_error.error_string "AUX trace ranges require Intel Processor Trace"
;;

let select_collection_mode ~extra_events ~use_sampling =
  match use_sampling with
  | true -> Stacktrace_sampling { extra_events }
  | false ->
    (match Core_unix.access "/sys/bus/event_source/devices/intel_pt" [ `Exists ] with
     | Ok () ->
       Intel_processor_trace { extra_events; aux_action = None; aux_control_events = [] }
     | Error _ ->
       Core.eprintf
         "Intel PT support not found. magic-trace will continue and use sampling instead.\n";
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
        "Use stacktrace sampling instead of Intel PT. If Intel PT is not available, \
         magic-trace will default to this. For more info: https://magic-trace.org/w/b"
  in
  select_collection_mode ~extra_events ~use_sampling
;;
