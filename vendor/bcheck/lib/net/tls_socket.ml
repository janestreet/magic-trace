let find_header_end s =
  let len = String.length s in
  let rec scan i =
    if i + 3 >= len then None
    else if
      s.[i] = '\r' && s.[i + 1] = '\n' && s.[i + 2] = '\r'
      && s.[i + 3] = '\n'
    then Some (i + 4)
    else scan (i + 1)
  in
  scan 0

let parse_content_length headers =
  let lines = String.split_on_char '\n' headers in
  let prefix = "content-length:" in
  let plen = String.length prefix in
  let rec find = function
    | [] -> None
    | line :: rest ->
      let lower = String.lowercase_ascii (String.trim line) in
      if
        String.length lower > plen
        && String.sub lower 0 plen = prefix
      then
        let value =
          String.trim (String.sub lower plen (String.length lower - plen))
        in
        (try Some (int_of_string value) with _ -> find rest)
      else find rest
  in
  find lines

let resolve_host host port =
  let open Lwt.Syntax in
  let hints = Unix.[ AI_FAMILY PF_INET; AI_SOCKTYPE SOCK_STREAM ] in
  let* addrs = Lwt_unix.getaddrinfo host (string_of_int port) hints in
  match addrs with
  | [] ->
    Lwt.return_error (Printf.sprintf "DNS resolution failed for %s" host)
  | ai :: _ -> Lwt.return_ok ai.Unix.ai_addr

let tls_read tls buf =
  Lwt.catch
    (fun () -> Tls_lwt.Unix.read tls buf)
    (function End_of_file -> Lwt.return 0 | exn -> Lwt.fail exn)

let scutil_proxy () =
  try
    let ic = Unix.open_process_in "scutil --proxy 2>/dev/null" in
    let buf = Buffer.create 512 in
    (try while true do Buffer.add_char buf (input_char ic) done
     with End_of_file -> ());
    let _ = Unix.close_process_in ic in
    let output = Buffer.contents buf in
    let find_val key =
      let pat = key ^ " : " in
      let plen = String.length pat in
      let olen = String.length output in
      let rec scan i =
        if i + plen >= olen then None
        else if String.sub output i plen = pat then
          let start = i + plen in
          let eol =
            match String.index_from_opt output start '\n' with
            | Some p -> p
            | None -> olen
          in
          Some (String.trim (String.sub output start (eol - start)))
        else scan (i + 1)
      in
      scan 0
    in
    let enabled = match find_val "HTTPSEnable" with
      | Some "1" -> true
      | _ -> false
    in
    if enabled then
      match find_val "HTTPSProxy", find_val "HTTPSPort" with
      | Some host, Some port -> Some (Printf.sprintf "http://%s:%s" host port)
      | Some host, None -> Some (Printf.sprintf "http://%s:8080" host)
      | _ -> None
    else
      let http_enabled = match find_val "HTTPEnable" with
        | Some "1" -> true
        | _ -> false
      in
      if http_enabled then
        match find_val "HTTPProxy", find_val "HTTPPort" with
        | Some host, Some port -> Some (Printf.sprintf "http://%s:%s" host port)
        | Some host, None -> Some (Printf.sprintf "http://%s:8080" host)
        | _ -> None
      else None
  with _ -> None

let get_proxy_config () =
  let try_env name =
    match Sys.getenv_opt name with
    | Some "" | None -> None
    | Some v -> Some v
  in
  match try_env "HTTPS_PROXY" with
  | Some _ as v -> v
  | None ->
    match try_env "https_proxy" with
    | Some _ as v -> v
    | None ->
      match try_env "HTTP_PROXY" with
      | Some _ as v -> v
      | None ->
        match try_env "http_proxy" with
        | Some _ as v -> v
        | None ->
          match try_env "ALL_PROXY" with
          | Some _ as v -> v
          | None -> scutil_proxy ()

let parse_proxy_url url =
  let url =
    if String.length url > 0 && url.[String.length url - 1] = '/' then
      String.sub url 0 (String.length url - 1)
    else url
  in
  let strip_scheme s =
    let prefixes = ["https://"; "http://"] in
    let rec try_prefix = function
      | [] -> s
      | p :: rest ->
        let plen = String.length p in
        if String.length s >= plen &&
           String.lowercase_ascii (String.sub s 0 plen) = p
        then String.sub s plen (String.length s - plen)
        else try_prefix rest
    in
    try_prefix prefixes
  in
  let hostport = strip_scheme url in
  match String.index_opt hostport ':' with
  | Some i ->
    let h = String.sub hostport 0 i in
    let p_str = String.sub hostport (i + 1) (String.length hostport - i - 1) in
    (match int_of_string_opt p_str with
    | Some p -> Some (h, p)
    | None -> Some (h, 8080))
  | None -> Some (hostport, 8080)

let raw_read fd buf =
  Lwt.catch
    (fun () -> Lwt_unix.read fd buf 0 (Bytes.length buf))
    (fun _ -> Lwt.return 0)

