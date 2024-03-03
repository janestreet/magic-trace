open! Core
open Writer_intf

(** We want to be able to write event arguments without allocating, which requires users
    specify the argument types they will pass up front. To avoid allocating a record to
    store those counts we pre-compile the fields of the event header which have to do
    with argument counts and total size into an immediate value. *)
module Header_template = struct
  type t = int

  let none = 0

  let create ?(int64s = 0) ?(int32s = 0) ?(floats = 0) ?(strings = 0) () =
    let num_args = int64s + floats + int32s + strings in
    let arg_words = (int64s * 2) + (floats * 2) + int32s + strings in
    (* This also guards [arg_words] since it has a much larger bound *)
    if num_args > 15 then failwithf "%i is over the 15 event argument limit" num_args ();
    (arg_words lsl 4) lor (num_args lsl 20)
  ;;

  let add_size t words = t + (words lsl 4)

  (* isolate the rsize field, which is a word count shifted to the left by 4 bits,
     we want the word count multiplied by 8, which is equivalent to the word count
     shifted left by 3 (2**3=8), so we just need to shift right by one. *)
  let byte_size t = (t land 0xFFF0) lsr 1

  (* Because of the two bitfields for total size and argument count, we can effectively
     treat the full [Header_template] as the sum of integers representing the arguments
     we've committed to. We can subtract integers representing those individual arguments
     to remove them from the template, and if we reach zero then we've subtracted
     compatible arguments. Except for issues involving overflow between the two fields,
     which are unlikely to happen accidentally in practice, and this is only used by
     a check to try to avoid writing invalid traces. See the comment for [pending_args]
     inside [flush]. *)
  let[@inline] remove_args t ?int64s ?int32s ?floats ?strings () =
    t - create ?int64s ?int32s ?floats ?strings ()
  ;;

  (* [pending_args] below is a trick to check that we've written arguments matching the
     signature we gave to the event writer function.

     If we set [pending_args] to the header when we write an event, and then use
     [remove_args] every time we write an argument, then if [pending_args] ends up being
     zero then the written arguments match the header. *)
  let check_none t =
    if t <> none
    then
      if t < none
      then failwith "too many args written for arg type signature"
      else failwith "not enough args written for arg type signature"
  ;;
end

(** In the public API it makes more sense for it to be named [Arg_types] since that's
    all the functionality which is exposed *)
module Arg_types = Header_template

type t =
  { mutable buf : (read_write, Iobuf.seek) Iobuf.t
  ; mutable notified_lo : int
  ; destination : (module Destination)
  ; mutable next_thread_id : int
  ; mutable next_string_id : int
  ; mutable num_temp_strs : int
  ; mutable pending_args : Header_template.t
  ; mutable word_to_flush : int
  ; mutable pending_word : bool
  }

module Tick_translation = Writer_intf.Tick_translation

let[@inline] write_int64 t i = Iobuf.Fill.int64_le t.buf i
let[@inline] write_int64_t t i = Iobuf.Fill.int64_t_le t.buf i

(* Due to the zero-alloc approach to writing arguments, some checking and writing needs
   to be delayed until all arguments have been written, which should be before the next
   event is written or the file is closed. *)
let flush t =
  Header_template.check_none t.pending_args;
  if t.pending_word
  then (
    write_int64 t t.word_to_flush;
    t.pending_word <- false)
;;

let notify_writes t =
  (* We don't notify on every write, just update on how much we've written since we last
     called [D.wrote_bytes]. *)
  let buf_lo = Iobuf.Expert.lo t.buf in
  let partially_written = buf_lo - t.notified_lo in
  let (module D : Destination) = t.destination in
  D.wrote_bytes partially_written;
  t.notified_lo <- buf_lo
;;

let[@cold] switch_buffers t ~ensure_capacity =
  notify_writes t;
  let (module D : Destination) = t.destination in
  let buf = D.next_buf ~ensure_capacity in
  t.buf <- buf;
  t.notified_lo <- Iobuf.Expert.lo buf;
  let buf_len = Iobuf.length t.buf in
  if buf_len < ensure_capacity
  then
    failwithf "new buffer too small: %i bytes < %i requested" buf_len ensure_capacity ()
;;

(* In probes we never leave events with a pending_word and use a PPX to ensure arguments
   are written correctly. So skip the flush for performance *)
let[@inline] ensure_capacity_no_flush t amount =
  if Iobuf.length t.buf < amount then switch_buffers t ~ensure_capacity:amount
;;

