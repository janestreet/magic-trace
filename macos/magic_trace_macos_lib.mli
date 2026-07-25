exception Error of string

val failf : ('a, unit, string, 'b) format4 -> 'a

type frame =
  { name : string
  ; binary_name : string
  ; binary_path : string
  ; address : string
  }

type sample =
  { time_ns : int64
  ; weight_ns : int64
  ; pid : int
  ; process_name : string
  ; tid : int
  ; thread_name : string
  ; frames_leaf_first : frame list
  }

type interval =
  { start_ns : int64
  ; end_ns : int64
  ; pid : int
  ; tid : int
  ; depth : int
  ; frame : frame
  }

type trace_document =
  { sample_count : int
  ; sampling_period_ns : int64
  ; intervals : interval list
  ; processes : (int * string) list
  ; threads : ((int * int) * string) list
  }

type target =
  | Pid of int
  | Command of string list

val normalize_duration : string -> string
val parse_time_profile_xml : string -> sample list
val samples_to_intervals : sample list -> interval list
val build_trace_document : sample list -> trace_document
val write_trace_document : trace_document -> string -> unit

val find_on_path : string -> string option
val find_xctrace : unit -> string
val with_temporary_directory : (string -> 'a) -> 'a

val record
  :  timeout_seconds:float option
  -> target_stdout:string option
  -> xctrace:string
  -> recording:string
  -> duration:string
  -> target:target
  -> unit

val convert_export
  :  profile_xml:string
  -> output:string
  -> force:bool
  -> unit

val record_and_convert
  :  duration:string
  -> output:string
  -> keep_recording:string option
  -> force:bool
  -> target:target
  -> unit
