type keypair = { priv : string; pub_ : string }

type session = {
  mutable key : string;
  mutable send_counter : int64;
  mutable recv_counter : int64;
  mutable msg_since_rotation : int;
  rotation_interval : int;
}

let generate_keypair () =
  let secret, pub_ = Mirage_crypto_ec.X25519.gen_key () in
  { priv = Mirage_crypto_ec.X25519.secret_to_octets secret; pub_ }

let derive_session_key ~local_priv ~remote_pub ~salt =
  let secret =
    match Mirage_crypto_ec.X25519.secret_of_octets local_priv with
    | Ok (s, _) -> s
    | Error _ -> failwith "invalid X25519 private key"
  in
  match Mirage_crypto_ec.X25519.key_exchange secret remote_pub with
  | Error _ -> failwith "X25519 key exchange failed"
  | Ok shared_secret ->
    let prk = Hkdf.extract ~hash:`SHA256 ~salt shared_secret in
    Hkdf.expand ~hash:`SHA256 ~prk ~info:"kdf-v1" 32

let create_session ~key =
  {
    key;
    send_counter = 0L;
    recv_counter = 0L;
    msg_since_rotation = 0;
    rotation_interval = 1000;
  }

let direction_byte = function
  | `To_server -> '\x00'
  | `To_client -> '\x01'

let build_nonce ~counter ~direction =
  let buf = Bytes.make 12 '\x00' in
  Bytes.set buf 3 (direction_byte direction);
  Bytes.set_int64_be buf 4 counter;
  Bytes.to_string buf

let rotate_key session =
  let counter_buf = Bytes.create 8 in
  Bytes.set_int64_be counter_buf 0 session.send_counter;
  let prk =
    Hkdf.extract ~hash:`SHA256 ~salt:(Bytes.to_string counter_buf) session.key
  in
  session.key <- Hkdf.expand ~hash:`SHA256 ~prk ~info:"kdf-rotate" 32;
  session.msg_since_rotation <- 0

let encrypt session ~direction ?(adata = "") plaintext =
  let counter = session.send_counter in
  let nonce = build_nonce ~counter ~direction in
  let key = Mirage_crypto.Chacha20.of_secret session.key in
  let ct =
    Mirage_crypto.Chacha20.authenticate_encrypt ~key ~nonce ~adata plaintext
  in
  let counter_prefix = Bytes.create 8 in
  Bytes.set_int64_be counter_prefix 0 counter;
  session.send_counter <- Int64.add counter 1L;
  session.msg_since_rotation <- session.msg_since_rotation + 1;
  if session.msg_since_rotation >= session.rotation_interval then
    rotate_key session;
  Ok (Bytes.to_string counter_prefix ^ ct)

let decrypt session ~direction ?(adata = "") ciphertext_with_counter =
  let len = String.length ciphertext_with_counter in
  if len < 8 then Error "ciphertext too short"
  else
    let counter_bytes = Bytes.of_string (String.sub ciphertext_with_counter 0 8) in
    let counter = Bytes.get_int64_be counter_bytes 0 in
    if Int64.compare counter session.recv_counter < 0 then
      Error "replay: counter not advancing"
    else
      let nonce = build_nonce ~counter ~direction in
      let ct = String.sub ciphertext_with_counter 8 (len - 8) in
      let key = Mirage_crypto.Chacha20.of_secret session.key in
      match Mirage_crypto.Chacha20.authenticate_decrypt ~key ~nonce ~adata ct with
      | None -> Error "AEAD authentication failed"
      | Some pt ->
        session.recv_counter <- Int64.add counter 1L;
        Ok pt
