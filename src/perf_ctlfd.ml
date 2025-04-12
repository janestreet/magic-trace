open Core

module Command = struct
  type t = string

  let snapshot = "snapshot"
end

let ack_msg = "ack\n\000"
let ack_timeout = Time_ns.Span.of_int_sec 1

type t =
  { mutable ctl_rx : Core_unix.File_descr.t
  ; ctl_tx : Core_unix.File_descr.t
  ; ack_rx : Core_unix.File_descr.t
  ; mutable ack_tx : Core_unix.File_descr.t
  ; ack_buf : Bytes.t
  }

let create () =
  let ctl_rx, ctl_tx = Core_unix.pipe ~close_on_exec:false () in
  let ack_rx, ack_tx = Core_unix.pipe ~close_on_exec:false () in
  Core_unix.set_close_on_exec ctl_tx;
  Core_unix.set_close_on_exec ack_rx;
  { ctl_rx; ctl_tx; ack_rx; ack_tx; ack_buf = Bytes.make (String.length ack_msg) '\000' }
;;

let close_perf_side_fds t =
  Core_unix.close ~restart:true t.ctl_rx;
  t.ctl_rx <- Core_unix.File_descr.of_int (-1);
  Core_unix.close ~restart:true t.ack_tx;
  t.ack_tx <- Core_unix.File_descr.of_int (-1)
;;

let control_opt ({ ctl_rx; ack_tx; _ } as t) =
  let p = Core_unix.File_descr.to_int in
  ( [ [%string "--control=fd:%{p ctl_rx#Int},%{p ack_tx#Int}"] ]
  , fun () -> close_perf_side_fds t )
;;

let block_read_ack t =
  let total_bytes_read = ref 0 in
  while
    match
      Core_unix.select
        ~restart:true
        ~read:[ t.ack_rx ]
        ~write:[]
        ~except:[]
        ~timeout:(`After ack_timeout)
        ()
    with
    | { read = []; _ } -> failwith "Perf didn't ack snapshot within timeout"
    | { read = [ _fd ]; _ } ->
      let bytes_read =
        Core_unix.read ~restart:true t.ack_rx ~buf:t.ack_buf ~pos:!total_bytes_read
      in
      if bytes_read = 0 then failwith "Perf unexpectedly closed ack fd";
      total_bytes_read := !total_bytes_read + bytes_read;
      !total_bytes_read < Bytes.length t.ack_buf
    | _ -> failwith "unreachable"
  do
    ()
  done;
  if not
       (String.equal
          ack_msg
          (Bytes.unsafe_to_string ~no_mutation_while_string_reachable:t.ack_buf))
  then failwith "Receive malformed ack from perf";
  Bytes.fill t.ack_buf ~pos:0 ~len:(Bytes.length t.ack_buf) '\000'
;;

let dispatch_and_block_for_ack t (command : Command.t) =
  (* Don't do an async write because we want to write immediately; we don't really
     care if we block for a bit *)
  if Core_unix.single_write_substring ~restart:true t.ctl_tx ~buf:command
     <> String.length command
  then failwith "Unexpected partial write to perf ctlfd"
  else block_read_ack t
;;
