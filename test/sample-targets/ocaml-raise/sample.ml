open! Core

exception Test

let rec raise_after = function
  | 0 -> raise Test
  | n -> 1 + raise_after (n - 1)
;;

let command =
  Command.basic
    ~summary:
      "sample executable for tracing that unwinds 20 stack frames in an ocaml exception"
    (let%map_open.Command () = return () in
     fun () ->
       Magic_trace.mark_start ();
       let _sdf =
         try raise_after 20 with
         | Test ->
           print_endline "123";
           2
       in
       Magic_trace.take_snapshot_with_arg 7;
       Core_unix.sleep 1)
;;

let () = Command_unix.run command
