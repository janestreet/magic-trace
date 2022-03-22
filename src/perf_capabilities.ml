open! Core
open! Async

let bit n = Int63.of_int (1 lsl n)
let configurable_psb_period = bit 0

include Flags.Make (struct
  let allow_intersecting = false
  let should_print_error = true
  let remove_zero_flags = false
  let known = [ configurable_psb_period, "configurable_psb_period" ]
end)

module Version = struct
  type t =
    { major : int
    ; minor : int
    }
  [@@deriving sexp_of, compare]

  let _create ~major ~minor = { major; minor }

  let of_perf_version_string_exn version_string =
    try
      Scanf.sscanf version_string "perf version %d.%d" (fun major minor ->
          { major; minor })
    with
    | Scanf.Scan_failure _ | End_of_file ->
      raise_s
        [%message "unable to interpret perf version string" (version_string : string)]
  ;;
end

let supports_configurable_psb_period () =
  let cyc_cap =
    In_channel.read_all "/sys/bus/event_source/devices/intel_pt/caps/psb_cyc"
  in
  String.( = ) cyc_cap "1\n"
;;

let detect_exn () =
  let%bind perf_version_proc = Process.create_exn ~prog:"perf" ~args:[ "--version" ] () in
  let%map version_string = Reader.contents (Process.stdout perf_version_proc) in
  let _version = Version.of_perf_version_string_exn version_string in
  let capabilities = empty in
  let capabilities =
    if supports_configurable_psb_period ()
    then capabilities + configurable_psb_period
    else capabilities
  in
  capabilities
;;
