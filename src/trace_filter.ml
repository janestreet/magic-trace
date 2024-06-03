open! Core

module Unevaluated = struct
  type t =
    { start_symbol : Symbol_selection.t
    ; stop_symbol : Symbol_selection.t
    }
  [@@deriving fields]

  (* Accepts '(foo bar)', returns { start_symbol = User_selected "foo"; stop_symbol = User_selected = "bar" } *)
  let arg_type =
    Command.Param.Arg_type.create (fun s ->
      let start_symbol, stop_symbol =
        Sexp.of_string s
        |> Tuple2.t_of_sexp String.t_of_sexp String.t_of_sexp
        |> Tuple2.map ~f:Symbol_selection.of_command_string
      in
      { start_symbol; stop_symbol })
  ;;
end

type t =
  { start_symbol : string
  ; stop_symbol : string
  }
[@@deriving sexp, fields]

let param =
  let open Command.Param in
  flag
    "-filter"
    (optional Unevaluated.arg_type)
    ~doc:
      "_ [-filter \"(<START> <STOP>)\"] restricts the output of magic-trace to events \
       occurring between consecutive occurrences of START and STOP. If either function \
       is not called in the trace, no output will be produced."
;;
