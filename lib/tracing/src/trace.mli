(** Write a trace in the Fuchsia Trace Format using a high level API. This allows you to
    convert your data to a trace and view it on an interactive timeline in Perfetto.

    This module provides a wrapper around [Tracing_zero.Writer.t] which makes it easier to
    write traces with less steps and more normal OCaml types.

    However, unlike [Tracing_zero.Writer.t], this module allocates and doesn't pay close
    attention to its performance. It should still be fast enough for most offline
    converters though.

    See [app/tracing/bin/dominodb_converter.ml] for an example of something using this API
    to visualize some performance data as a trace.

    {2 Viewing traces}

    You can view traces in the Perfetto web UI available at
    https://ui.perfetto.dev/

    Use the "Open trace file" menu item on the left to select a trace file to view.

    {2 String interning}

    All [string]s in this API with the exception of [Arg.String] event arguments are
    interned in a lasting way such that every further use will just refer to the string by
    an identifier rather than putting it in the file again. This means long names and
    categories are fine and won't bloat the file too much if you create lots of events
    with them.

    However, there's currently a limit of around 32k interned strings shared between
    names, categories and [Arg.Interned] arguments. If you exceed that limit the library
    will assert. We expect nearly every use case won't come close to this limit, but if
    you have a use case that does let us know and we can add logic to evict old strings
    from the interning slots for re-use.

    {2 Times: relative and absolute}

    Time instants are provided as a Time_ns.Span.t from the start of the trace. If you have
    absolute times you should subtract the time of the start of your trace or the start of
    the day the trace was taken (see [dominodb_converter.ml] in app/tracing for code).
    Then provide [base_time] to [create] so that tools which need absolute time can use it
    to for example merge traces while aligning time properly.

    Avoid converting a Time_ns.t to a span since epoch, because although the format uses
    64-bit nanoseconds, the Perfetto trace viewer visualizes using Javascript doubles so
    large timestamps like this will cause weird imprecision in where events are drawn due
    to rounding of large numbers.
*)

open! Core

type t

(** Open a file to write trace events to in the Fuchsia Trace Format, suggested extension
    is [.ftf].

    If [base_time] is provided, a time initialization record will be written which
    records what absolute time corresponds to [Time_ns.Span.zero]. *)
val create_for_file : base_time:Time_ns.t option -> filename:string -> t

(** Signifies that all writing is done, any further writing will throw an exception.

    Just calls [close] on the underlying writer. *)
val close : t -> unit

(** Translate an absolute time to trace time. If [base_time] was provided it subtracts that,
    asserting if the time is before the base time. Otherwise it measures relative to unix
    epoch. If you already have times relative to a trace start time there's no need to use
    this. *)
val translate_time : t -> Time_ns.t -> Time_ns.Span.t

(** The format uses pids and tids to represent processes and threads, and the wrapper can
    allocate pids for processes and set the process name for you.

    Processes are sorted by pid in the Perfetto UI, and PIDs are allocated in order. *)
val allocate_pid : t -> name:string -> int

module Thread : sig
  type t
end

(** Allocate a tid and name a new the thread for a process.

    Threads are sorted by alphabetical order within a process in the Perfetto UI.*)
val allocate_thread : t -> pid:int -> name:string -> Thread.t

(* Wrappers for Tracing_zero.Writer events with an easier-to-use interface.

   See the [Tracing_zero.Writer.t] docs for more on what these events are. *)

(** Named arguments of various simple types can be attached to events and will show up
    in the bottom details panel when an event is selected in Perfetto. *)
module Arg = Trace_intf.Event_arg

(** The [name] shows up as the main label of the event in UIs, and the category is another
    string that can be used to classify the event, and is visible in Perfetto when an
    event is clicked on. *)
type 'a event_writer =
  t
  -> args:Arg.t list
  -> thread:Thread.t
  -> category:string
  -> name:string
  -> time:Time_ns.Span.t
  -> 'a

(** An event with a time but no duration

    Note: instant events currently are not visible in the Perfetto UI. *)
val write_instant : unit event_writer

(** Same as [write_instant] except guaranteed to be visible in visualization UIs and
    usable with flow events.

    Currently this uses [write_duration_complete] with an identical begin and end time,
    which shows up in Perfetto as chevron pointing at that time. In the future if we
    change Perfetto to be able to show instant events we may search for usages of this
    function which don't use flow events and replace them with [write_instant]. *)
val write_duration_instant : unit event_writer

(** A counters event uses its arguments to specify "counters" which may be represented by
    trace viewers as a chart over time. Its arguments must be [Arg.Int] or [Arg.Float] and
    there should be at least one.

    The spec says that multiple arguments in the same counter event should be
    representable as a stacked area chart, and otherwise you should use multiple counter
    events. At the moment Perfetto doesn't implement this and instead ignores the counter
    ID and represents each argument as a separate line chart.

    Counter events are grouped into a chart labeled "<event name>:<argument name>" per
    thread that name pair is used on.
*)
val write_counter : unit event_writer

(** Begin a duration slice which will be finished with a matching end event.

    A "duration slice" starts and ends at different times but has a single name
    and category. It shows up as a bar between the start and end time in UIs.

    Duration slices within a thread should be nested properly such that if a duration
    slice starts within another slice then it must end before that slice ends. *)
val write_duration_begin : unit event_writer

(** End a duration slice, should be properly nested and with matching name/category *)
val write_duration_end : unit event_writer

(** Create a duration slice where the start and end are known up front.

    Takes 3*8 bytes instead of 2*2*8 bytes for separate begin/end events, saving 8 bytes
    per slice *)
val write_duration_complete : (time_end:Time_ns.Span.t -> unit) event_writer

(** Flows are chains of duration slices which get connected by arrows when selected in
    a trace viewer UI. A flow is composed of "steps", each of which must be written at a
    time contained in a duration slice, and when one of those slices is selected in the UI
    it will display arrows connecting the slices of each step in order like this:

    {v
      [    my_slice_1     ] ---> [ my_slice_2 ] -\   [slice_not_in_flow_2 ]
      [      slice_not_in_flow       ]            \-----------> [ my_slice_3 ]
    v}

    Flows have identity and can consist of multiple steps, which allows selecting one
    duration slice with an associated flow to show the arrows for all steps of that flow.
    Perfetto also allows the user to navigate through the steps of a flow with the square
    bracket keys. *)
val create_flow : t -> Flow.t

(** Add a step to a flow, which will connect to the duration event enclosing the provided
    time on that thread. Specifically there needs to be a duration slice on the given
    thread with a start time less than or equal to [time] and an end time greater than or
    equal to [time] and the flow event will be associated with the latest-starting (i.e
    most deeply nested) such enclosing slice. *)
val write_flow_step : t -> Flow.t -> thread:Thread.t -> time:Time_ns.Span.t -> unit

(** All flows must be "finished" before the end of the trace and after writing all steps.

    The representation of trace events in the file format requires us to hold one flow
    step in memory until either the next flow step or we finish adding steps, in order to
    know what kind of event to write out. Finishing a flow writes out any last buffered
    step.
*)
val finish_flow : t -> Flow.t -> unit

module Expert : sig
  (** Wraps a [Tracing_zero.Writer.t] to keep track of IDs and interned strings

      It's still safe to write to the writer directly after using this wrapper, as long as
      you use IDs allocated with the [allocate_*] functions and are aware that this module
      can overwrite strings using [set_temp_string_slot].

      See [create_for_file] for explanation of [base_time]. *)
  val create : base_time:Time_ns.t option -> Tracing_zero.Writer.t -> t
end
