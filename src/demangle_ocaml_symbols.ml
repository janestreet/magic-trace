open! Core

let decode_two_digit_hexadecimal_number first_character second_character =
  let%bind.Option hex_digit_of_first_character = Char.get_hex_digit first_character in
  let%bind.Option hex_digit_of_second_character = Char.get_hex_digit second_character in
  let leftshift_first_character = hex_digit_of_first_character lsl 4 in
  let bit_or_on_the_hexadecimals =
    leftshift_first_character lor hex_digit_of_second_character
  in
  Char.of_int bit_or_on_the_hexadecimals
;;

let parser =
  let open Angstrom in
  let strip_numeric_suffix =
    char '_' *> skip_while Char.is_digit *> end_of_input *> return None
  in
  let double_underscores = string "__" >>| fun _ -> Some '.' in
  let two_digit_hexadecimal_number =
    let hex_character = satisfy Char.is_hex_digit in
    let hexcode =
      decode_two_digit_hexadecimal_number <$> char '$' *> hex_character <*> hex_character
    in
    hexcode
    >>= fun integer ->
    match integer with
    | None -> fail "invalid integer"
    | Some character -> return (Some character)
  in
  let normal_character = any_char >>| fun character -> Some character in
  let token =
    choice
      ~failure_msg:"unrecognized token"
      [ strip_numeric_suffix
      ; double_underscores
      ; two_digit_hexadecimal_number
      ; normal_character
      ]
  in
  string "caml" *> many1 token
;;

let demangle mangled_symbol =
  let mangled_string = Angstrom.parse_string ~consume:All parser mangled_symbol in
  match mangled_string with
  | Ok list -> Some (String.of_char_list (List.filter_map list ~f:Fn.id))
  | Error _ -> None
;;
