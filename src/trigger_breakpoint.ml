open! Core
open! Async

type t =
  { breakpoint : Breakpoint.t
  ; fd : Async_unix.Fd.t
  }

let create ~tid ~addr =
  let open Or_error.Let_syntax in
  let%map breakpoint = Breakpoint.breakpoint_fd tid ~addr in
  let fd =
    Async_unix.Fd.create
      Async_unix.Fd.Kind.File
      (Breakpoint.fd breakpoint)
      (Info.of_string [%string "perf breakpoint %{tid#Pid}"])
  in
  { breakpoint; fd }
;;

let enable t ~single_hit = Breakpoint.enable t.breakpoint ~single_hit

let monitor t ~interrupt ~on_hit =
  let rec read_events snapshot_enabled =
    match Breakpoint.next_hit t.breakpoint with
    | Some hit ->
      if snapshot_enabled then on_hit hit;
      read_events false
    | None -> ()
  in
  Async_unix.Fd.interruptible_every_ready_to
    t.fd
    `Read
    ~interrupt
    (fun () -> read_events true)
    ()
;;

let destroy t = Breakpoint.destroy t.breakpoint

type breakpoint = t

module Manager = struct
  let scan_interval = Time_ns.Span.of_ms 50.

  let new_thread_ids ~active tids =
    List.filter tids ~f:(fun tid -> not (Set.mem active tid))
  ;;

  module Active_breakpoint = struct
    type t =
      { breakpoint : breakpoint
      ; monitoring : unit Deferred.t
      }
  end

  let monitor_process ~pid ~addr ~single_hit ~interrupt ~on_hit =
    let breakpoints = Hashtbl.create (module Pid) in
    let stopped () = Deferred.is_determined interrupt in
    let add_tid tid =
      if Hashtbl.mem breakpoints tid || stopped ()
      then Deferred.unit
      else (
        match create ~tid ~addr with
        | Error error ->
          if Process_info.thread_exists ~pid ~tid
          then Error.raise error
          else
            (* The task exited between /proc enumeration and perf_event_open. *)
            Deferred.unit
        | Ok breakpoint ->
          let monitoring =
            let%map result = monitor breakpoint ~interrupt ~on_hit in
            Hashtbl.remove breakpoints tid;
            destroy breakpoint;
            match result with
            | `Interrupted | `Bad_fd | `Closed -> ()
            | `Unsupported -> failwith "failed to wait on breakpoint"
          in
          Hashtbl.set
            breakpoints
            ~key:tid
            ~data:{ Active_breakpoint.breakpoint; monitoring };
          let%bind () = Scheduler.yield () in
          (match enable breakpoint ~single_hit with
           | Ok () ->
             don't_wait_for monitoring;
             Deferred.unit
           | Error error ->
             Hashtbl.remove breakpoints tid;
             destroy breakpoint;
             if Process_info.thread_exists ~pid ~tid
             then Error.raise error
             else Deferred.unit))
    in
    let rec rescan () =
      if stopped ()
      then Deferred.unit
      else (
        let%bind () =
          match Process_info.thread_ids pid with
          | Error _ -> Deferred.unit
          | Ok tids ->
            let active = Hashtbl.keys breakpoints |> Set.of_list (module Pid) in
            let new_tids = new_thread_ids ~active tids in
            Deferred.List.iter new_tids ~how:`Sequential ~f:add_tid
        in
        let%bind () = Async.Clock_ns.after scan_interval in
        rescan ())
    in
    let%bind () = rescan () in
    let active =
      Hashtbl.data breakpoints
      |> List.map ~f:(fun { Active_breakpoint.monitoring; _ } -> monitoring)
    in
    Deferred.all_unit active
  ;;

  module For_testing = struct
    let new_thread_ids = new_thread_ids
  end
end