(* Everything that writes uses this call to allocate space beforehand, and should use one
   call to allocate all the space it needs, both for efficiency and so that no events are
   cut in half when buffers are dropped in any future shared memory transport. *)
let ensure_capacity t amount =
  flush t;
  ensure_capacity_no_flush t amount
;;

(* Because the format guarantees aligned 64-bit words, some things need to be padded to
   8 bytes. This is an efficient expression for doing that. *)
let padding_to_word x = -x land (8 - 1)

(* many size fields in FTF are based on number of words, since the format is based on
   everything being aligned 64-bit words. *)
let round_words_for bytes = (bytes + 8 - 1) / 8
let provider_name = "jane_tracing"

let write_string_stream t s =
  let len = String.length s in
  let padding = padding_to_word len in
  ensure_capacity t (len + padding);
  Iobuf.Fill.stringo t.buf s;
  (* Pad with zero bytes *)
  Iobuf.memset t.buf ~pos:0 ~len:padding Char.min_value;
  Iobuf.advance t.buf padding
;;

module String_id = struct
  type t = int [@@deriving equal]

  let empty = 0
  let process = 1
  let first_temp = 2
  let max_value = (1 lsl 15) - 1
  let max_number_of_temp_string_slots = max_value - first_temp + 1
end

(* maximum string length defined in spec, somewhat less than 2**15 *)
let max_interned_string_length = 32000 - 1

let set_string_slot t ~string_id s =
  let str_len = String.length s in
  if str_len > max_interned_string_length
  then failwithf "string too long for FTF trace: %i is over the limit of 32kb" str_len ();
  (* String record *)
  let rtype = 2 in
  let rsize = 1 + round_words_for str_len in
  ensure_capacity t (rsize * 8);
  write_int64 t (rtype lor (rsize lsl 4) lor (string_id lsl 16) lor (str_len lsl 32));
  write_string_stream t s
;;

let set_temp_string_slot t ~slot s =
  if slot >= t.num_temp_strs
  then failwithf "temp string slot over the limit: %i >= %i" slot t.num_temp_strs ();
  let string_id = slot + String_id.first_temp in
  set_string_slot t ~string_id s;
  string_id
;;

let intern_string t s =
  (* This is an easy mistake to make, so give a more specific error message *)
  if t.pending_args <> 0
  then failwith "can't intern strings while you still need to write arguments";
  let string_id = t.next_string_id in
  if string_id > String_id.max_value then failwith "ran out of FTF string IDs";
  t.next_string_id <- t.next_string_id + 1;
  set_string_slot t ~string_id s;
  string_id
;;

let num_temp_strs t = t.num_temp_strs

let write_header t =
  ensure_capacity t 8;
  (* Magic number record *)
  write_int64 t 0x0016547846040010;
  (* Provider info metadata *)
  let rtype = 0 in
  let name_len = String.length provider_name in
  let rsize = 1 + round_words_for name_len in
  let mtype = 1 in
  let provider_id = 0 in
  ensure_capacity t (rsize * 8);
  write_int64
    t
    (rtype
     lor (rsize lsl 4)
     lor (mtype lsl 16)
     lor (provider_id lsl 20)
     lor (name_len lsl 52));
  write_string_stream t provider_name;
  (* Provider section metadata *)
  let rtype = 0 in
  let rsize = 1 in
  let mtype = 2 in
  ensure_capacity t (rsize * 8);
  write_int64 t (rtype lor (rsize lsl 4) lor (mtype lsl 16) lor (provider_id lsl 20));
  (* String constants used internally *)
  set_string_slot t ~string_id:String_id.process "process";
  ()
;;

let write_tick_initialization t (tick_translation : Tick_translation.t) =
  let rtype = 1 in
  let rsize = 4 in
  ensure_capacity t (rsize * 8);
  write_int64 t (rtype lor (rsize lsl 4));
  write_int64 t tick_translation.ticks_per_second;
  write_int64 t tick_translation.base_ticks;
  write_int64 t (Time_ns.to_int_ns_since_epoch tick_translation.base_time)
;;

module Thread_id = struct
  type t = int

  let first = 1 (* 0 means inline so 1 is first valid value *)
end

let set_thread_slot t ~slot ~pid ~tid =
  let thread_id = slot + Thread_id.first in
  if thread_id >= 1 lsl 8 || thread_id <= 0
  then failwithf "thread slot outside of valid range [0,254]: %i" slot ();
  (* Thread record *)
  let rtype = 3 in
  let rsize = 3 in
  ensure_capacity t (rsize * 8);
  write_int64 t (rtype lor (rsize lsl 4) lor (thread_id lsl 16));
  write_int64 t pid;
  write_int64 t tid;
  thread_id
