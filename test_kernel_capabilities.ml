(* Test script for improved kernel capability checking *)
open! Core
open! Async

let test_kernel_capabilities () =
  printf "Testing kernel tracing capability detection:\n%!";
  
  (* Test 1: Check current user *)
  let uid = Core_unix.geteuid () in
  printf "Current effective UID: %d%s\n%!" uid 
    (if Int.(uid = 0) then " (root)" else " (non-root)");
  
  (* Test 2: Check perf_event_paranoid *)
  (try
    let paranoid = 
      In_channel.read_all "/proc/sys/kernel/perf_event_paranoid"
      |> String.strip
    in
    printf "perf_event_paranoid: %s\n%!" paranoid;
    let paranoid_int = Int.of_string paranoid in
    printf "  -> Kernel tracing %s (requires < 0)\n%!"
      (if Int.(paranoid_int < 0) then "ALLOWED" else "DENIED")
  with
  | e -> printf "Failed to read perf_event_paranoid: %s\n%!" (Exn.to_string e));
  
  (* Test 3: Check perf binary capabilities *)
  let perf_path = "/usr/bin/perf" in (* Default path, adjust as needed *)
  printf "Checking capabilities for: %s\n%!" perf_path;
  
  let%bind getcap_result = 
    try
      let%bind proc = Process.create ~prog:"getcap" ~args:[perf_path] () in
      Process.collect_output_and_wait proc
    with
    | e -> Deferred.return { 
        Process.Output.stdout = ""; 
        stderr = Exn.to_string e; 
        exit_status = Error (`Exit_non_zero 1) 
      }
  in
  
  (match getcap_result with
  | { stdout; exit_status = Ok (); _ } when String.length stdout > 0 ->
    printf "Perf capabilities: %s" stdout;
    if String.is_substring stdout ~substring:"cap_sys_admin" then
      printf "  -> CAP_SYS_ADMIN detected: kernel tracing MAY be allowed\n%!"
    else
      printf "  -> No CAP_SYS_ADMIN capability\n%!"
  | { stderr; _ } when String.length stderr > 0 ->
    printf "getcap error: %s\n%!" stderr
  | _ ->
    printf "No capabilities set on perf binary\n%!");
  
  (* Test 4: Check Intel PT availability *)
  (try
    let pt_type = In_channel.read_all "/sys/bus/event_source/devices/intel_pt/type" in
    printf "Intel PT available: YES (type=%s)%!" (String.strip pt_type)
  with
  | _ -> printf "Intel PT available: NO or not accessible\n%!");
  
  printf "\nSummary: The improved capability checking will test all these conditions.\n%!";
  Deferred.unit

let () =
  Command.async_spec
    ~summary:"Test kernel tracing capability detection"
    Command.Spec.empty
    test_kernel_capabilities
  |> Command_unix.run