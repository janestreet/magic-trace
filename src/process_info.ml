open! Core

module Entry = struct
  module Cmdline = struct
    type t = string list
  end
end

let state = Hashtbl.create (module Pid)

let read_proc_info pid =
  let line = In_channel.read_lines [%string "/proc/%{pid#Pid}/cmdline"] |> List.hd in
  match line with
  | None -> ()
  | Some args ->
    let cmdline =
      String.split ~on:(Char.of_int_exn 0) args |> List.filter ~f:(Fn.non String.is_empty)
    in
    Hashtbl.set state ~key:pid ~data:cmdline
;;

let read_all_proc_info () =
  Sys_unix.readdir "/proc"
  |> Array.iter ~f:(fun filename ->
    try Pid.of_string filename |> read_proc_info with
    | _ -> ())
;;

let cmdline_of_pid pid = Hashtbl.find state pid

let kthreadd_pid = Pid.of_int 2

let ppid_of_stat_line stat_line =
  match String.rsplit2 stat_line ~on:')' with
  | None -> None
  | Some (_, rest) ->
    (match
       rest
       |> String.lstrip
       |> String.split ~on:' '
       |> List.filter ~f:(Fn.non String.is_empty)
     with
     | _state :: ppid :: _ -> Some (Pid.of_string ppid)
     | _ -> None)
;;

let ppid_of_pid pid =
  try
    In_channel.read_all [%string "/proc/%{pid#Pid}/stat"] |> ppid_of_stat_line
  with
  | _ -> None
;;

let is_kernel_thread pid =
  match ppid_of_pid pid with
  | Some ppid -> Pid.(ppid = kthreadd_pid)
  | None -> false
;;

let vmlinux_candidates () =
  let release = (Core_unix.uname ()).release in
  [ [%string "/usr/lib/debug/boot/vmlinux-%{release}"]
  ; [%string "/boot/vmlinux-%{release}"]
  ; [%string "/usr/lib/debug/lib/modules/%{release}/vmlinux"]
  ]
;;

let find_vmlinux () =
  List.find_map (vmlinux_candidates ()) ~f:(fun path ->
    if Sys_unix.file_exists path then Some path else None)
;;

let executable_of_pid pid =
  let exe_path = [%string "/proc/%{pid#Pid}/exe"] in
  match Or_error.try_with (fun () -> Core_unix.readlink exe_path) with
  | Ok path -> Ok path
  | Error _ when is_kernel_thread pid ->
    (match find_vmlinux () with
     | Some vmlinux -> Ok vmlinux
     | None ->
       Or_error.error_string
         "Cannot trace kernel thread: vmlinux not found. Install your distro's kernel \
          debug package (for example, linux-image-$(uname -r)-dbgsym on Debian/Ubuntu) \
          and retry with [-trace-include-kernel] or [-trace-kernel-only].")
  | Error error -> Error error
;;

let%expect_test "ppid_of_stat_line parses comm with spaces" =
  Expect_test_helpers_core.require_equal
    (module struct
      type t = Pid.t option

      let equal = Option.equal Pid.equal
      let sexp_of_t = [%sexp_of: Pid.t option]
    end)
    (ppid_of_stat_line "(migration/0) S 2 0 0 0 -1 2129984 0 0 0 0 0 0 0 0 20 0 1 0")
    (Some (Pid.of_int 2))
  |> Deferred.return
;;

let%expect_test "is_kernel_thread is false for the current process" =
  Expect_test_helpers_core.require_equal
    (module Bool)
    (is_kernel_thread (Pid.of_int (Core_unix.getpid ())))
    false
  |> Deferred.return
;;