;;

let set_process_name t ~pid ~name =
  (* Kernel object record *)
  let rtype = 7 in
  let rsize = 2 in
  let num_args = 0 in
  let obj_type = 1 (* process *) in
  ensure_capacity t (rsize * 8);
  write_int64
    t
    (rtype lor (rsize lsl 4) lor (obj_type lsl 16) lor (name lsl 24) lor (num_args lsl 40));
  write_int64 t pid;
  ()
;;

let set_thread_name t ~pid ~tid ~name =
  (* Kernel object record *)
  let rtype = 7 in
  let arg_size = 2 in
  let rsize = 2 (* header *) + arg_size in
  let num_args = 1 in
  let obj_type = 2 (* thread *) in
  ensure_capacity t (rsize * 8);
  write_int64
    t
    (rtype lor (rsize lsl 4) lor (obj_type lsl 16) lor (name lsl 24) lor (num_args lsl 40));
  write_int64 t tid;
  (* Perfetto requires the thread to have an argument specifying the process ID *)
  let arg_type = 8 (* kernel object ID *) in
  let arg_name = String_id.process in
  write_int64 t (arg_type lor (arg_size lsl 4) lor (arg_name lsl 16));
  write_int64 t pid;
  ()
;;

type 'a event_writer =
  t
  -> arg_types:Arg_types.t
  -> thread:Thread_id.t
  -> category:String_id.t
  -> name:String_id.t
  -> ticks:int
  -> 'a

let[@inline] event_header ~counts ~event_type ~thread ~category ~name =
  Int64.(
    4L (* rtype *)
    lor of_int counts
    lor (of_int event_type lsl 16)
    lor (of_int thread lsl 24)
    lor (of_int category lsl 32)
    lor (of_int name lsl 48))
;;

module Event_type = struct
  type t = int

  let instant = 0
  let counter = 1
  let duration_begin = 2
  let duration_end = 3
  let duration_complete = 4
  let flow_begin = 8
  let flow_step = 9
  let flow_end = 10
end

let write_event t ~event_type ~extra_words ~arg_types ~thread ~category ~name ~ticks =
  (* Event record *)
  let counts = Header_template.add_size arg_types (2 + extra_words) in
  ensure_capacity t (Header_template.byte_size counts);
  t.pending_args <- arg_types;
  let header = event_header ~counts ~event_type ~thread ~category ~name in
  write_int64_t t header;
  write_int64 t ticks;
  ()
;;

(* I believe using currying for these would allocate or involve additional cost. *)

let write_instant t ~arg_types ~thread ~category ~name ~ticks =
  (* The [let writer] style avoids ocamlformat splitting these over a million lines.
     I checked under flambda it generates the same code as a single call. *)
  let writer = write_event t ~event_type:Event_type.instant ~extra_words:0 in
  writer ~arg_types ~thread ~category ~name ~ticks
;;

let write_counter t ~arg_types ~thread ~category ~name ~ticks ~counter_id =
  let writer = write_event t ~event_type:Event_type.counter ~extra_words:1 in
  writer ~arg_types ~thread ~category ~name ~ticks;
  t.word_to_flush <- counter_id;
  t.pending_word <- true
;;

let write_duration_begin t ~arg_types ~thread ~category ~name ~ticks =
  let writer = write_event t ~event_type:Event_type.duration_begin ~extra_words:0 in
  writer ~arg_types ~thread ~category ~name ~ticks
;;

let write_duration_end t ~arg_types ~thread ~category ~name ~ticks =
  let writer = write_event t ~event_type:Event_type.duration_end ~extra_words:0 in
  writer ~arg_types ~thread ~category ~name ~ticks
;;

let write_duration_complete t ~arg_types ~thread ~category ~name ~ticks ~ticks_end =
  if ticks_end < ticks
  then
    failwithf
      "duration_complete event must have start tick (%i) greater than end tick (%i)"
      ticks
      ticks_end
      ();
  let writer = write_event t ~event_type:Event_type.duration_complete ~extra_words:1 in
  writer ~arg_types ~thread ~category ~name ~ticks;
  t.word_to_flush <- ticks_end;
  t.pending_word <- true
;;

(* Flow events in the Fuchsia Trace Format are kind of weird in that they have a name,
   category and arguments. These are all just ignored by Perfetto and have no good way of
   being represented in its data model. The fact that these fields are in the FTF data
   model is probably a legacy of attempted consistency in the Chromium JSON format. We
   just set all these fields to dummy values. *)

