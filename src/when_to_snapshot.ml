open! Core

type which_function =
  | Use_fzf_to_select_one
  | User_selected of string

type t =
  | Magic_trace_or_the_application_terminates
  | Application_calls_a_function of which_function

let param =
  let open Command.Param in
  flag
    "-trigger"
    (optional string)
    ~doc:
      "SYMBOL Decides when magic-trace takes a trace. There are three trigger modes to \
       choose from:\n\
       1) If you do not provide [-trigger], magic-trace takes a snapshot when either it \
       or the application under trace ends. You can Ctrl+C magic-trace to manually \
       trigger a snapshot.\n\
       2) If you provide [-trigger $], magic-trace will open up a fuzzy-find dialog to \
       help you choose a symbol to trace.\n\
       3) If you provide [-trigger <FUNCTION NAME>], magic-trace will snapshot when the \
       application being traced calls the given function. This takes the fully-mangled \
       name, so if you're using anything except C, fuzzy-find mode will probably be \
       easier to use. [-trigger .] is a shorthand for [-trigger \
       magic_trace_stop_indicator]."
  |> map ~f:(function
         | None -> Magic_trace_or_the_application_terminates
         | Some "$" -> Application_calls_a_function Use_fzf_to_select_one
         | Some "." ->
           Application_calls_a_function (User_selected Magic_trace.Private.stop_symbol)
         | Some symbol -> Application_calls_a_function (User_selected symbol))
;;
