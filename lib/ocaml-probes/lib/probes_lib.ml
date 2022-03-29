exception Error of string

let (_ : unit) =
  Callback.register_exception "caml_probes_lib_stub_exception" (Error "any string")
;;

type pid = int
type probe_name = string

(* Keep in sync with [enum Mode] in stubs.c *)
type mode =
  | Mode_self
  | Mode_ptrace
  | Mode_vm

external stub_realpath : string -> string = "probes_lib_realpath"
external stub_start_ptrace : argv:string array -> pid = "probes_lib_start_ptrace"
external stub_attach : pid -> unit = "probes_lib_attach"
external stub_detach : pid -> unit = "probes_lib_detach"
external stub_set_verbose : bool -> unit = "probes_lib_set_verbose"

external stub_write_semaphore
  :  mode
  -> pid
  -> int64 array
  -> int
  -> unit
  = "probes_lib_write_semaphore"

external stub_read_semaphore : mode -> pid -> int64 -> int = "probes_lib_read_semaphore"

external stub_write_probe_sites
  :  mode
  -> pid
  -> int64 array
  -> bool
  -> unit
  = "probes_lib_write_probes"

type probe_state =
  { name : probe_name
  ; enabled : bool
  }

type pattern = string * Str.regexp

let pattern s = s, Str.regexp s

(** Stores the string representation of the pattern,
    because we need it for error messages, and
    there seem to be no way to print a compiled Str.regexp as a string.  *)
type probe_desc =
  | Name of probe_name
  | Pair of probe_name * probe_name (** start and end probes semantics *)
  | Regex of pattern (** all probe names that match the regexp *)
  | Predicate of (probe_name -> bool)
  (** all probe names for which the predicate is true *)

type action =
  | Enable
  | Disable

type actions =
  | All of action
  | Selected of (action * probe_desc) list

type process =
  { id : pid
  ; mmap : Mmap.t option
  (** Some memory map for a position independent executable, None
      otherwise *)
  }

type status =
  | Attached of process
  | Not_attached

type t =
  { mutable status : status (** for ptrace operations *)
  ; check_prog : bool
  (** check that the program executed by pid is elf.filename
      before making changes to process pid  *)
  ; elf : Elf.t
  ; probe_names : probe_name array (** ordered alphabetically, no duplicates *)
  }

let verbose = ref false

let set_verbose b =
  verbose := b;
  stub_set_verbose b;
  Mmap.verbose := b;
  ()
;;

let desc_to_string t probe_desc =
  match probe_desc with
  | Name n -> n
  | Pair (start, stop) -> start ^ ", " ^ stop
  | Regex (s, _) -> s
  | Predicate p -> Array.to_list t.probe_names |> List.filter p |> String.concat ","
;;

let get_exe pid = Unix.readlink (Printf.sprintf "/proc/%d/exe" pid)

let (_ : unit) =
  Callback.register_exception "probes_lib_stub_exception" (Error "any string")
;;

let create ~check_prog ~prog =
  let filename = stub_realpath prog in
  if !verbose then Printf.printf "create: read probe notes from %s\n" filename;
  let elf = Elf.create ~filename in
  let probe_names = Hashtbl.to_seq_keys elf.probes |> Array.of_seq in
  Array.fast_sort String.compare probe_names;
  if !verbose
  then
    if Array.length probe_names = 0
    then Printf.printf "No probes found in %s\n" prog
    else Array.iteri (fun i name -> Printf.printf "%d:%s\n" i name) probe_names;
  { probe_names; elf; status = Not_attached; check_prog }
;;

let is_self pid = Int.equal pid (Unix.getpid ())

let get_mmap t id =
  match t.elf.pie with
  | false -> None
  | true -> Some (Mmap.read ~pid:id t.elf)
;;

let get_probe_names t = t.probe_names

module Semaphore : sig
  type t = private int

  val create : int -> t
  val is_enabled : t -> bool
  val init : bool -> int
  val get : t -> int
  val incr : t -> t
  val decr : t -> t
