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

let thread_ids_of_dir_entries entries =
  Array.filter_map entries ~f:(fun entry ->
    try Some (Pid.of_string entry) with
    | _ -> None)
  |> Array.to_list
  |> List.sort ~compare:Pid.compare
;;

let thread_ids pid =
  Or_error.try_with (fun () ->
    Sys_unix.readdir [%string "/proc/%{pid#Pid}/task"] |> thread_ids_of_dir_entries)
;;

let thread_exists ~pid ~tid =
  match Core_unix.access [%string "/proc/%{pid#Pid}/task/%{tid#Pid}"] [ `Exists ] with
  | Ok () -> true
  | Error _ -> false
;;

module For_testing = struct
  let thread_ids_of_dir_entries = thread_ids_of_dir_entries
end

let cmdline_of_pid pid = Hashtbl.find state pid
