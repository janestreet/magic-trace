open! Core
open! Import

type t

external create
  :  pid:int
  -> addr:int64
  -> single_hit:bool
  -> (t, int) result
  = "magic_breakpoint_create_stub"

(* Keep in sync with magic_breakpoint_next_stub *)
module Hit = struct
  type t =
    { timestamp : Time_ns.Span.t
    ; passed_timestamp : Time_ns.Span.t
    ; passed_val : int
    ; tid : int
    ; ip : Int64.Hex.t
    }
  [@@deriving sexp]
end

external get_fd : t -> int = "magic_breakpoint_fd_stub"
external destroy : t -> unit = "magic_breakpoint_destroy_stub"
external next_hit : t -> Hit.t option = "magic_breakpoint_next_stub"

let breakpoint_fd pid ~addr ~single_hit =
  match create ~pid:(Pid.to_int pid) ~addr ~single_hit with
  | Ok t -> Ok t
  | Error errno -> Errno.to_error errno
;;

let fd t = get_fd t |> Core_unix.File_descr.of_int |> Core_unix.dup
