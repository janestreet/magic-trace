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
