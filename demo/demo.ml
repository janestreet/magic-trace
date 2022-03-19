#!/usr/bin/env ocaml

let () =
  let r = open_in "/dev/zero" in
  let w = open_out "/dev/null" in
  let buf = Bytes.create 4096 in
  while true do
    let bytes_read = input r buf 0 (Bytes.length buf) in
    output w buf 0 bytes_read
  done
;;
