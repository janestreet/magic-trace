open! Core

type t =
  { start_symbol : Symbol_selection.t
  ; stop_symbol : Symbol_selection.t
  }

let param =
  let open Command.Param in
  flag
    "-aux-range"
    (optional
       (Arg_type.create (fun s ->
          let start_symbol, stop_symbol =
            Sexp.of_string s
            |> Tuple2.t_of_sexp String.t_of_sexp String.t_of_sexp
            |> Tuple2.map ~f:Symbol_selection.of_command_string
          in
          { start_symbol; stop_symbol })))
    ~doc:
      "_ Record Intel PT only between START and STOP. Syntax: -aux-range \"(<START> \
       <STOP>)\"."
;;