end = struct

  (** Semaphore is unsigned 2 bytes long integer value, represented as int. *)
  type t = int

  let max = (1 lsl 16) - 1 (* 0xffff *)

  let is_enabled t = t > 0
  let init enabled = if enabled then 1 else 0
  let get t = t

  let create t =
    if t < 0 || t > max
    then
      raise
        (Error
           (Printf.sprintf
              "Semaphore.create %d. Semaphore must be non-negative greater or equal to \
               %d."
              t
              max));
    t
  ;;

  let incr t =
    if t < max
    then t + 1
    else
      raise
        (Error
           (Printf.sprintf
              "Semaphore.incr overflow: semaphore %d. Semaphore must be non-negative \
               greater or equal to %d."
              t
              max))
  ;;

  let decr t =
    if t > 0
    then t - 1
    else
      raise
        (Error
           (Printf.sprintf
              "Semaphore.decr underflow: semaphore is %d. Semaphore must be non-negative."
              t))
  ;;
end

let opcode_address addr ~offset = Int64.add (Int64.add addr offset) (* skip NOP byte *) 1L

let probe_sites (mmap : Mmap.t option) (probe : Elf.probe_info) =
  let offset =
    match mmap with
    | None -> 0L
    | Some mmap -> mmap.vma_offset_text
  in
  Array.map (fun address -> opcode_address address ~offset) probe.sites
;;

let semaphore_addresses (mmap : Mmap.t option) (probe : Elf.probe_info) =
  let offset =
    match mmap with
    | None -> 0L
    | Some mmap -> mmap.vma_offset_semaphores
  in
  Array.map (Int64.add offset) probe.semaphores
;;

let read_semaphore mode pid addresses =
  (* Assumes that all semaphores have the same values *)
  stub_read_semaphore mode pid addresses.(0) |> Semaphore.create
;;

