open! Core

module Command = struct
  type t = string

  let snapshot = "snapshot\n"
  let stop = "stop\n"
end

let ack_msg = Bytes.of_string "ack\n\000"

(* If we send a command while perf is shutting down, [ack_rx] will become ready only after
   perf exits, so this timeout must be at least as long as it takes perf to finish
   shutting down. *)
let ack_timeout = `After (Time_ns.Span.of_int_sec 8)

type t =
  { mutable ctl_rx : Core_unix.File_descr.t option
  ; ctl_tx : Core_unix.File_descr.t
  ; ack_rx : Core_unix.File_descr.t
  ; mutable ack_tx : Core_unix.File_descr.t option
  ; ack_buf : Bytes.t
  }

let create () =
  let ctl_rx, ctl_tx = Core_unix.pipe ~close_on_exec:false () in
  let ack_rx, ack_tx = Core_unix.pipe ~close_on_exec:false () in
  Core_unix.set_close_on_exec ctl_tx;
  Core_unix.set_close_on_exec ack_rx;
  { ctl_rx = Some ctl_rx
  ; ctl_tx
  ; ack_rx
  ; ack_tx = Some ack_tx
  ; ack_buf = Bytes.make (Bytes.length ack_msg) '\000'
  }
;;

let close_perf_side_fds t =
  Option.iter t.ctl_rx ~f:Core_unix.close;
  t.ctl_rx <- None;
  Option.iter t.ack_tx ~f:Core_unix.close;
  t.ack_tx <- None
;;

let control_opt ({ ctl_rx; ack_tx; _ } as t) =
  let p fd = Core_unix.File_descr.to_int (Option.value_exn fd) in
  ( [ [%string "--control=fd:%{p ctl_rx#Int},%{p ack_tx#Int}"] ]
  , fun () -> close_perf_side_fds t )
;;

let block_read_ack t =
  Bytes.fill t.ack_buf ~pos:0 ~len:(Bytes.length t.ack_buf) '\000';
  let rec read_loop t ~total_bytes_read =
    match
      Core_unix.select
        ~restart:true
        ~read:[ t.ack_rx ]
        ~write:[]
        ~except:[]
        ~timeout:ack_timeout
        ()
    with
    | { read = []; _ } -> failwith "Perf didn't ack command within timeout"
    | { read = [ _fd ]; _ } ->
      let bytes_read =
        Core_unix.read ~restart:true t.ack_rx ~buf:t.ack_buf ~pos:total_bytes_read
      in
      if bytes_read = 0
      then Error `Perf_exited
      else (
        let total_bytes_read = total_bytes_read + bytes_read in
        if total_bytes_read < Bytes.length t.ack_buf
        then read_loop t ~total_bytes_read
        else if Bytes.equal ack_msg t.ack_buf
        then Ok ()
        else
          raise_s
            [%message "Receive malformed ack from perf" ~recvd:(t.ack_buf : Bytes.t)])
    | _ -> failwith "unreachable"
  in
  read_loop t ~total_bytes_read:0
;;

let dispatch_and_block_for_ack t (command : Command.t) =
  (* Don't do an async write because we want to write immediately; we don't really
     care if we block for a bit *)
  try
    let written = Core_unix.single_write_substring ~restart:true t.ctl_tx ~buf:command in
    if written <> String.length command
    then failwith "Unexpected partial write to perf ctlfd"
    else block_read_ack t
  with
  | Core_unix.Unix_error (Core_unix.Error.EPIPE, _, _) -> Error `Perf_exited
;;
