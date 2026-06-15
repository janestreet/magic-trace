(* Async is opened later after the Blocking submodule *)
open! Core
open! Import
module Unix = Core_unix
module Io = Io

module Streaming = struct
  type _ t = T : 'a Io.t * Io.Input.t Async.Pipe.Reader.t -> _ t

  let of_escaped_strings reader =
    T
      ( Io.of_escaped_string
      , Async.Pipe.map reader ~f:(fun x ->
          match Io.(encode of_escaped_string x) with
          | Error _ -> .
          | Ok x -> x) )
  ;;

  let of_strings_raise_on_newlines reader =
    T
      ( Io.of_human_friendly_string
      , Async.Pipe.map reader ~f:(fun x ->
          match Io.(encode of_human_friendly_string x) with
          | Error `String_contains_newline ->
            raise_s [%message "string unexpectedly contains newline" ~_:x]
          | Ok x -> x) )
  ;;
end

module Pick_from : sig
  type _ t =
    | Map : 'a String.Map.t -> 'a t
    | Assoc : (string * 'a) list -> 'a t
    | Inputs : string list -> string t
    | Command_output : string -> string t
    | Streaming : _ Streaming.t -> string t

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

  (** A [Pick_from.Encoded.t] takes care to convert client provided keys into
      'fzf-friendly' strings (i.e., not containing any newlines), and maps the
      'fzf-friendly' output from Fzf back into client-provided keys.
  *)
  module Encoded : sig
    type 'a unencoded := 'a t
    type 'a t

    val create : 'a unencoded -> 'a t
    val to_list : _ t -> Io.Input.t list
    val lookup_selection : 'a t -> Io.Output.t -> 'a
  end
end = struct
  type _ t =
    | Map : 'a String.Map.t -> 'a t
    | Assoc : (string * 'a) list -> 'a t
    | Inputs : string list -> string t
    | Command_output : string -> string t
    | Streaming : (_ Streaming.t[@sexp.opaque]) -> string t
  [@@deriving sexp_of]

  let to_list (type a) (t : a t) : string list =
    match t with
    | Map values -> Map.keys values
    | Assoc entries -> List.map ~f:fst entries
    | Inputs l -> l
    | Command_output (_ : string) -> []
    | Streaming (_ : _ Streaming.t) -> []
  ;;

  let inputs x = Inputs x
  let map x = Map x
  let assoc x = Assoc x
  let command_output x = Command_output x
  let streaming s = Streaming s

  module Of_stringable = struct
    let assoc (type t) (module S : Stringable with type t = t) assoc =
      let map =
        List.map assoc ~f:(fun (key, v) -> S.to_string key, v) |> String.Map.of_alist_exn
      in
      Map map
    ;;

    let map s map = Map.to_alist map |> assoc s
    let inputs s inputs = List.map inputs ~f:(fun s -> s, s) |> assoc s

    let%expect_test "assoc" =
      let module T = struct
        module T = struct
          type t =
            | Thing
            | Amabob
          [@@deriving enumerate, sexp]
        end

        include T
        include Sexpable.To_stringable (T)
      end
      in
      print_s [%sexp (assoc (module T) [ Thing, "t"; T.Amabob, "a" ] : string t)];
      [%expect {| (Map ((Amabob a) (Thing t))) |}]
    ;;
  end

  let lookup_selection (type a) (t : a t) (selection : string) : a =
    match t with
    | Map map ->
      (match Map.find map selection with
       | Some x -> x
       | None ->
         raise_s
           [%message
             "Fzf bug: String selected that was not a map key"
               selection
               (map : _ String.Map.t)])
    | Assoc alist ->
      (match List.Assoc.find ~equal:String.equal alist selection with
       | Some x -> x
       | None ->
         raise_s
           [%message
             "Fzf bug: string selected was not in selections"
               selection
               ~selections:(alist : (string * _) list)])
    | Inputs _ -> (selection : a)
    | Command_output (_ : string) -> (selection : a)
    | Streaming (_ : _ Streaming.t) -> (selection : a)
  ;;

  module Encoded = struct
    type 'a pick_from = 'a t

    type 'a t =
      { pick_from : 'a pick_from
      ; encoded : Io.Input.t list
      ; decode_exn : Io.Output.t -> string
      }

    let decode_exn codec selection ~message =
      match Io.decode codec selection with
      | Ok decoded -> decoded
      | Error (`Decoded_with_inconsistent_codec err) ->
        raise_s [%message message (selection : Io.Output.t) (err : Error.t)]
    ;;

    let create (type a) (pick_from : a pick_from) : a t =
      let unencoded = to_list pick_from in
      let encode_all (type err) (codec : err Io.t) : (a t, err) Result.t =
        let encode_results = List.map unencoded ~f:(Io.encode codec) in
        match List.partition_result encode_results with
        | encoded, [] ->
          let decode_exn =
            decode_exn
              codec
              ~message:"Fzf bug: string selected that was not in expected format"
          in
          Ok { pick_from; encoded; decode_exn }
        | (_ : Io.Input.t list), err :: (_ : err list) -> Error err
      in
      match pick_from with
      | Streaming (T (codec, _)) ->
        { pick_from
        ; encoded = []
        ; decode_exn =
            decode_exn
              codec
              ~message:"string selected that was not encoded with the right Fzf.Io format"
        }
      | _ ->
        (match encode_all Io.of_human_friendly_string with
         | Ok t -> t
         | Error `String_contains_newline ->
           (match encode_all Io.of_escaped_string with
            | Ok t -> t
            | Error _ -> .))
    ;;

    let lookup_selection (type a) (t : a t) (selection : Io.Output.t) : a =
      let selection = t.decode_exn selection in
      lookup_selection t.pick_from selection
    ;;

    let to_list t = t.encoded
  end
end

module Tiebreak = struct
  module T = struct
    type t =
      | Length
      | Begin
      | End
      | Index
    [@@deriving compare, enumerate, equal, sexp]
  end

  include T
  include Sexpable.To_stringable (T)

  let to_string = Fn.compose String.lowercase to_string

  let%test_unit "roundtrip" =
    List.iter all ~f:(fun t -> [%test_result: t] ~expect:t (of_string (to_string t)))
  ;;

  let%expect_test "demonstrate to_string" =
    List.iter all ~f:(fun t -> print_endline (to_string t));
    [%expect {|
      length
      begin
      end
      index |}]
  ;;
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
  -> ?nth:string
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

module Blocking = struct
  let prog = "fzf"

  let really_write_with_newline fd str =
    let str = str ^ "\n" in
    let rec loop pos =
      let pos = pos + Unix.single_write_substring fd ~pos ~buf:str in
      if String.length str > pos then loop pos
    in
    loop 0
  ;;

  let make_command_option ~key value = sprintf "--%s=%s" key value

  let shuttle_pipe_strings_to_fd_then_close pipe stdin_wr =
    let open Async in
    let shuttle_strings =
      let%map () =
        Async.Pipe.iter pipe ~f:(fun (str : Io.Input.t) ->
          match really_write_with_newline stdin_wr (str :> string) with
          | exception Core_unix.Unix_error _ -> Deferred.unit
          | () -> Deferred.unit)
      in
      Core_unix.close stdin_wr
    in
    don't_wait_for shuttle_strings
  ;;

  let pick
        ?select1
        ?query
        ?header
        ?preview
        ?preview_window
        ?no_sort
        ?reverse_input
        ?prompt_at_top
        ?with_nth
        ?nth
        ?delimiter
        ?height
        ?bind
        ?tiebreak
        ?filter
        ?border
        ?info
        ?exact_match
        ?select_many
        ?no_hscroll
        (entries :
           [ `Streaming of Io.Input.t Async.Pipe.Reader.t
           | `List of Io.Input.t Nonempty_list.t
           | `Command_output of string
           ])
        ~buffer_size
        ~on_result
        ~pid_ivar
    =
    let stdout_rd, stdout_wr = Unix.pipe () in
    (* In the past, this [pipe] was created in the child, and written to there.
       Unix pipes have a limited size buffer, and will block on writes if it is filled.
       Therefore, we need to create the pipe in a way that the parent can feed bytes
       into it while [fzf] is reading said bytes. *)
    let stdin_rd, stdin_wr = Unix.pipe () in
    match Unix.fork () with
    | `In_the_child ->
      Unix.dup2 ~dst:Unix.stdin ~src:stdin_rd ();
      Unix.dup2 ~dst:Unix.stdout ~src:stdout_wr ();
      Unix.close stdin_wr;
      let args =
        ([ Option.map query ~f:(make_command_option ~key:"query")
         ; Option.map header ~f:(make_command_option ~key:"header")
         ; Option.map select1 ~f:(Fn.const "--select-1")
         ; Option.map preview ~f:(make_command_option ~key:"preview")
         ; Option.map preview_window ~f:(make_command_option ~key:"preview-window")
         ; Option.map no_sort ~f:(Fn.const "--no-sort")
         ; Option.map reverse_input ~f:(Fn.const "--tac")
         ; Option.map prompt_at_top ~f:(Fn.const "--reverse")
         ; Option.map with_nth ~f:(make_command_option ~key:"with-nth")
         ; Option.map nth ~f:(make_command_option ~key:"nth")
         ; Option.map delimiter ~f:(make_command_option ~key:"delimiter")
         ; Option.map height ~f:(fun h ->
             make_command_option ~key:"height" (Int.to_string h))
         ; Option.map filter ~f:(make_command_option ~key:"filter")
         ; Option.map border ~f:(fun x ->
             [%sexp_of: [ `rounded | `sharp | `horizontal ]] x
             |> Sexp.to_string
             |> make_command_option ~key:"border")
         ; Option.map info ~f:(fun x ->
             [%sexp_of: [ `default | `inline | `hidden ]] x
             |> Sexp.to_string
             |> make_command_option ~key:"info")
         ; Option.map exact_match ~f:(Fn.const "--exact")
         ; Option.map select_many ~f:(Fn.const "-m")
         ; Option.map
             select_many
             ~f:(Fn.const (make_command_option ~key:"bind" "ctrl-a:toggle-all"))
         ; Option.map tiebreak ~f:(fun tiebreaks ->
             let value =
               Nonempty_list.to_list tiebreaks
               |> List.map ~f:Tiebreak.to_string
               |> String.concat ~sep:","
             in
             make_command_option ~key:"tiebreak" value)
         ; Option.map no_hscroll ~f:(Fn.const "--no-hscroll")
         ; (match entries with
            | `List (_ : Io.Input.t Nonempty_list.t) -> None
            | `Streaming (_ : Io.Input.t Async.Pipe.Reader.t) -> None
            | `Command_output command ->
              Some (make_command_option ~key:"bind" [%string "change:reload:%{command}"]))
         ]
         |> List.filter_opt)
        @ Option.value_map bind ~default:[] ~f:(fun bindings ->
          Nonempty_list.to_list bindings
          |> List.map ~f:(fun binding -> make_command_option ~key:"bind" binding))
      in
      never_returns (Unix.exec ~prog ~argv:(prog :: args) ())
    | `In_the_parent pid ->
      Unix.close stdin_rd;
      (match entries with
       | `List entries ->
         let entries = (entries :> string Nonempty_list.t) in
         Nonempty_list.iter entries ~f:(really_write_with_newline stdin_wr);
         Unix.close stdin_wr
       | `Streaming pipe -> shuttle_pipe_strings_to_fd_then_close pipe stdin_wr
       | `Command_output (_ : string) -> Unix.close stdin_wr);
      Option.iter pid_ivar ~f:(fun ivar -> Async.Ivar.fill_exn ivar pid);
      let (_ : Unix.Exit_or_signal.t) = Unix.waitpid pid in
      Unix.close stdout_wr;
      let buf = Bytes.create buffer_size in
      let count = Unix.read stdout_rd ~buf in
      Unix.close stdout_rd;
      on_result buf count
  ;;

  let entries_and_buffer_size (type a) (pick_from : a Pick_from.t) ~buffer_size =
    let large_enough_for_a_reasonable_string_selectable_by_a_human =
      Byte_units.(bytes_int_exn (of_kilobytes 16.))
    in
    match pick_from with
    | Command_output command ->
      Some
        ( `Command_output command
        , large_enough_for_a_reasonable_string_selectable_by_a_human )
    | Streaming (T ((_ : _ Io.t), pipe)) ->
      Some (`Streaming pipe, large_enough_for_a_reasonable_string_selectable_by_a_human)
    | pick_from ->
      let pick_from = Pick_from.Encoded.create pick_from in
      let%map.Option entries =
        Nonempty_list.of_list (Pick_from.Encoded.to_list pick_from)
      in
      `List entries, buffer_size entries
  ;;

  let pick_one_with_pid_ivar
        (type a)
        ?select1
        ?query
        ?header
        ?preview
        ?preview_window
        ?no_sort
        ?reverse_input
        ?prompt_at_top
        ?with_nth
        ?nth
        ?delimiter
        ?height
        ?bind
        ?tiebreak
        ?filter
        ?border
        ?info
        ?exact_match
        ?no_hscroll
        ~pid_ivar
        (pick_from : a Pick_from.t)
    : a option
    =
    let result =
      let%bind.Option entries, buffer_size =
        entries_and_buffer_size pick_from ~buffer_size:(fun entries ->
          Nonempty_list.map (entries :> string Nonempty_list.t) ~f:String.length
          |> Nonempty_list.reduce ~f:Int.max
          |> succ
          (* +1 for trailing newline *))
      in
      pick
        ?select1
        ?query
        ?header
        ?preview
        ?preview_window
        ?no_sort
        ?reverse_input
        ?prompt_at_top
        ?with_nth
        ?nth
        ?delimiter
        ?height
        ?bind
        ?tiebreak
        ?filter
        ?border
        ?info
        ?exact_match
        ?no_hscroll
        entries
        ~buffer_size
        ~on_result:(fun buf count ->
          if count = 0
          then None
          else (
            (* leave off trailing newline *)
            let output = Bytes.To_string.subo buf ~len:(count - 1) in
            Some (Io.Output.of_string output)))
        ~pid_ivar
    in
    let pick_from = Pick_from.Encoded.create pick_from in
    Option.map result ~f:(fun key -> Pick_from.Encoded.lookup_selection pick_from key)
  ;;

  let pick_one = pick_one_with_pid_ivar ~pid_ivar:None

  let pick_many_with_pid_ivar
        (type a)
        ?select1
        ?query
        ?header
        ?preview
        ?preview_window
        ?no_sort
        ?reverse_input
        ?prompt_at_top
        ?with_nth
        ?nth
        ?delimiter
        ?height
        ?bind
        ?tiebreak
        ?filter
        ?border
        ?info
        ?exact_match
        ?no_hscroll
        ~pid_ivar
        (pick_from : a Pick_from.t)
    : a list option
    =
    let result =
      let%bind.Option entries, buffer_size =
        entries_and_buffer_size pick_from ~buffer_size:(fun entries ->
          let each_entry_has_a_trailing_newline = 1 in
          (entries :> string Nonempty_list.t)
          |> Nonempty_list.map ~f:(fun entry ->
            String.length entry + each_entry_has_a_trailing_newline)
          |> Nonempty_list.reduce ~f:Int.( + ))
      in
      pick
        ?select1
        ?query
        ?header
        ?preview
        ?preview_window
        ?no_sort
        ?reverse_input
        ?prompt_at_top
        ?with_nth
        ?nth
        ?delimiter
        ?height
        ?bind
        ?tiebreak
        ?filter
        ?border
        ?info
        ?exact_match
        ?no_hscroll
        entries
        ~buffer_size
        ~select_many:()
        ~on_result:(fun buf count ->
          if count = 0
          then None
          else
            (* leave off trailing newline *)
            Bytes.To_string.subo buf ~len:(count - 1)
            |> String.split ~on:'\n'
            |> List.map ~f:Io.Output.of_string
            |> Option.some)
        ~pid_ivar
    in
    let pick_from = Pick_from.Encoded.create pick_from in
    Option.map result ~f:(fun keys ->
      List.map keys ~f:(fun key -> Pick_from.Encoded.lookup_selection pick_from key))
  ;;

  let pick_many = pick_many_with_pid_ivar ~pid_ivar:None
end

open Async

let with_abort ~abort ~f =
  let pid_ivar = Ivar.create () in
  let abort_deferred =
    let%map (), pid = Deferred.both abort (Ivar.read pid_ivar) in
    pid
  in
  let abort_choice =
    choice abort_deferred (fun pid ->
      Signal_unix.send_i Signal.int (`Pid pid);
      Or_error.return (Second `Aborted))
  in
  let fzf_deferred =
    let%map.Deferred.Or_error x = f ~pid_ivar:(Some pid_ivar) in
    First x
  in
  let fzf_choice = choice fzf_deferred Fn.id in
  let%bind result = choose [ abort_choice; fzf_choice ] in
  (* Wait on the fzf_deferred so when the returned deferred is determined we know the
     child fzf process has already been reaped. *)
  let%bind.Deferred (_ : _ Either.t Or_error.t) = fzf_deferred in
  return result
;;

let pick_one_with_pid_ivar
      (type a)
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      ~pid_ivar
      (entries : a Pick_from.t)
  : a option Deferred.Or_error.t
  =
  Deferred.Or_error.try_with
    ~run:`Schedule (* consider [~run:`Now] instead; see: https://wiki/x/ByVWF *)
    ~rest:`Log
    (* consider [`Raise] instead; see: https://wiki/x/Ux4xF *)
    (fun () ->
       In_thread.run (fun () ->
         Blocking.pick_one_with_pid_ivar
           ?select1
           ?query
           ?header
           ?preview
           ?preview_window
           ?no_sort
           ?reverse_input
           ?prompt_at_top
           ?with_nth
           ?nth
           ?delimiter
           ?height
           ?bind
           ?tiebreak
           ?filter
           ?border
           ?info
           ?exact_match
           ?no_hscroll
           ~pid_ivar
           entries))
;;

let pick_one = pick_one_with_pid_ivar ~pid_ivar:None

let pick_one_abort
      (type a)
      ~abort
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      (entries : a Pick_from.t)
  : (a option, [ `Aborted ]) Either.t Deferred.Or_error.t
  =
  with_abort ~abort ~f:(fun ~pid_ivar ->
    pick_one_with_pid_ivar
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      ~pid_ivar
      entries)
;;

let pick_many_with_pid_ivar
      (type a)
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      ~pid_ivar
      (entries : a Pick_from.t)
  : a list option Deferred.Or_error.t
  =
  Deferred.Or_error.try_with
    ~run:`Schedule (* consider [~run:`Now] instead; see: https://wiki/x/ByVWF *)
    ~rest:`Log
    (* consider [`Raise] instead; see: https://wiki/x/Ux4xF *)
    (fun () ->
       In_thread.run (fun () ->
         Blocking.pick_many_with_pid_ivar
           ?select1
           ?query
           ?header
           ?preview
           ?preview_window
           ?no_sort
           ?reverse_input
           ?prompt_at_top
           ?with_nth
           ?nth
           ?delimiter
           ?height
           ?bind
           ?tiebreak
           ?filter
           ?border
           ?info
           ?exact_match
           ?no_hscroll
           ~pid_ivar
           entries))
;;

let pick_many = pick_many_with_pid_ivar ~pid_ivar:None

let pick_many_abort
      (type a)
      ~abort
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      (entries : a Pick_from.t)
  : (a list option, [ `Aborted ]) Either.t Deferred.Or_error.t
  =
  with_abort ~abort ~f:(fun ~pid_ivar ->
    pick_many_with_pid_ivar
      ?select1
      ?query
      ?header
      ?preview
      ?preview_window
      ?no_sort
      ?reverse_input
      ?prompt_at_top
      ?with_nth
      ?nth
      ?delimiter
      ?height
      ?bind
      ?tiebreak
      ?filter
      ?border
      ?info
      ?exact_match
      ?no_hscroll
      ~pid_ivar
      entries)
;;

let complete_subcommands ~show_help ~path ~part subcommands =
  let preview =
    if show_help
    then (
      (* Always use /proc/self/exe, since the first element in [path] might not resolve to
         the executable. *)
      let exe = Core_unix.readlink "/proc/self/exe" in
      let name, args =
        match path with
        | name :: args -> name, String.concat ~sep:" " args
        | [] -> failwith "complete_subcommands: Unexpected empty list for path"
      in
      let command_prefix = [%string "exec -a %{name} %{exe} %{args}"] in
      Some (sprintf "eval '%s '{}' -help'" command_prefix))
    else None
  in
  let prompt_at_top =
    (* If help is being displayed, it will appear at the top, so also move the prompt up
       there.  That way eyes can more easily bounce between the current selection and the
       help. *)
    Option.some_if (Option.is_some preview) ()
  in
  Blocking.pick_one
    (Inputs (List.map ~f:(String.concat ~sep:" ") subcommands))
    ~query:part
    ?preview
    ?prompt_at_top
  |> Option.map ~f:List.return
;;

let complete ~choices (univ_map : Univ_map.t) ~part =
  Blocking.pick_one ~query:part (Inputs (choices univ_map)) |> Option.to_list
;;

let complete_enumerable (module E : Command.Enumerable_stringable) =
  let choices (_ : Univ_map.t) = List.map E.all ~f:E.to_string in
  complete ~choices
;;

let complete_enumerable_sexpable (module E : Command.Enumerable_sexpable) =
  let choices (_ : Univ_map.t) =
    List.map E.all ~f:(fun t -> Sexp.to_string [%sexp (t : E.t)])
  in
  complete ~choices
;;