let establish_connect_tunnel fd ~proxy_host ~target_host ~target_port =
  let open Lwt.Syntax in
  let connect_req =
    Printf.sprintf
      "CONNECT %s:%d HTTP/1.1\r\nHost: %s:%d\r\n\r\n"
      target_host target_port target_host target_port
  in
  ignore proxy_host;
  let req_bytes = Bytes.of_string connect_req in
  let* _n = Lwt_unix.write fd req_bytes 0 (Bytes.length req_bytes) in
  let acc = Buffer.create 512 in
  let chunk = Bytes.create 1024 in
  let rec read_connect_response () =
    let* n = raw_read fd chunk in
    if n = 0 then Lwt.return_error "proxy closed connection"
    else begin
      Buffer.add_subbytes acc chunk 0 n;
      let data = Buffer.contents acc in
      match find_header_end data with
      | None -> read_connect_response ()
      | Some _ ->
        let status_line =
          match String.split_on_char '\r' data with
          | first :: _ -> first
          | [] -> ""
        in
        let code =
          match String.split_on_char ' ' status_line with
          | _ :: c :: _ -> (try int_of_string c with _ -> 0)
          | _ -> 0
        in
        if code = 200 then Lwt.return_ok ()
        else Lwt.return_error (Printf.sprintf "proxy CONNECT returned %d" code)
    end
  in
  read_connect_response ()

let https_request ~host ~port ~request =
  let open Lwt.Syntax in
  match Ca_certs.authenticator () with
  | Error (`Msg msg) -> Lwt.return_error ("CA certs: " ^ msg)
  | Ok authenticator -> (
    let proxy = get_proxy_config () in
    let proxy_parsed = match proxy with
      | None -> None
      | Some url -> parse_proxy_url url
    in
    let connect_host, connect_port = match proxy_parsed with
      | Some (h, p) -> (h, p)
      | None -> (host, port)
    in
    let* addr_result = resolve_host connect_host connect_port in
    match addr_result with
    | Error e -> Lwt.return_error e
    | Ok addr ->
      let fd = Lwt_unix.socket Unix.PF_INET Unix.SOCK_STREAM 0 in
      Lwt.finalize
        (fun () ->
          Lwt.catch
            (fun () ->
              let* () = Lwt_unix.connect fd addr in
              let* () = match proxy_parsed with
                | None -> Lwt.return_unit
                | Some (proxy_host, _) ->
                  let* tunnel_result =
                    establish_connect_tunnel fd
                      ~proxy_host ~target_host:host ~target_port:port
                  in
                  (match tunnel_result with
                  | Ok () -> Lwt.return_unit
                  | Error e -> Lwt.fail (Failure e))
              in
              let tls_config =
                match Tls.Config.client ~authenticator () with
                | Ok c -> c
                | Error (`Msg msg) -> failwith ("TLS config: " ^ msg)
              in
              let* tls =
                Tls_lwt.Unix.client_of_fd tls_config
                  ~host:
                    (Domain_name.of_string_exn host |> Domain_name.host_exn)
                  fd
              in
              let* () = Tls_lwt.Unix.write tls request in
              let acc = Buffer.create 4096 in
              let chunk = Bytes.create 4096 in
              let rec read_until_header_end () =
                let* n = tls_read tls chunk in
                if n = 0 then Lwt.return_none
                else begin
                  Buffer.add_subbytes acc chunk 0 n;
                  let data = Buffer.contents acc in
                  match find_header_end data with
                  | Some pos -> Lwt.return_some pos
                  | None -> read_until_header_end ()
                end
              in
              let* hdr_end = read_until_header_end () in
              match hdr_end with
              | None ->
                let* () =
                  Lwt.catch
                    (fun () -> Tls_lwt.Unix.shutdown tls `read_write)
                    (fun _exn -> Lwt.return_unit)
                in
                Lwt.return_error "Connection closed before headers complete"
              | Some hdr_end ->
                let data = Buffer.contents acc in
                let headers = String.sub data 0 hdr_end in
                let status_line =
                  match String.split_on_char '\r' headers with
                  | first :: _ -> first
                  | [] -> ""
                in
                let code =
                  match String.split_on_char ' ' status_line with
                  | _ :: c :: _ -> (try int_of_string c with _ -> 0)
                  | _ -> 0
                in
                let content_length = parse_content_length headers in
                let body_buf = Buffer.create 4096 in
                Buffer.add_string body_buf
                  (String.sub data hdr_end (String.length data - hdr_end));
                let rec read_body () =
                  match content_length with
                  | Some cl when Buffer.length body_buf >= cl ->
                    Lwt.return_unit
                  | _ ->
                    let* n = tls_read tls chunk in
                    if n = 0 then Lwt.return_unit
                    else begin
                      Buffer.add_subbytes body_buf chunk 0 n;
                      read_body ()
                    end
                in
                let* () = read_body () in
                let body =
                  let raw = Buffer.contents body_buf in
                  match content_length with
                  | Some cl when cl < String.length raw ->
                    String.sub raw 0 cl
                  | _ -> raw
                in
                let* () =
                  Lwt.catch
                    (fun () -> Tls_lwt.Unix.shutdown tls `read_write)
                    (fun _exn -> Lwt.return_unit)
                in
                Lwt.return_ok (code, body))
            (fun exn ->
              Lwt.return_error
                (Printf.sprintf "TLS error: %s" (Printexc.to_string exn))))
        (fun () ->
          Lwt.catch
            (fun () -> Lwt_unix.close fd)
            (fun _exn -> Lwt.return_unit)))
