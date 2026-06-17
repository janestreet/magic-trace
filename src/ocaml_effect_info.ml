open! Core

type t =
  { caml_runstack_enter : int
  ; caml_runstack_exit : int
  ; caml_runstack_exn : int
  ; caml_perform_enter : int
  ; caml_resume_enter : int
  ; caml_resume_preempted : int
  }
[@@deriving sexp_of]

module Kind = struct
  type t =
    | Runstack_enter
    | Runstack_exit
    | Runstack_exn
    | Perform_enter
    | Resume_enter
    | Resume_premepted
end

let create ~offsets =
  if Array.length offsets < 6 then failwith "Insufficient offsets";
  (* Keep in sync with [amd64.S] in the compiler. *)
  { caml_runstack_enter = Int64.to_int_exn offsets.(0)
  ; caml_runstack_exit = Int64.to_int_exn offsets.(1)
  ; caml_runstack_exn = Int64.to_int_exn offsets.(2)
  ; caml_perform_enter = Int64.to_int_exn offsets.(3)
  ; caml_resume_enter = Int64.to_int_exn offsets.(4)
  ; caml_resume_preempted = Int64.to_int_exn offsets.(5)
  }
;;

let categorize t (loc : Event.Location.t) : Kind.t or_null =
  match Symbol.display_name loc.symbol with
  | "caml_runstack" when loc.symbol_offset = t.caml_runstack_enter -> This Runstack_enter
  | "caml_runstack" when loc.symbol_offset = t.caml_runstack_exit -> This Runstack_exit
  | "caml_runstack" when loc.symbol_offset = t.caml_runstack_exn -> This Runstack_exn
  | "caml_perform" when loc.symbol_offset = t.caml_perform_enter -> This Perform_enter
  | "caml_resume" when loc.symbol_offset = t.caml_resume_enter -> This Resume_enter
  | "caml_resume" when loc.symbol_offset = t.caml_resume_preempted ->
    This Resume_premepted
  | _ -> Null
;;

let is_exn_handler t (loc : Event.Location.t) =
  match categorize t loc with
  | This Runstack_exn -> true
  | _ -> false
;;
