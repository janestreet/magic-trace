type t = {
  poll :
    session:Bcheck_codec.Cipher.session ->
    msg:Bcheck_codec.Schema.message ->
    (Bcheck_codec.Schema.message list, string) result Lwt.t;
  send_result :
    session:Bcheck_codec.Cipher.session ->
    Bcheck_codec.Schema.message ->
    (unit, string) result Lwt.t;
  jittered_sleep : unit -> unit Lwt.t;
}
