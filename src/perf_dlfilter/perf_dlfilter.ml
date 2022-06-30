open! Core
open! Async
open! Import

let writer_ref = ref None

let initialize () =
  let filename = Unix.getenv "MAGIC_TRACE_DLFILTER_FILE" |> Option.value_exn in
  let writer = Writer.open_file filename in
  while not (Deferred.is_determined writer) do
    Scheduler.Private.run_cycles_until_no_jobs_remain ()
  done;
  writer_ref := Some (Deferred.value_exn writer)
;;

let finally () =
  let writer = !writer_ref |> Option.value_exn in
  let close_result = Writer.close writer in
  while not (Deferred.is_determined close_result) do
    Scheduler.Private.run_cycles_until_no_jobs_remain ()
  done
;;

let process_sample sample =
  let writer = !writer_ref |> Option.value_exn in
  Writer.write_bin_prot writer Perf_raw_sample.bin_writer_t sample
;;

let _ = Callback.register "initialize" initialize
let _ = Callback.register "finally" finally
let _ = Callback.register "process_sample" process_sample
