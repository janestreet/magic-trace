type t

(* Module for representing the necessary information to follow effect operations for
   OxCaml programs compiled with <https://github.com/oxcaml/oxcaml/pull/6274> *)

module Kind : sig
  type t =
    | Runstack_enter
    | Runstack_exit
    | Runstack_exn
    | Perform_enter
    | Resume_enter
    | Resume_premepted
end

val create : offsets:int64 array -> t
val categorize : t -> Event.Location.t -> Kind.t or_null
val is_exn_handler : t -> Event.Location.t -> bool
