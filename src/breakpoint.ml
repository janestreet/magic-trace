open! Core

type t

external create
  :  pid:Pid.t
  -> addr:int64
  -> (t, int) result
  = "magic_breakpoint_create_stub"

(* Keep in sync with magic_breakpoint_next_stub *)
module Hit = struct
  type t =
    { timestamp : Time_ns.Span.t
    ; passed_timestamp : Time_ns.Span.t
    ; passed_val : int
    ; tid : Pid.t
    ; ip : Int64.Hex.t
    }
  [@@deriving sexp]
end

external get_fd : t -> int = "magic_breakpoint_fd_stub"
external destroy : t -> unit = "magic_breakpoint_destroy_stub"
external next_hit : t -> Hit.t option = "magic_breakpoint_next_stub"

external enable : t -> single_hit:bool -> int or_null = "magic_breakpoint_enable_stub"
[@@noalloc]

let breakpoint_fd pid ~addr =
  match create ~pid ~addr with
  | Ok t -> Ok t
  | Error errno -> Errno.to_error errno
;;

let enable t ~single_hit =
  match enable t ~single_hit with
  | Null -> Ok ()
  | This errno -> Errno.to_error errno
;;

let fd t = get_fd t |> Core_unix.File_descr.of_int |> Core_unix.dup
