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

let capability_grants_effective_capability capability_group capability =
  match String.lsplit2 capability_group ~on:'=' with
  | None -> false
  | Some (capabilities, permitted_sets) ->
    String.exists permitted_sets ~f:(Char.equal 'e')
    && capabilities |> String.split ~on:',' |> List.exists ~f:(String.equal capability)
;;

let getcap_output_grants_kernel_tracing getcap_output =
  getcap_output
  |> String.split_lines
  |> List.exists ~f:(fun line ->
    match String.split line ~on:' ' |> List.filter ~f:(Fn.non String.is_empty) with
    | [] | [ _ ] -> false
    | _path :: capability_groups ->
      List.exists capability_groups ~f:(fun capability_group ->
        capability_grants_effective_capability capability_group "cap_perfmon"
        || capability_grants_effective_capability capability_group "cap_sys_admin"))
;;

let resolve_executable_from_path executable =
  if String.contains executable '/'
  then Some executable
  else (
    match Sys.getenv "PATH" with
    | None -> None
    | Some path ->
      path
      |> String.split ~on:':'
      |> List.find_map ~f:(fun dir ->
        let candidate = dir ^/ executable in
        match Sys_unix.file_exists candidate with
        | `Yes -> Some candidate
        | `No | `Unknown -> None))
;;

let perf_has_kernel_tracing_capability ~perf_path =
  match resolve_executable_from_path perf_path with
  | None -> return false
  | Some perf_path ->
    (match%bind
       Monitor.try_with (fun () ->
         Process.create_exn ~prog:"getcap" ~args:[ perf_path ] ())
     with
     | Error _ -> return false
     | Ok getcap_proc ->
       let%map { stdout; _ } = Process.collect_output_and_wait getcap_proc in
       getcap_output_grants_kernel_tracing stdout)
;;

let supports_tracing_kernel ~perf_path =
  (* `perf` can trace the kernel as root, or when the perf executable has suitable
     effective file capabilities. If [getcap] is unavailable, keep the historical
     root-only behavior. *)
  if Int.(Core_unix.geteuid () = 0)
  then return true
  else perf_has_kernel_tracing_capability ~perf_path
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
  let%bind { stdout; _ } = Process.collect_output_and_wait perf_version_proc in
  let version = Version.of_perf_version_string_exn stdout in
  let%bind supports_tracing_kernel =
    supports_tracing_kernel ~perf_path:Env_vars.perf_path
  in
  let set_if bool flag cap = cap + if bool then flag else empty in
  return
    (empty
     |> set_if (supports_configurable_psb_period ()) configurable_psb_period
     |> set_if supports_tracing_kernel kernel_tracing
     |> set_if (supports_kcore version) kcore
     |> set_if (supports_snapshot_on_exit version) snapshot_on_exit
     |> set_if (supports_last_branch_record ()) last_branch_record
     |> set_if (supports_dlfilter version) dlfilter
     |> set_if (supports_ctlfd version) ctlfd)
;;

let%expect_test "getcap output grants kernel tracing via effective cap_perfmon" =
  let output = "/usr/bin/perf cap_sys_ptrace,cap_syslog,cap_perfmon=ep\n" in
  print_s [%sexp (getcap_output_grants_kernel_tracing output : bool)];
  [%expect {| true |}]
;;

let%expect_test "getcap output grants kernel tracing via effective cap_sys_admin" =
  let output = "/usr/bin/perf cap_sys_admin=ep\n" in
  print_s [%sexp (getcap_output_grants_kernel_tracing output : bool)];
  [%expect {| true |}]
;;

let%expect_test "getcap output requires effective capabilities" =
  let output = "/usr/bin/perf cap_perfmon=p\n" in
  print_s [%sexp (getcap_output_grants_kernel_tracing output : bool)];
  [%expect {| false |}]
;;

let%expect_test "getcap output ignores unrelated capabilities" =
  let output = "/usr/bin/perf cap_sys_ptrace,cap_syslog=ep\n" in
  print_s [%sexp (getcap_output_grants_kernel_tracing output : bool)];
  [%expect {| false |}]
;;

let%expect_test "executable resolution keeps explicit paths" =
  print_s [%sexp (resolve_executable_from_path "/usr/bin/perf" : string option)];
  [%expect {| (/usr/bin/perf) |}]
;;
