open! Core
module Writer = Tracing_zero.Writer
module Event_type = Writer.Expert.Event_type
module Buffer_until_initialized = Tracing_zero.Destinations.Buffer_until_initialized

let global_dest = Buffer_until_initialized.create ()

let tick_translation =
  let calibrator = Lazy.force Time_stamp_counter.calibrator in
  (* Only fails when on a 32 bit platform is detected, which we don't deploy any of *)
  let mhz_est = (Or_error.ok_exn Time_stamp_counter.Calibrator.cpu_mhz) calibrator in
  let ticks_per_second = Float.to_int (mhz_est *. 1E6) in
  let base_tsc = Time_stamp_counter.now () in
  let base_ticks = base_tsc |> Time_stamp_counter.to_int63 |> Int63.to_int_exn in
  let base_time = Time_stamp_counter.to_time_ns ~calibrator base_tsc in
  { Writer.Tick_translation.ticks_per_second; base_ticks; base_time }
;;

let global_writer =
  let destination = Buffer_until_initialized.to_destination global_dest in
  let w = Writer.Expert.create ~destination () in
  Writer.write_tick_initialization w tick_translation;
  w
;;

let main_thread = Writer.set_thread_slot global_writer ~slot:0 ~pid:1 ~tid:2

let set_destination dest =
  Buffer_until_initialized.set_destination global_dest dest;
  (* This isn't strictly necessary but it avoids a latency spike from the copy when the
     temp buffer gets filled up, and makes sure that we're writing to a buffer that at
     least has some chance of surviving a crash. *)
  Writer.Expert.force_switch_buffers global_writer
;;

let close () = Writer.close global_writer

module Event = struct
  type t = Writer.Expert.header

  let create_duration ~arg_types ~category ~name =
    let category = Writer.intern_string global_writer category in
    let name = Writer.intern_string global_writer name in
    let begin_header =
      Writer.Expert.precompute_header
        ~event_type:Event_type.duration_begin
        ~extra_words:0
        ~arg_types
        ~thread:main_thread
        ~category
        ~name
    in
    let end_header =
      Writer.Expert.precompute_header
        ~event_type:Event_type.duration_end
        ~extra_words:0
        ~arg_types:Writer.Arg_types.none
        ~thread:main_thread
        ~category
        ~name
    in
    begin_header, end_header
  ;;

  let create_event ~event_type ~arg_types ~category ~name ~extra_words =
    let category = Writer.intern_string global_writer category in
    let name = Writer.intern_string global_writer name in
    let header =
      Writer.Expert.precompute_header
        ~event_type
        ~extra_words
        ~arg_types
        ~thread:main_thread
        ~category
        ~name
    in
    header
  ;;

  let create_instant = create_event ~event_type:Event_type.instant ~extra_words:0

  let create_duration_begin =
    create_event ~event_type:Event_type.duration_begin ~extra_words:0
  ;;

  let create_duration_end =
    create_event ~event_type:Event_type.duration_end ~extra_words:0
  ;;

  let create_duration_instant =
    create_event ~event_type:Event_type.duration_complete ~extra_words:1
  ;;

  let write header = Writer.Expert.write_from_header_with_tsc global_writer ~header

  let write_and_get_tsc header =
    Writer.Expert.write_from_header_and_get_tsc global_writer ~header
  ;;
end

module For_testing = struct
  let tick_translation = tick_translation
end
