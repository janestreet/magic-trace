(** Mutable representation of OCaml probes in the traced program. Not thread safe.
    Use with only one tracer thread. *)
type t

exception Error of string

type pid = int
type probe_name = string

type probe_state =
  { name : probe_name
  ; enabled : bool
  }

type pattern

(** Constructor for patterns from string using Str.regexp notation.  *)
val pattern : string -> pattern

type probe_desc =
  | Name of probe_name
  | Pair of probe_name * probe_name (** start and end probes semantics *)
  | Regex of pattern (** all probe names that match the regexp pattern *)
  | Predicate of (probe_name -> bool)
  (** all probe names for which the predicate is true *)

type action =
  | Enable
  | Disable

type actions =
  | All of action (** does not require knowing the available probe names *)
  | Selected of (action * probe_desc) list

(** Reads the entire elf binary [prog] and extracts probes descriptions from
    its stapstd .notes section. Memory and time are linear in the size of the
    binary, so can be slow for large binaries. Does not require the program
    to be running.

    [check_prog] is false by default. If [check_prog] is true,
    any changes to a running process by pid will be guarded by a check
    that the program executed by pid is [prog]. *)
val create : check_prog:bool -> prog:string -> t

(** Returns the names of probes available in the program associated with [t].
    The array is sorted and containts no duplicates. *)
val get_probe_names : t -> probe_name array

(** Check which probes are enabled in the process [pid].

    The check is based on reading the values of counters associated with each probe name
    (see [trace_existing_process]).

    If instances of a probe with a certain name have different states (i.e., some are
    enabled in the code at the probe site and some are not, or the code at probe site is
    inconsistent with the counter), the corresponding entry in the result array is
    undefined.

    [atomically] indicates whether the check should be
    performed atomically using ptrace's PEEK,
    or not atomically using process_vm_readv (default).
*)
val get_probe_states : ?atomically:bool -> t -> pid:pid -> probe_state array

(** Enable and disable probes in a running process [pid] according to [actions].

    Uses a counter per probe name to track the number of times a probe was
    enabled/disabled.

    If a probe is disabled, trying to disable it again is an error.

    If [force] is true, sets the state of the probes and counters to be as specified by
    the actions, rather than updating it based on the counters. [force] should be false
    when [trace_existing_process] is called from a library, to allow clients of the
    library to update the same probes correctly.

    [atomically] indicates whether the update of counters should be performed atomically
    using ptrace's PEEK and POKE, or not atomically using a combination of ptrace's POKE
    and faster process_vm_read (default).
*)
val trace_existing_process
  :  ?atomically:bool
  -> ?force:bool
  -> t
  -> pid:pid
  -> actions:actions
  -> unit

(** Execute the program with [args] and enable probes as specified in [actions], before
    running any code that might hit a probe.  By default, all probes start as disabled
    when the program executed directly (without tracing). Disable [actions] are ignored.

    Always performed atomically using ptrace. *)
val trace_new_process : t -> args:string list -> actions:actions -> pid

(** Utility to get the name of the binary executed by process [pid]. Read
    from /proc/pid/exe *)
val get_exe : pid -> string

(** Control debug printing. *)
val set_verbose : bool -> unit

(** Get and update the state of probes in the same process. Not atomic.  *)
module Self : sig
  val update : ?force:bool -> actions -> unit
  val get_probe_states : unit -> probe_state array
end

(** For expert use only.
    Use [trace_existing_process ~atomically:true] and [trace_new_process] if possible,
    they do [With_ptrace] under the hood.

    Atomically get and update the state of probes using ptrace.
    A simple state machine checks that the process is stopped before trying to
    get or update the state of probes:

    (attach . (update | get_probe_state)* . detach
*)
module With_ptrace : sig
  (** Attach to the process with [pid], and stop it to allow probe update. *)
  val attach : t -> pid -> unit

  val start : t -> args:string list -> pid

  (** Enable/disable probes. Raise if not attached to any process. [update]
      writes to memory of the process that must have been already stopped by
      [attach]. [update] does not continue process execution and can
      be invoked more than once. Invoke [detach] to continue process execution
      after all updates are done.

      [force] see [trace_existing_process]
  *)
  val update : ?force:bool -> t -> actions:actions -> unit

  (** Check which probes are enabled in the current process. Raise if not
      attached. *)
  val get_probe_states : ?probe_names:probe_name array -> t -> probe_state array

  (** Let the process continue its execution and detach from it. *)
  val detach : t -> unit
end

(** These don't actually have anything to do with probes, they're just exposed versions
    of the C stubs used to start a process paused with ptrace and then detach from it.

    The ability to start a paused process can be useful in other contexts. *)
module Raw_ptrace : sig
  val start : argv:string array -> pid
  val detach : pid -> unit
end
