open! Core

type t =
  { start_symbol : Symbol_selection.t
  ; stop_symbol : Symbol_selection.t
  }

val param : t option Command.Param.t
