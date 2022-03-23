open! Core

(** Abstraction for a source of buffers to write trace data to.

    At the moment this is used for the ability to both write to a file and to an in-memory
    buffer for tests.

    However I also tried to anticipate some of the structure of how the API would work
    which would be required to write to a shared-memory transport involving a ring or
    double-buffering system. *)
module type Destination = sig
  (** Called mainly when there isn't enough buffer space left to write a message of
      [ensure_capacity] bytes and a new buffer is needed. May also be called in certain
      other situations even if there's enough space in the previous buffer.
      Any older buffers will no longer be used after calling this function, so it's legal 
      for a [Destination] to re-use [Iobuf.t]s to avoid allocating. *)
  val next_buf : ensure_capacity:int -> (read_write, Iobuf.seek) Iobuf.t

  (** Record that the writer appended a certain number of bytes to the buffer, will be
      called some time after the bytes are written but before [next_buf] is called. *)
  val wrote_bytes : int -> unit

  (** We will no longer be writing anything. Resources should be flushed and freed. *)
  val close : unit -> unit
end

module type Arg_writers = sig
  type t
  type string_id

  val string : t -> name:string_id -> string_id -> unit
  val int32 : t -> name:string_id -> int -> unit
  val int64 : t -> name:string_id -> int -> unit
  val float : t -> name:string_id -> float -> unit
end

module Tick_translation = struct
  type t =
    { ticks_per_second : int
    ; base_ticks : int
    ; base_time : Time_ns.t
    }

  let epoch_ns =
    { ticks_per_second = 1_000_000_000; base_ticks = 0; base_time = Time_ns.epoch }
  ;;
end
