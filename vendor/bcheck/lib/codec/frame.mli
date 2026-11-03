val max_body_size : int ref

val seal :
  Cipher.session ->
  direction:[ `To_server | `To_client ] ->
  Schema.message ->
  (string, string) result

val open_ :
  Cipher.session ->
  direction:[ `To_server | `To_client ] ->
  string ->
  (Schema.message, string) result
