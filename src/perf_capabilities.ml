open! Core
open! Async

let bit n = Int63.of_int (1 lsl n)
let configurable_psb_period = bit 0
let kernel_tracing = bit 1
let kcore = bit 2
let snapshot_on_exit = bit 3
let last_branch_record = bit 4
let dlfilter = bit 5
let ctlfd = bit 6

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
      ; ctlfd, "ctlfd"
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
  (* Check if we can trace the kernel through multiple methods:
     1. Check if we're root (traditional method)
     2. Check perf_event_paranoid setting
     3. Check if perf binary has CAP_SYS_ADMIN capability
     4. Check if Intel PT is available for kernel tracing *)
  
  (* First, check if we're root *)
  if Int.(Core_unix.geteuid () = 0) then true
  else
    (* Check /proc/sys/kernel/perf_event_paranoid
       -1 = allow use of (almost) all events by all users
        0 = disallow raw tracepoint access for unpriv
        1 = disallow CPU event access for unpriv
        2 = disallow kernel profiling for unpriv (default)
       Kernel tracing requires paranoid < 0 *)
    try
      let paranoid = 
        In_channel.read_all "/proc/sys/kernel/perf_event_paranoid"
        |> String.strip
        |> Int.of_string
      in
      if Int.(paranoid < 0) then true
      else
        (* Check if the perf binary has the necessary capabilities *)
        (* This uses getcap to check if perf has CAP_SYS_ADMIN *)
        let check_perf_capabilities () =
          try
            let%bind getcap_proc =
              Process.create ~prog:"getcap" ~args:[Env_vars.perf_path] ()
            in
            match%map Process.collect_output_and_wait getcap_proc with
            | { stdout; exit_status = Ok (); _ } ->
              (* Look for cap_sys_admin in the output *)
              String.is_substring stdout ~substring:"cap_sys_admin"
            | _ -> false
          with
          | _ -> Deferred.return false
        in
        (* Run the capability check synchronously *)
        Thread_safe.block_on_async_exn (fun () -> check_perf_capabilities ())
    with
    | _ -> 
      (* If we can't read paranoid or check capabilities, 
         fall back to the conservative check *)
      false
;;

let kernel_version_at_least ~major ~minor version =
  Int.(Version.compare version (Version.create ~major ~minor) >= 0)
;;

(* Added in kernel commit eeb399b, which made it into 5.5. *)
let supports_kcore = kernel_version_at_least ~major:5 ~minor:5

(* Added in kernel commit ce7b0e4, which made it into 5.4. *)
let supports_snapshot_on_exit = kernel_version_at_least ~major:5 ~minor:4

(* Added in kernel commit d20aff1, which made it into 5.10. *)
let supports_ctlfd = kernel_version_at_least ~major:5 ~minor:10

(* Added in kernel commit 291961f, which made it into 5.14. *)
let supports_dlfilter = kernel_version_at_least ~major:5 ~minor:14

let detect_exn () =
  let%bind perf_version_proc =
    Process.create_exn ~prog:Env_vars.perf_path ~args:[ "--version" ] ()
  in
  let%map { stdout; _ } = Process.collect_output_and_wait perf_version_proc in
  let version = Version.of_perf_version_string_exn stdout in
  let set_if bool flag cap = cap + if bool then flag else empty in
  empty
  |> set_if (supports_configurable_psb_period ()) configurable_psb_period
  |> set_if (supports_tracing_kernel ()) kernel_tracing
  |> set_if (supports_kcore version) kcore
  |> set_if (supports_snapshot_on_exit version) snapshot_on_exit
  |> set_if (supports_last_branch_record ()) last_branch_record
  |> set_if (supports_dlfilter version) dlfilter
  |> set_if (supports_ctlfd version) ctlfd
;;