(* Reads the value of probe semaphores in process's memory. An
   alternative implementation (for example, if semaphores aren't in use),
   could be to check the instruction at the probe in the text section. *)
let get_states ?probe_names t ~mode ~pid ~mmap =
  let probe_names =
    match probe_names with
    | None -> t.probe_names
    | Some a -> a
  in
  let semaphores =
    Array.map
      (fun name ->
         let probe = Elf.find_probe_note t.elf name in
         let addresses = semaphore_addresses mmap probe in
         read_semaphore mode pid addresses)
      probe_names
  in
  Array.map2
    (fun name sem ->
       let enabled = Semaphore.is_enabled sem in
       if !verbose then Printf.printf "%s enabled: %b\n" name enabled;
       { name; enabled })
    probe_names
    semaphores
;;

let action_to_bool action =
  match action with
  | Enable -> true
  | Disable -> false
;;

let write_probe_sites mode pid addresses enable =
  match mode with
  | Mode_vm ->
    stub_attach pid;
    stub_write_probe_sites Mode_ptrace pid addresses enable;
    stub_detach pid
  | Mode_self | Mode_ptrace -> stub_write_probe_sites mode pid addresses enable
;;

let update_one ?(force = false) t ~action ~name ~pid ~mode ~mmap =
  let probe = Elf.find_probe_note t.elf name in
  let sem_addresses = semaphore_addresses mmap probe in
  let addresses = probe_sites mmap probe in
  let enable = action_to_bool action in
  let module S = Semaphore in
  if force
  then (
    let v = S.init enable in
    stub_write_semaphore mode pid sem_addresses v;
    write_probe_sites mode pid addresses enable)
  else (
    let sem_old = stub_read_semaphore mode pid sem_addresses.(0) |> S.create in
    let sem_new =
      match action with
      | Enable -> S.incr sem_old
      | Disable -> S.decr sem_old
    in
    stub_write_semaphore mode pid sem_addresses (S.get sem_new);
    let state_change = not Semaphore.(is_enabled sem_old = is_enabled sem_new) in
    if state_change then write_probe_sites mode pid addresses enable)
;;

let update ?force t ~pid ~actions ~mode ~mmap =
  let f name action = update_one ?force t ~action ~name ~pid ~mode ~mmap in
  let update_from_desc (action, desc) =
    let f name = f name action in
    match desc with
    | Name name -> f name
    | Pair (start, stop) ->
      (* Reduce the chance of recording an unclosed event by
         executing start when the matching stop is disabled. *)
      (match action with
       | Enable ->
         f stop;
         f start
       | Disable ->
         f start;
         f stop)
    | Regex (_, regexp) ->
      Array.iter (fun name -> if Str.string_match regexp name 0 then f name) t.probe_names
    | Predicate p -> Array.iter (fun name -> if p name then f name) t.probe_names
  in
  match actions with
  | All action -> Array.iter (fun name -> f name action) t.probe_names
  | Selected l -> List.iter update_from_desc l
;;

let check_prog t prog =
  if t.check_prog
  then
    if not (String.equal prog t.elf.filename)
    then
      raise
        (Error
           (Printf.sprintf
              "Start: prog is %s but probe notes come from %s\n"
              prog
              t.elf.filename))
;;

let check_prog_by_pid t pid =
  if t.check_prog
  then (
    let exe = get_exe pid in
    check_prog t exe)
;;

module With_ptrace = struct
  (* Updates [t.status] after stub to ensure stub didn't raise *)
  let set_status t id = t.status <- Attached { id; mmap = get_mmap t id }

  let start t ~args =
    let prog = t.elf.filename in
    let argv = Array.of_list (prog :: args) in
    if !verbose
    then (
      Printf.printf "start";
      Array.iter (fun s -> Printf.printf " %s" s) argv;
      Printf.printf "\n");
    check_prog t prog;
    match t.status with
    | Attached existing_p ->
      raise
        (Error
           (Printf.sprintf "Cannot start %s, already attached to %d" prog existing_p.id))
    | Not_attached ->
      let pid = stub_start_ptrace ~argv in
      set_status t pid;
      pid
  ;;

  let attach t pid =
    if !verbose then Printf.printf "attach to pid %d\n" pid;
    check_prog_by_pid t pid;
    if !verbose then Printf.printf "pid %d executing %s\n" pid t.elf.filename;
    match t.status with
    | Attached existing_p ->
      if Int.equal existing_p.id pid
      then raise (Error (Printf.sprintf "Already attached to %d" pid))
      else
        raise
          (Error
             (Printf.sprintf
                "Cannot attach to %d, already attached to %d"
                pid
                existing_p.id))
    | Not_attached ->
      if is_self pid then raise (Error (Printf.sprintf "Cannot attach to itself %d" pid));
      stub_attach pid;
      set_status t pid
  ;;

  let update ?force t ~actions =
    match t.status with
    | Not_attached -> raise (Error "update failed: no pid\n")
    | Attached p -> update ?force t ~actions ~pid:p.id ~mode:Mode_ptrace ~mmap:p.mmap
  ;;

  let get_probe_states ?probe_names t =
    match t.status with
    | Not_attached -> raise (Error "cannot get probe states: no pid\n")
    | Attached p -> get_states ?probe_names t ~pid:p.id ~mmap:p.mmap ~mode:Mode_ptrace
  ;;

  (* We use PTRACE_DETACH and not PTRACE_CONT: After sending PTRACE_CONT signal
     to the child process, the parent needs to stop the child process again to
     make updates to probes, and the only way to stop is to send PTRACE_ATTACH.
     It means it is not useful to stay attached after continue, because the
     tracer cannot do anything with the probes. An alternative is to use
     PTRACE_SEIZE instead of PTRACE_ATTACH and then explicitly interrupt to
     stop the process. This way the tracer can remain attached to the child.
     (Is it required for bpf?) The advantage of detaching is that it allows
     another tool such as gdb to attach. Only one parent can be attached at any
     give time. *)
  let detach t =
    match t.status with
    | Not_attached -> raise (Error "detach failed: no pid\n")
    | Attached p ->
      stub_detach p.id;
      t.status <- Not_attached
  ;;
end

module Raw_ptrace = struct
  let start = stub_start_ptrace
  let detach = stub_detach
end

module Self = struct
  let prog = Sys.executable_name
  let t = lazy (create ~prog ~check_prog:false)
  let pid = Unix.getpid ()
  let mmap = lazy (get_mmap (Lazy.force t) pid)

  (** cannot use ptrace on itself, it will be stuck! *)
  let mode = Mode_self

  let update ?force actions =
    update ?force (Lazy.force t) ~pid ~actions ~mmap:(Lazy.force mmap) ~mode
  ;;

  let get_probe_states () = get_states (Lazy.force t) ~pid ~mmap:(Lazy.force mmap) ~mode
end

exception Nothing_to_enable

let trace_new_process t ~args ~actions =
  try
    (* All probes are disabled initially, only enable actions matter at start.
       Filter out disabled actions. *)
    let actions =
      match actions with
      | All Disable ->
        if !verbose
        then
          Printf.printf "Ignoring -disable-all with trace: all probes start as disabled\n";
        raise Nothing_to_enable
      | All Enable ->
        if Hashtbl.length t.elf.probes = 0 then raise Nothing_to_enable;
        actions
      | Selected x ->
        let y =
          List.filter
            (fun (action, desc) ->
               match action with
               | Disable ->
                 if !verbose
                 then
                   Printf.printf
                     "Ignoring -disable %s with trace: all probes start as disabled.\n"
                     (desc_to_string t desc);
                 false
               | Enable -> true)
            x
        in
        if List.length y = 0 then raise Nothing_to_enable;
        Selected y
    in
    let module P = With_ptrace in
    let pid = P.start t ~args in
    P.update ~force:true t ~actions;
    P.detach t;
    pid
  with
  | Nothing_to_enable ->
    (* Use ptrace even if there is nothing to enable because ptrace
       waits until child is fully loaded and running if update probes
       happens to run immediately upon the return of this function. *)
    let module P = With_ptrace in
    let pid = P.start t ~args in
    P.detach t;
    pid
;;

let trace_existing_process ?(atomically = false) ?force t ~pid ~(actions : actions) =
  match is_self pid with
  | true ->
    if atomically
    then raise (Error "trace_existing_process: cannot trace 'self' process atomically ");
    check_prog t Self.prog;
    Self.update ?force actions
  | false ->
    (match t.status with
     | Attached p when Int.equal p.id pid ->
       update ?force t ~mode:Mode_ptrace ~pid:p.id ~mmap:p.mmap ~actions
     | Attached _ | Not_attached ->
       (match atomically with
        | true ->
          let module P = With_ptrace in
          P.attach t pid;
          P.update t ~actions;
          P.detach t
        | false -> update ?force t ~mode:Mode_vm ~pid ~actions ~mmap:(get_mmap t pid)))
;;

let get_probe_states ?(atomically = false) t ~pid =
  match is_self pid with
  | true ->
    if atomically
    then raise (Error "get_probe_states: cannot trace 'self' process atomically ");
    check_prog t Self.prog;
    Self.get_probe_states ()
  | false ->
    (match t.status with
     | Attached p when Int.equal p.id pid ->
       get_states t ~mode:Mode_ptrace ~pid:p.id ~mmap:p.mmap
     | Attached _ | Not_attached ->
       (match atomically with
        | true ->
          let module P = With_ptrace in
          P.attach t pid;
          let probe_states = P.get_probe_states t in
          P.detach t;
          probe_states
        | false -> get_states t ~mode:Mode_vm ~pid ~mmap:(get_mmap t pid)))
;;
