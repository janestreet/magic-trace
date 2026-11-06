let encode_message ~prefix raw_envelope =
  let b64 = Base64.encode_exn raw_envelope in
  prefix ^ ":" ^ b64

let decode_message ~prefix text =
  match String.index_opt text ':' with
  | None -> None
  | Some i ->
    let msg_prefix = String.sub text 0 i in
    if msg_prefix <> prefix then None
    else
      let b64 = String.sub text (i + 1) (String.length text - i - 1) in
      (match Base64.decode b64 with Ok raw -> Some raw | Error _ -> None)

let unescape_json s =
  let len = String.length s in
  let buf = Buffer.create len in
  let rec go i =
    if i >= len then Buffer.contents buf
    else if s.[i] = '\\' && i + 1 < len then begin
      (match s.[i + 1] with
      | '/' -> Buffer.add_char buf '/'
      | '\\' -> Buffer.add_char buf '\\'
      | '"' -> Buffer.add_char buf '"'
      | 'n' -> Buffer.add_char buf '\n'
      | 'r' -> Buffer.add_char buf '\r'
      | 't' -> Buffer.add_char buf '\t'
      | c -> Buffer.add_char buf '\\'; Buffer.add_char buf c);
      go (i + 2)
    end else begin
      Buffer.add_char buf s.[i];
      go (i + 1)
    end
  in
  go 0

let find_string_value ~key body =
  let pat1 = Printf.sprintf {|"%s":"|} key in
  let pat2 = Printf.sprintf {|"%s": "|} key in
  let blen = String.length body in
  let try_pattern pattern =
    let plen = String.length pattern in
    let rec scan i =
      if i + plen >= blen then None
      else if String.sub body i plen = pattern then
        let start = i + plen in
        let rec find_end j =
          if j >= blen then None
          else if body.[j] = '"' && (j = 0 || body.[j - 1] <> '\\') then
            Some (unescape_json (String.sub body start (j - start)))
          else find_end (j + 1)
        in
        find_end start
      else scan (i + 1)
    in
    scan 0
  in
  match try_pattern pat1 with
  | Some _ as r -> r
  | None -> try_pattern pat2

let has_ok_true body =
  let rec scan i =
    if i + 11 > String.length body then false
    else if String.sub body i 9 = {|"ok":true|}
         || String.sub body i 10 = {|"ok": true|} then true
    else scan (i + 1)
  in
  scan 0

let has_ok_false body =
  let rec scan i =
    if i + 12 > String.length body then false
    else if String.sub body i 10 = {|"ok":false|}
         || String.sub body i 11 = {|"ok": false|} then true
    else scan (i + 1)
  in
  scan 0

let slack_error body =
  match find_string_value ~key:"error" body with
  | Some e -> "Slack API: " ^ e
  | None -> "Slack API: unknown error"

let parse_post_response body =
  if has_ok_false body then Error (slack_error body)
  else if has_ok_true body then
    match find_string_value ~key:"ts" body with
    | Some ts -> Ok ts
    | None -> Error "Slack API: ok but no ts field"
  else Error "Slack API: unexpected response"

let parse_history_response body =
  if has_ok_false body then Error (slack_error body)
  else if not (has_ok_true body) then
    Error "Slack API: unexpected response"
  else
    let pattern = {|"messages":[|} in
    let plen = String.length pattern in
    let blen = String.length body in
    let rec find_start i =
      if i + plen > blen then None
      else if String.sub body i plen = pattern then Some (i + plen)
      else find_start (i + 1)
    in
    match find_start 0 with
    | None -> Error "Slack API: no messages array"
    | Some start ->
      if start < blen && body.[start] = ']' then Ok []
      else
        let find_next_brace body pos blen =
          let rec go i =
            if i >= blen then None
            else if body.[i] = '{' then Some i
            else go (i + 1)
          in
          go pos
        in
        let find_matching_close body start blen =
          let rec go i depth =
            if i >= blen then blen
            else match body.[i] with
            | '{' -> go (i + 1) (depth + 1)
            | '}' -> if depth = 1 then i + 1 else go (i + 1) (depth - 1)
            | _ -> go (i + 1) depth
          in
          go start 0
        in
        let has_type_message obj =
          let pat1 = {|"type":"message"|} in
          let pat2 = {|"type": "message"|} in
          let olen = String.length obj in
          let l1 = String.length pat1 in
          let l2 = String.length pat2 in
          let rec scan i =
            if i + l1 > olen then false
            else if String.sub obj i l1 = pat1 then true
            else if i + l2 <= olen && String.sub obj i l2 = pat2 then true
            else scan (i + 1)
          in
          scan 0
        in
        let rec collect acc pos =
          if pos >= blen then Ok (List.rev acc)
          else
            match find_next_brace body pos blen with
            | None -> Ok (List.rev acc)
            | Some obj_start ->
              let obj_end = find_matching_close body obj_start blen in
              let obj = String.sub body obj_start (obj_end - obj_start) in
              if has_type_message obj then
                let ts =
                  match find_string_value ~key:"ts" obj with
                  | Some v -> v
                  | None -> ""
                in
                let text =
                  match find_string_value ~key:"text" obj with
                  | Some v -> v
                  | None -> ""
                in
                collect ((ts, text) :: acc) obj_end
              else
                collect acc obj_end
        in
        collect [] start

let newest_ts msgs =
  List.fold_left
    (fun acc (ts, _) -> if String.compare ts acc > 0 then ts else acc)
    "" msgs
