type keypair = { priv : string; pub_ : string }

type session

val generate_keypair : unit -> keypair
val derive_session_key :
  local_priv:string -> remote_pub:string -> salt:string -> string
val create_session : key:string -> session
val encrypt :
  session ->
  direction:[ `To_server | `To_client ] ->
  ?adata:string ->
  string ->
  (string, string) result
val decrypt :
  session ->
  direction:[ `To_server | `To_client ] ->
  ?adata:string ->
  string ->
  (string, string) result
