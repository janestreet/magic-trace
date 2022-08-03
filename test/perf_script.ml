open! Core
open! Async
open Magic_trace_core
open Magic_trace_lib
module Time_ns = Time_ns_unix

let run ?(debug = false) ?events_writer ?ocaml_exception_info ~trace_scope file =
  (* CR-someday cgaebel: Get the git root by shelling out to `git rev-parse --show-toplevel`.
     This works, but is ridiculous. *)
  let git_root = "../../.." in
  let script = In_channel.read_all (git_root ^ "/test/" ^ file) in
  let lines = String.split script ~on:'\n' in
  let next_pid = ref 0 in
  let next_thread = ref 0 in
  let module Trace = struct
    type thread = int

    let allocate_pid ~name:_ =
      incr next_pid;
      !next_pid
    ;;

    let allocate_thread ~pid:_ ~name:_ =
      incr next_thread;
      !next_thread
    ;;

    let write_duration_begin ~args:_ ~thread:_ ~name ~time : unit =
      if not String.(name = "branch-misses" || name = "cache-misses")
      then printf "-> %8s BEGIN %s\n" (Time_ns.Span.to_string_hum time) name
    ;;

    let write_duration_end ~args:_ ~thread:_ ~name ~time : unit =
      if not String.(name = "branch-misses" || name = "cache-misses")
      then printf "-> %8s END   %s\n" (Time_ns.Span.to_string_hum time) name
    ;;

    let write_duration_complete ~args ~thread ~name ~time ~time_end : unit =
      write_duration_begin ~args ~thread ~name ~time;
      write_duration_end ~args ~thread ~name ~time:time_end
    ;;

    let write_duration_instant ~args ~thread ~name ~time : unit =
      write_duration_begin ~args ~thread ~name ~time;
      printf "->          END   %s\n" name
    ;;

    let write_counter ~args:_ ~thread:_ ~name:_ ~time:_ : unit = ()
  end
  in
  Magic_trace_lib.Trace_writer.debug := debug;
  Exn.protect
    ~finally:(fun () -> Magic_trace_lib.Trace_writer.debug := false)
    ~f:(fun () ->
      let trace_writer =
        Trace_writer.create_expert
          ~trace_scope
          ~debug_info:None
          ~ocaml_exception_info
          ~earliest_time:Time_ns.Span.zero
          ~hits:[]
          ~annotate_inferred_start_times:true
          (module Trace)
      in
      let first_event_time = ref Time_ns.Span.Option.none in
      (* Make the start of the trace start at time=0, regardless of when it actually started. *)
      let adjust_event_time (event : Event.t) : Event.t =
        Event.change_time event ~f:(fun event_time ->
          let first_event_time =
            match%optional.Time_ns.Span.Option !first_event_time with
            | None ->
              first_event_time := Time_ns.Span.Option.some event_time;
              event_time
            | Some first_event_time -> first_event_time
          in
          Time_ns.Span.( - ) event_time first_event_time)
      in
      let should_print_perf_line (event : Event.t) =
        match event with
        | Ok { data = Trace data; _ } ->
          (* Most of a trace is just jumps within a single function. Those are basically
             uninteresting to magic-trace, so skip them to keep tests a little cleaner. *)
          not ([%compare.equal: Symbol.t] data.src.symbol data.dst.symbol)
        | Error _ | Ok _ -> true
      in
      let%map split_lines =
        Perf_decode.For_testing.split_line_pipe (Pipe.of_list lines) |> Pipe.to_list
      in
      List.iter split_lines ~f:(fun lines ->
        let event =
          Perf_decode.For_testing.to_event lines |> Option.map ~f:adjust_event_time
        in
        match event with
        | Some event ->
          if should_print_perf_line event
          then (
            match lines with
            | [ line ] -> printf "%s\n" line
            | lines -> print_s [%message (lines : string list)]);
          let event = Event.With_write_info.create ~should_write:true event in
          Trace_writer.write_event ?events_writer trace_writer event
        | None -> ());
      printf "END\n";
      Trace_writer.end_of_trace trace_writer)
;;
