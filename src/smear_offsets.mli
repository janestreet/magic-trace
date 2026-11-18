(** Emit floor(gap * preceding_calls / (num_calls + 1)) for each event. The positive
    gap is measured to the next distinct timestamp. Every emitted offset is strictly
    below that gap. Consecutive events may share an offset at nanosecond resolution. *)
val iter
  :  duration_ns:int
  -> num_calls:int
  -> length:int
  -> consumes_time:(int -> bool)
  -> f:(int -> int -> unit)
  -> unit
