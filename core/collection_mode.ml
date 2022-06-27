open! Core

module Primary = struct
  type t =
    | Intel_processor_trace
    | Stacktrace_sampling
end

module Event = struct
  module Name = struct
    type t =
      | Branch_misses
      | Cache_misses
    [@@deriving compare, hash, sexp]

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
      { when_to_sample = Period 50; name = Cache_misses; precision = Maximum_possible }
    | str -> t_of_sexp (Sexp.of_string str)
  ;;

  let arg_type = Command.Arg_type.create of_string
end

type t =
  { primary : Primary.t
  ; extra_events : Event.t list
  }

let select_primary_collection_mode ~use_sampling =
  match use_sampling with
  | true -> Primary.Stacktrace_sampling
  | false ->
    (match Core_unix.access "/sys/bus/event_source/devices/intel_pt" [ `Exists ] with
    | Ok () -> Intel_processor_trace
    | Error _ ->
      Core.printf
        "Intel PT support not found. magic-trace will continue and use sampling instead.\n";
      Stacktrace_sampling)
;;

let param =
  let%map_open.Command primary =
    flag
      "-sampling"
      no_arg
      ~doc:
        "Use stacktrace sampling instead of Intel PT. If Intel PT is not available, \
         magic-trace will default to this."
    |> map ~f:(fun use_sampling -> select_primary_collection_mode ~use_sampling)
  and extra_events =
    flag
      "-events"
      (optional_with_default
         []
         (Command.Arg_type.comma_separated ~unique_values:true Event.arg_type))
      ~doc:
        "EVENTS Select additional events which can be sampled as a comma separated list. \
         Valid options are [cache-misses] or [branch-misses]. For more info: \
         https://magic-trace.org/w/e"
  in
  { primary; extra_events }
;;
