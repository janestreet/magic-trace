open! Core

external ptrace_traceme : unit -> bool = "magic_ptrace_traceme"

(* Same as [Caml.exit] but does not run at_exit handlers *)
external sys_exit : int -> 'a = "caml_sys_exit"

let fork_exec_stopped ~prog ~argv () =
  let pr_set_pdeathsig = Or_error.ok_exn Linux_ext.pr_set_pdeathsig in
  match Core_unix.fork () with
  | `In_the_child ->
    (* Don't outlive the magic-trace parent process. *)
    pr_set_pdeathsig Signal.kill;
    (* This is how we ensure the process is started in a stopped state: we mark ourselves
       as traced, so that we receive a `SIGTRAP` after `exec*` completes. *)
    if not (ptrace_traceme ()) then sys_exit 126;
    never_returns
      (try Core_unix.exec ~prog ~argv () with
      | _ -> sys_exit 127)
  | `In_the_parent pid ->
    (match Core_unix.wait_untraced (`Pid pid) with
    | _, Error (`Stop _) -> pid
    | _, result ->
      raise_s
        [%message
          "expected child to stop but it did not"
            (pid : Pid.t)
            (result : (unit, Core_unix.Exit_or_signal_or_stop.error) Result.t)])
;;

external resume : Pid.t -> unit = "magic_ptrace_detach"
