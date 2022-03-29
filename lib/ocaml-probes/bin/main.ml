module P = Probes_lib

let info ~pid ~bpf:_ =
  let prog = P.get_exe pid in
  let t = P.create ~prog ~check_prog:false in
  let probes = P.get_probe_states t ~pid in
  Array.iter
    (fun (p : P.probe_state) ->
       Printf.printf "%s %s\n" p.name (if p.enabled then "enabled" else "disabled"))
    probes
;;

let attach ~pid ~bpf:_ ~(actions : P.actions) =
  let prog = P.get_exe pid in
  let t = P.create ~prog ~check_prog:false in
  P.trace_existing_process t ~pid ~actions
;;

let trace ~prog ~args ~bpf:_ ~(actions : P.actions) =
  let t = P.create ~prog ~check_prog:false in
  ignore (P.trace_new_process t ~args ~actions : P.pid)
;;
