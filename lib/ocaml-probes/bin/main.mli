val attach : pid:int -> bpf:bool -> actions:Probes_lib.actions -> unit

val trace
  :  prog:string
  -> args:string list
  -> bpf:bool
  -> actions:Probes_lib.actions
  -> unit

val info : pid:int -> bpf:bool -> unit
