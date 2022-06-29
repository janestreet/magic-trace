open! Core
open! Async

let bit n = Int63.of_int (1 lsl n)
let configurable_psb_period = bit 0
let kernel_tracing = bit 1
let kcore = bit 2
let snapshot_on_exit = bit 3
let last_branch_record = bit 4
let dlfilter = bit 5

include Flags.Make (struct
  let allow_intersecting = false
  let should_print_error = true
  let remove_zero_flags = false

  let known =
    [ configurable_psb_period, "configurable_psb_period"
    ; kernel_tracing, "kernel_tracing"
    ; kcore, "kcore"
    ; last_branch_record, "last_branch_record"
    ; dlfilter, "dlfilter"
    ]
  ;;
end)

module Version = struct
  type t =
    { major : int
    ; minor : int
    }
  [@@deriving sexp_of, compare]

  let create ~major ~minor = { major; minor }

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
  try
    let cyc_cap =
      In_channel.read_all "/sys/bus/event_source/devices/intel_pt/caps/psb_cyc"
    in
    String.( = ) cyc_cap "1\n"
  with
  (* Even if this file is not present (i.e. when Intel PT isn't present), we
     don't want capability checking to fail. *)
  | Sys_error _ -> false
;;

(* This checks if pdcm flag is present in /proc/cpuinfo. This is necessary for
   LBR to work. Although I couldn't ascertain that it is also sufficient.
   However it seems unlikely this would fail on most machines. *)
let supports_last_branch_record () =
  let cpuinfo = In_channel.read_lines "/proc/cpuinfo" in
  let flag_re = Re.Perl.re {|^flags\s*:\s+(\S.*)$|} |> Re.compile in
  let flags =
    List.filter_map cpuinfo ~f:(fun line ->
        try
          match Re.Group.all (Re.exec flag_re line) with
          | [| _; flags |] -> Some (String.split ~on:' ' flags)
          | _ -> None
        with
        | _ -> None)
  in
  (* Check if pdcm in intersection of all processor flags *)
  let contains_pdcm flags = List.exists flags ~f:(fun flag -> String.(flag = "pdcm")) in
  List.fold flags ~init:true ~f:(fun acc flags -> acc && contains_pdcm flags)
;;

let supports_tracing_kernel () =
  (* Only allow tracing the kernel if we are root. `perf` will start even without this,
     but the generated traces will be broken, so disallow it here.

     This check is technically stricter than it has to be. We could query the capability
     bits of the perf binary here instead, as per
     <https://perf.wiki.kernel.org/index.php/Perf_tools_support_for_Intel%C2%AE_Processor_Trace#Adding_capabilities_to_perf> *)
  Int.(Core_unix.geteuid () = 0)
;;

let kernel_version_at_least ~major ~minor version =
  Int.(Version.compare version (Version.create ~major ~minor) >= 0)
;;

(* Added in kernel commit eeb399b, which made it into 5.5. *)
let supports_kcore = kernel_version_at_least ~major:5 ~minor:5

(* Added in kernel commit ce7b0e4, which made it into 5.4. *)
let supports_snapshot_on_exit = kernel_version_at_least ~major:5 ~minor:4

(* Added in kernel commit 291961f, which made it into 5.14. *)
let supports_dlfilter = kernel_version_at_least ~major:5 ~minor:14

let detect_exn () =
  let%bind perf_version_proc = Process.create_exn ~prog:"perf" ~args:[ "--version" ] () in
  let%map version_string = Reader.contents (Process.stdout perf_version_proc) in
  let version = Version.of_perf_version_string_exn version_string in
  let set_if bool flag cap = cap + if bool then flag else empty in
  empty
  |> set_if (supports_configurable_psb_period ()) configurable_psb_period
  |> set_if (supports_tracing_kernel ()) kernel_tracing
  |> set_if (supports_kcore version) kcore
  |> set_if (supports_snapshot_on_exit version) snapshot_on_exit
  |> set_if (supports_last_branch_record ()) last_branch_record
  |> set_if (supports_dlfilter version) dlfilter
;;
