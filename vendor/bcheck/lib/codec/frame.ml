let magic = "\x4F\x43"
let max_body_size = ref 10_000_000

let ( let* ) = Result.bind

let seal session ~direction msg =
  let plaintext = Schema.serialize msg in
  let ciphertext_len = String.length plaintext + 24 in
  if ciphertext_len > !max_body_size then
    Error
      (Printf.sprintf "message too large: %d > %d" ciphertext_len
         !max_body_size)
  else
    let header = Bytes.create 6 in
    Bytes.blit_string magic 0 header 0 2;
    Bytes.set_int32_be header 2 (Int32.of_int ciphertext_len);
    let adata = Bytes.to_string header in
    let* ciphertext = Cipher.encrypt session ~direction ~adata plaintext in
    let buf = Buffer.create (6 + ciphertext_len) in
    Buffer.add_string buf adata;
    Buffer.add_string buf ciphertext;
    Ok (Buffer.contents buf)

let open_ session ~direction data =
  let data_len = String.length data in
  if data_len < 6 then Error "envelope too short"
  else if String.sub data 0 2 <> magic then Error "bad magic"
  else
    let body_len =
      Int32.to_int (Bytes.get_int32_be (Bytes.of_string data) 2)
    in
    if body_len < 0 || body_len > !max_body_size then
      Error (Printf.sprintf "body length out of range: %d" body_len)
    else if data_len < 6 + body_len then
      Error
        (Printf.sprintf "envelope truncated: need %d, have %d" (6 + body_len)
           data_len)
    else
      let adata = String.sub data 0 6 in
      let ciphertext = String.sub data 6 body_len in
      let* plaintext = Cipher.decrypt session ~direction ~adata ciphertext in
      Schema.deserialize plaintext
