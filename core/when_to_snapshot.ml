open! Core

type t =
  | Magic_trace_or_the_application_terminates
  | Application_calls_a_function of Symbol_selection.t

let param =
  let open Command.Param in
  flag
    "-trigger"
    (optional string)
    ~doc:
      "_ Selects when magic-trace takes a trace. There are three trigger modes to choose \
       from:\n\
       (1) If you do not provide [-trigger], magic-trace takes a snapshot when you \
       Ctrl+C it.\n\
       (2) If you provide [-trigger ?], [-trigger symbol:?], or [-trigger line:?], \
       magic-trace will open up a fuzzy-find dialog to help you choose a symbol to \
       trace. Fails if you don't have the \"fzf\" binary in your PATH. The prefixes \
       [symbol:] and [line:] restrict to showing only functions or files respectively.\n\
       (3) If you provide [-trigger <SELECTION>], magic-trace will snapshot when the \
       application being traced calls the given function. This takes the fully-mangled \
       name, so if you're using anything except C, fuzzy-find mode will probably be \
       easier to use. [-trigger .] is a shorthand for [-trigger \
       magic_trace_stop_indicator]. [SELECTION] can be [<FUNCTION NAME>], [<ADDRESS>], \
       or [<FILE>:<LINE>:<COL>]. Prefixes [addr:], [symbol:], and [line:] restrict how \
       magic-trace should parse the selection.\n\
       (*) Regardless of trigger mode, magic-trace will always snapshot when the \
       application terminates if it has not yet triggered for any other reason.\n\
       (*) If you pass multiple PIDs when tracing, the trigger will only be able to \
       select a function from the first PID passed.\n\n"
  |> map ~f:(function
    | None -> Magic_trace_or_the_application_terminates
    | Some input ->
      Application_calls_a_function (Symbol_selection.of_command_string input))
;;
