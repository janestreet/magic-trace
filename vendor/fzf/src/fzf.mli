(** Functions for calling out to [fzf], the command-line fuzzy finder, from
    within terminal applications.  See [man fzf] for more details.

    Some higher-level interfaces for constructing UIs using fzf exist.
    See {!Fzf_selector}. *)

open! Core
open! Async
open! Import

module Streaming : sig
  type 'a t

  val of_escaped_strings : string Pipe.Reader.t -> _ t
  val of_strings_raise_on_newlines : string Pipe.Reader.t -> _ t
end

(** [Pick_from] instructs [Fzf] to choose from a given input and perhaps select an
    output that wasn't the string selected. *)
module Pick_from : sig
  type _ t =
    | Map : 'a String.Map.t -> 'a t
    (** [Map map] will sort the displayed map keys lexicographically and return the
        corresponding value. *)
    | Assoc : (string * 'a) list -> 'a t
    (** [Assoc list] will display [list] in an order preserving way, returning the
        corresponding ['a] upon selection. *)
    | Inputs : string list -> string t
    (** [Inputs strings] will display [strings] to the user, order preserving. The string
        selected is returned. *)
    | Command_output : string -> string t
    (** [Command_output command] will execute [command] and display the results for
        selection, this is useful for interactive selection driven from another
        executable:

        - [command] will be run every time the query string changes.
        - All occurrences of "{q}" in [command] will be replaced with the current value of
          fzf's query string.

        The selected line is returned as a string.

        This mechanism uses the --bind flag with the [change] event (see `man 1 fzf` for
        more information about query strings and preview/bind). *)
    | Streaming : _ Streaming.t -> string t
    (** [Streaming] will read encoded strings from [reader] until the pipe
        is closed. *)

  val map : 'a String.Map.t -> 'a t
  val assoc : (string * 'a) list -> 'a t
  val inputs : string list -> string t
  val command_output : string -> string t
  val streaming : _ Streaming.t -> string t

  module Of_stringable : sig
    val map : (module Stringable with type t = 't) -> ('t, 'a, _) Map.t -> 'a t
    val assoc : (module Stringable with type t = 't) -> ('t, 'a) List.Assoc.t -> 'a t
    val inputs : (module Stringable with type t = 't) -> 't List.t -> 't t
  end
end

(** [Tiebreak] instructs [Fzf] how to sort lines when the "matching scores" are tied. See
    fzf(1) for more documentation. *)
module Tiebreak : sig
  type t =
    | Length (** Prefers line with shorter length *)
    | Begin (** Prefers line with matched substring closer to the beginning *)
    | End (** Prefers line with matched substring closer to the end *)
    | Index (** Prefers line that appeared earlier in the input stream (default) *)

  include Stringable.S with type t := t
end

type ('a, 'return) pick_fun =
  ?select1:unit
  -> ?query:string
  -> ?header:string
  -> ?preview:string
  -> ?preview_window:string
  -> ?no_sort:unit
  -> ?reverse_input:unit
  -> ?prompt_at_top:unit
  -> ?with_nth:string
  -> ?nth:
       string
  -> ?delimiter:string
  -> ?height:int
  -> ?bind:string Nonempty_list.t
  -> ?tiebreak:Tiebreak.t Nonempty_list.t
  -> ?filter:string
  -> ?border:[ `rounded | `sharp | `horizontal ]
  -> ?info:[ `default | `inline | `hidden ]
  -> ?exact_match:unit
  -> ?no_hscroll:unit
  -> 'a Pick_from.t
  -> 'return

(** [pick_one ?query ?header ?preview items] will display a visual selector from [items].
    If [pick_one items] evaluates to [Some x], it is guaranteed that [x] is a member of
    [items].

    If [items] is empty, [pick_one] just returns [None].

    If [query] is provided, the finder will start the search as if
    [query] had been typed already.

    If [select1] is passed and either [items] has length 1 or [query] matches exactly 1
    item, the lone item will be immediately returned without a prompt.

    If [preview] is provided, it specifies the preview string provided to fzf.
    See the Preview section of man fzf (1). E.g. ~preview:"cat {}" will cat out
    the current selection and display it. Programs may want specify a [preview] string
    that causes itself to be [exec]'d in order to generate valuable previews.

    If [preview_window] is provided, it specifies the dimensions and format of the preview
    window that fzf displays.  See the Preview section of man fzf (1).  E.g.
    [~preview_window:"top:99%:wrap"] will display the preview window above fzf's prompt,
    cause it to take up 99% of the screen, and automatically wrap text in the window.

    If [no_sort] is passed, fzf will not sort the filtered results displayed to the user.
    That is, they will appear in the same order as in [items] instead of in order of
    relevance.

    If [reverse_input] is passed, fzf will display the initial list of options in reverse
    order to how it usually does (first line closest to the prompt).
    (This passes the [--tac] flag to fzf)

    If [prompt_at_top] is passed, fzf will display the fuzzy finder's prompt at the top of
    the window, instead of at the bottom.
    (This passes the [--reverse] flag to fzf)

    If [with_nth] is passed fzf will only show part of every item, e.g. "2.." means "for
    every item show everything from 2nd field onwards" (n.b. fields are 1 indexed).

    If [nth] is passed fzf will only match part of every item, e.g. "2.." means "for
    every item only match from 2nd field onwards" (n.b. fields are 1 indexed).

    If [delimiter] is passed fzf will use this to delimit items (as used in [with_nth],
    [nth] and [preview])

    If [height] is passed, fzf window will be displayed below the cursor with the given
    height instead of using fullscreen.
    (This passes the [--height] flag to fzf)

    If [bind] is passed, the default key bindings will be redefined according to the
    format of fzf [--bind] flag.  While fzf allows you to pass multiple bindings
    in a single instance of the [--bind] flag by separating the bindings with commas,
    some commands cannot be followed by a comma (e.g. the 'preview' command can't
    be followed by a comma because there is no way to delineate the 'end' of a preview
    command, and so fzf treats the comma as part of the command).  To work around this,
    every element of [bind] causes the --bind flag to be passed to fzf again - e.g.
    (["ctrl-l:preview:echo hi"; "ctrl-k:kill-line"] causes this to pass
    --bind "ctrl-l:preview:echo hi" --bind "ctrl-k:kill-line".

    If [exact_match] is passed, fzf will use exact-match rather than fuzzy-match for each
    word in the query. (This passes the [--exact_match] flag to fzf)

    If [no_hscroll] is passed, fzf will disable horizontal scroll. (This passes the
    [--no-hscroll] flag to fzf.)
*)
val pick_one : ('a, 'a option Deferred.Or_error.t) pick_fun

(** [pick_many] will present the user with a multi-select prompt.

    The user can select multiple results at once by using TAB
    to select and SHIFT + TAB to unselect. All current results can be selected
    using CTRL + A.

    For documentation on the other options to this function see [pick_one]. *)
val pick_many : ('a, 'a list option Deferred.Or_error.t) pick_fun

(** These functions allow the fzf select to be aborted by providing an [abort : unit
    Deferred.t].

    If [abort] becomes determined before a selection is made, the fzf screen closes and
    [`Aborted] is returned, otherwise [result] is returned, where result would be
    the value returned by [pick_one]/[pick_many] *)
val pick_one_abort
  :  abort:unit Deferred.t
  -> ('a, ('a option, [ `Aborted ]) Either.t Deferred.Or_error.t) pick_fun

val pick_many_abort
  :  abort:unit Deferred.t
  -> ('a, ('a list option, [ `Aborted ]) Either.t Deferred.Or_error.t) pick_fun

module Blocking : sig
  val pick_one : ('a, 'a option) pick_fun
  val pick_many : ('a, 'a list option) pick_fun
end

(** [complete_subcommands ~show_help] is intended to be used as the argument to
    [Command.run]s [complete_subcommands] argument.

    [show_help] determines if command help is shown alongside the subcommand during
    selection as a preview.
*)
val complete_subcommands
  :  show_help:bool
  -> path:string list
  -> part:string
  -> string list list
  -> string list option

(** [complete ~choices] is intended to be used as the argument to [Command.Arg_type]s
    [complete] argument.
*)
val complete : choices:(Univ_map.t -> string list) -> Command.Auto_complete.t

(** [complete_enumerable] is a convenience wrapper for [complete] to use with
    [ppx_enumerate] using [to_string].
*)
val complete_enumerable
  :  (module Command.Enumerable_stringable)
  -> Command.Auto_complete.t

(** [complete_enumerable_sexpable] is a convenience wrapper for [complete] to use with
    [ppx_enumerate] using [sexp_of_t] to turn the value into a string.
*)
val complete_enumerable_sexpable
  :  (module Command.Enumerable_sexpable)
  -> Command.Auto_complete.t