let write_flow_begin t ~thread ~ticks ~flow_id =
  write_event
    t
    ~event_type:Event_type.flow_begin
    ~extra_words:1
    ~arg_types:Arg_types.none
    ~thread
    ~category:String_id.empty
    ~name:String_id.empty
    ~ticks;
  write_int64 t flow_id
;;

let write_flow_step t ~thread ~ticks ~flow_id =
  write_event
    t
    ~event_type:Event_type.flow_step
    ~extra_words:1
    ~arg_types:Arg_types.none
    ~thread
    ~category:String_id.empty
    ~name:String_id.empty
    ~ticks;
  write_int64 t flow_id
;;

let write_flow_end t ~thread ~ticks ~flow_id =
  write_event
    t
    ~event_type:Event_type.flow_end
    ~extra_words:1
    ~arg_types:Arg_types.none
    ~thread
    ~category:String_id.empty
    ~name:String_id.empty
    ~ticks;
  write_int64 t flow_id
;;

module Header_tag = struct
  let _null = 0
  let int32 = 1
  let _uint32 = 2
  let int64 = 3
  let _uint64 = 4
  let float = 5
  let string = 6
  let pointer = 7
  let _kernel_object_id = 8
end

module Write_arg_unchecked = struct
  (* None of the argument writers allocate capacity, the event does that. *)

  let string t ~name value =
    let asize = 1 in
    write_int64
      t
      (Header_tag.string lor (asize lsl 4) lor (name lsl 16) lor (value lsl 32))
  ;;

  let int32 t ~name value =
    let asize = 1L in
    (* int32 arguments can use the most significant bit, so we need to use Int64.t
       and we also need to be careful to truncate the int32 properly. *)
    write_int64_t
      t
      Int64.(
        of_int Header_tag.int32
        lor (asize lsl 4)
        lor (of_int name lsl 16)
        (* because we use Int64 this also truncates to 32 bits *)
        lor (of_int value lsl 32))
  ;;

  let int63 t ~name value =
    let asize = 2 in
    write_int64 t (Header_tag.int64 lor (asize lsl 4) lor (name lsl 16));
    write_int64 t value
  ;;

  let int64 t ~name value =
    let asize = 2 in
    write_int64 t (Header_tag.int64 lor (asize lsl 4) lor (name lsl 16));
    write_int64_t t value
  ;;

  let pointer t ~name value =
    let asize = 2 in
    write_int64 t (Header_tag.pointer lor (asize lsl 4) lor (name lsl 16));
    write_int64_t t value
  ;;

  let float t ~name value =
    let asize = 2 in
    write_int64 t (Header_tag.float lor (asize lsl 4) lor (name lsl 16));
    write_int64_t t (Int64.bits_of_float value)
  ;;
end

module Write_arg = struct
  let string t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~strings:1 ();
    Write_arg_unchecked.string t ~name value
  ;;

  let int32 t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~int32s:1 ();
    Write_arg_unchecked.int32 t ~name value
  ;;

  let int63 t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~int64s:1 ();
    Write_arg_unchecked.int63 t ~name value
  ;;

  let int64 t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~int64s:1 ();
    Write_arg_unchecked.int64 t ~name value
  ;;

  let pointer t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~int64s:1 ();
    Write_arg_unchecked.pointer t ~name value
  ;;

  let float t ~name value =
    t.pending_args <- Header_template.remove_args t.pending_args ~floats:1 ();
    Write_arg_unchecked.float t ~name value
  ;;
end

