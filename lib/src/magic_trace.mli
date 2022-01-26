(** The magic-trace tool can work with any binary, but using these functions
    allows you to easily mark places in your code to take a snapshot, and enables
    additional features like passing a value and marking the start of a duration. *)

(** This is the default symbol that the magic-trace command will attach to and use to
    take a snapshot. Use it if you want to take a snapshot based on custom logic, and it
    will save you the step of selecting the symbol you want to stop on.

    It's an external C function that does nothing and should be very fast to call. It's
    only a C function to ensure it has a stable and exact symbol. *)
val take_snapshot : unit -> unit

(** Passes an integer along that will show up in the resulting trace *)
val take_snapshot_with_arg : int -> unit

(** Passes both the start tsc for the operation and an argument. *)
val take_snapshot_with_time_and_arg : Time_stamp_counter.t -> int -> unit

(** Mark the start time of some operation which may lead to a snapshot. *)
val mark_start : unit -> unit

(** Intended for use like so:

    {[
      let min_dur = Magic_trace.Min_duration.of_ns 3_000

      let my_fun a b c =
        Magic_trace.mark_start ();
        (* ... *)
        if Magic_trace.Min_duration.over min_dur then Magic_trace.take_snapshot ()
      ;;
    ]}

    which allows capturing only unusually long executions without adding the
    ~10us breakpoint overhead on every run while magic-trace is attached.

    See also the [-duration-thresh] flag for use in combination with this or
    instead of it if you can tolerate a 10us pause on every call.
*)
module Min_duration : sig
  type t

  (** This involves using and forcing [Time_stamp_counter.calibrator] so should probably
      be done only once at the top level as opposed to every time. *)
  val of_ns : int -> t

  (** Returns true if the time since [mark_start] is over the threshold *)
  val over : t -> bool
end

(** Internal details about how to interact with the snapshot function from outside *)
module Private : sig
  val stop_symbol : string
end
