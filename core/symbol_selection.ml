open! Core
open! Async

type t =
  | Use_fzf_to_select_one of [ `File | `Func | `File_or_func ]
  | User_selected of string

let of_command_string s =
  match s with
  | "?" -> Use_fzf_to_select_one `File_or_func
  | "line:?" -> Use_fzf_to_select_one `File
  | "symbol:?" -> Use_fzf_to_select_one `Func
  | "." -> User_selected Magic_trace.Private.stop_symbol
  | s -> User_selected s
;;

let select_owee_symbol ~elf ~header select =
  let open Deferred.Or_error.Let_syntax in
  let all_symbols = Elf.all_symbols ~select elf in
  let all_symbol_names = List.map all_symbols ~f:Tuple2.get1 in
  let demangled_symbols =
    List.map all_symbol_names ~f:(fun mangled_symbol ->
      match Demangle_ocaml_symbols.demangle mangled_symbol with
      | None -> mangled_symbol, mangled_symbol
      | Some demangled_symbol -> demangled_symbol, mangled_symbol)
  in
  match%bind Fzf.pick_one ~header (Assoc demangled_symbols) with
  | None -> Deferred.Or_error.error_string "No symbol selected"
  | Some chosen_name ->
    let chosen_symbol =
      List.find_exn all_symbols ~f:(fun (name, _symbol) -> String.(name = chosen_name))
      |> Tuple2.get2
    in
    return (chosen_name, chosen_symbol)
;;

let select_within_file ~elf ~header symbol =
  let open Deferred.Or_error.Let_syntax in
  let all_file_selections = Elf.all_file_selections elf symbol in
  let all_file_selection_names = List.map all_file_selections ~f:Tuple2.get1 in
  let%bind () =
    if List.is_empty all_file_selections
    then
      Deferred.Or_error.error_string
        "No lines found, possibly because of missing debug info"
    else return ()
  in
  match%bind Fzf.pick_one ~header (Inputs all_file_selection_names) with
  | None -> Deferred.Or_error.error_string "No location selected"
  | Some chosen_name -> return chosen_name
;;

let evaluate ~supports_fzf ~elf ~header symbol_selection =
  let open Deferred.Or_error.Let_syntax in
  let%bind elf =
    match elf with
    | None -> Deferred.Or_error.error_string "No ELF found"
    | Some elf -> return elf
  in
  let%bind () =
    if force supports_fzf
    then return ()
    else
      Deferred.Or_error.error_string
        "magic-trace could show you a fuzzy-finding selector here if \"fzf\" were in \
         your PATH, but it is not."
  in
  match symbol_selection with
  | Use_fzf_to_select_one select ->
    let%bind chosen_name, chosen_symbol = select_owee_symbol ~elf ~header select in
    (match Owee_elf.Symbol_table.Symbol.type_attribute chosen_symbol with
     | File ->
       let%bind chosen_name =
         select_within_file ~elf ~header:(header ^ " line") chosen_symbol
       in
       return chosen_name
     | _ -> return chosen_name)
  | User_selected user_selection -> return user_selection
;;
