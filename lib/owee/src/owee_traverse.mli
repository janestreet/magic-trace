
(** WIP, a tool for generating explicit graphs out of marked objects *)
type location = Owee_location.t

type 'a trace = Trace of int * string * 'a list * 'a trace list lazy_t

val dump_trace : location trace list -> unit
val dump_graphviz : location trace list -> out_channel -> unit

val extract_trace : ?search_depth:int -> 'a -> location trace list
