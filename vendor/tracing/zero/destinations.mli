open! Core

(** Write to a file using synchronous writes, not suitable for low latency applications. *)
val direct_file_destination
  :  ?buffer_size:int
  -> filename:string
  -> unit
  -> (module Writer_intf.Destination)

(** Write to a file in some way with the best available performance. *)
val file_destination : filename:string -> unit -> (module Writer_intf.Destination)

(** Write to a provided [Iobuf.t], throws an exception if the buffer runs out of space.
    Mostly intended for use in tests. After the [Destination] is closed, sets the window
    of the [Iobuf.t] to the data written. *)
val iobuf_destination
  :  (read_write, Iobuf.seek) Iobuf.t
  -> (module Writer_intf.Destination)

(** Creates a new buffer, which is reset and reused on every call to [next_buf],
    effectively dropping all the previously-recorded content, as the name suggests.
    Useful for performance benchmarking or having trace
    events be ignored without growing an in-memory log.

    [len] is the length of the buffer and can be tuned to simulate different cache
    characteristics in a benchmark or avoid using much memory when ignoring events.

    If [touch_memory] is true, the memory will be written over to ensure all the
    memory is paged in, to reduce benchmark variance. *)
val black_hole_destination
  :  len:int
  -> touch_memory:bool
  -> (module Writer_intf.Destination)

(** Starts by keeping events in internal memory buffers. After [set_destination] is called
    it will copy any buffered events into the new destination upon the next buffer switch,
    then provide a buffer directly from the newly set destination.

    This is intended for use with a global trace writer which needs to be available from
    initialization time, before anything like a trace file has been set up.

    It also provides one other feature not guaranteed by other destinations, which is that
    writes after [close] is called will be ignored without error. This behavior was chosen
    so that when adding performance instrumentation to functions, users don't have to
    worry about those functions potentially being called in late stages of application
    shutdown after a trace file has been closed. *)
module Buffer_until_initialized : sig
  type t

  val create : unit -> t
  val set_destination : t -> (module Writer_intf.Destination) -> unit
  val to_destination : t -> (module Writer_intf.Destination)
end