module Expert = struct
  module type Destination = Destination

  let create ?(num_temp_strs = 100) ~destination () =
    if num_temp_strs > String_id.max_number_of_temp_string_slots
    then failwith "num_temp_strs too large";
    (* If [num_temp_strs] is set to [String_id.max_number_of_temp_string_slots],
       [first_real_string] will be one greater than [String_id.max_value]. *)
    let first_real_string = String_id.first_temp + num_temp_strs in
    let (module D : Destination) = destination in
    let ensure_capacity = 8 in
    let buf = D.next_buf ~ensure_capacity in
    let t =
      { buf
      ; destination
      ; next_thread_id = Thread_id.first
      ; next_string_id = first_real_string
      ; num_temp_strs
      ; pending_args = Header_template.none
      ; word_to_flush = 0
      ; notified_lo = Iobuf.Expert.lo buf
      ; pending_word = false
      }
    in
    write_header t;
    t
  ;;

  let set_string_slot t ~slot s =
    let first_non_temp_slot = String_id.first_temp + t.num_temp_strs in
    if slot >= first_non_temp_slot
    then
      failwith
        "Cannot call [Expert.set_string_slot] with a slot that is not a temp string slot";
    if slot <= 0 then failwithf "string slot must be positive: slot %i <= 0" slot ();
    if slot = String_id.process
    then (
      if not String.(s = "process")
      then failwith "tried to overwrite the slot for the process string")
    else set_string_slot t ~string_id:slot s;
    slot
  ;;

  let force_switch_buffers t =
    flush t;
    switch_buffers t ~ensure_capacity:1
  ;;

  let flush_and_notify t =
    flush t;
    notify_writes t
  ;;

  type header = Int64.t

  module Event_type = Event_type

  (* See [Header_template.byte_size] comment, this is the same but with Int64 operations *)
  let[@inline] header_byte_size header =
    Int64.((header land 0xFFF0L) lsr 1) |> Int64.to_int_trunc
  ;;

  let precompute_header ~event_type ~extra_words ~arg_types ~thread ~category ~name =
    let counts = Header_template.add_size arg_types (2 + extra_words) in
    let header = (event_header [@inlined]) ~counts ~event_type ~thread ~category ~name in
    (* we're going to unsafely write 16 bytes so validate this ahead of time using the
       same function we'll use when writing. *)
    assert (header_byte_size header >= 16);
    header
  ;;

  let[@inline] int64_of_tsc ticks = Time_stamp_counter.to_int63 ticks |> Int63.to_int64

  let[@inline] write_from_header_and_get_tsc t ~header =
    (* Using [unsafe_set_int64_t_le] makes the assembly produced by this function
       much simpler, with the writes getting completely inlined and only one conditional
       branch for capacity checking.

       The benchmark does show a 1.5x-2x slowdown for using safe set calls (3-6ns/event).

       Safety proof sketch:
       - By assert in [precompute_header] and abstraction of the type,
         [header_byte_size header] >= 16 = bytes we write unsafely
       - By [ensure_capacity], we know [Iobuf.length t.buf >= 16]
         (this is either checked by the conditional or the check after [switch_buffers])
       - By the definition of [Iobuf.length = hi - lo] we now have [hi - lo >= 16] and so
         [hi >= lo + 16]
       - By the invariant of [Iobuf] that [hi <= Bigstring.length (Iobuf.Expert.buf b)],
         substitution and transitivity we have [Bigstring.length bstr >= lo + 16]
       - We write 8 bytes at [pos = lo] and [pos = lo + 8], thus
         we never write beyond [lo + 16].
       - By another invariant of [Iobuf] we have [lo >= 0]
       - By transitivity since we only write bytes at offsets x such that
         [lo <= x < lo+16], given the above we have [0 <= x < Bigstring.length bstr] so
         our writes are in bounds.
       - Since [final_pos = lo + 16] and [lo+16<=hi] our [set_lo] maintains the [Iobuf]
         invariant that [lo <= hi]. This function doesn't rely on [lo <= hi] but other
         functions might.*)
    let byte_size = header_byte_size header in
    ensure_capacity_no_flush t byte_size;
    let pos = Iobuf.Expert.lo t.buf in
    let bstr = Iobuf.Expert.buf t.buf in
    let final_pos = pos + 16 in
    Iobuf.Expert.set_lo t.buf final_pos;
    Bigstring.unsafe_set_int64_t_le bstr ~pos header;
    let pos = pos + 8 in
    let ticks = Time_stamp_counter.now () in
    Bigstring.unsafe_set_int64_t_le bstr ~pos (int64_of_tsc ticks);
    ticks
  ;;

  let write_from_header_with_tsc t ~header =
    ignore (write_from_header_and_get_tsc t ~header : Time_stamp_counter.t)
  ;;

  let write_tsc t ticks = write_int64_t t (int64_of_tsc ticks)

  module Write_arg_unchecked = Write_arg_unchecked
end

let create_for_file ?num_temp_strs ~filename () =
  let destination = Destinations.file_destination ~filename () in
  Expert.create ?num_temp_strs ~destination ()
;;

let close t =
  Expert.flush_and_notify t;
  (* Make buffer have zero length so further writes will ask for a new buffer and throw
     an exception. The [close] function should do that but we don't want to rely on it. *)
  Iobuf.resize t.buf ~len:0;
  (* Now that it's safer, close the underlying file *)
  let (module D : Destination) = t.destination in
  D.close ()
;;
