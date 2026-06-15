open! Core

let intable_of_hex_string
  (type a)
  (module M : Int_intf.S with type t = a)
  ?(remove_hex_prefix = false)
  str
  =
  (* Bit hacks for fast parsing of hex strings.
   *
   * Note that in ASCII, ('1' | 'a' | 'A') & 0xF = 1.
   *
   * So for each character, take the bottom 4 bits, and add 9 if it's
   * not a digit. *)
  let res = ref (M.of_int_exn 0) in
  let fifteen = M.of_int_exn 0xF in
  let eight = M.of_int_exn 0x8 in
  for i = if remove_hex_prefix then 2 else 0 to String.length str - 1 do
    let open M in
    let c = of_int_exn (Char.to_int (String.unsafe_get str i)) in
    res := (!res lsl 4) lor ((c land fifteen) + ((c lsr 6) lor ((c lsr 3) land eight)))
  done;
  !res
;;

let int64_of_hex_string = intable_of_hex_string (module Int64)
let int_trunc_of_hex_string = intable_of_hex_string (module Int)

module%test _ = struct
  open Core

  let check ?remove_hex_prefix str =
    print_s
      [%message
        ""
          ~int64:(int64_of_hex_string ?remove_hex_prefix str |> sprintf "0x%Lx")
          ~int:(int_trunc_of_hex_string ?remove_hex_prefix str |> sprintf "0x%x")]
  ;;

  let%expect_test "int64 hex parsing" =
    check ~remove_hex_prefix:true "0x7f9db48c1d80";
    [%expect {|
        ((int64 0x7f9db48c1d80) (int 0x7f9db48c1d80)) |}];
    check "7f9db48c1d80";
    [%expect {|
        ((int64 0x7f9db48c1d80) (int 0x7f9db48c1d80)) |}];
    check "fF";
    [%expect {|
        ((int64 0xff) (int 0xff)) |}];
    check "f0f";
    [%expect {|
        ((int64 0xf0f) (int 0xf0f)) |}];
    check "fA0f";
    [%expect {|
          ((int64 0xfa0f) (int 0xfa0f)) |}];
    check "0";
    [%expect {|
        ((int64 0x0) (int 0x0)) |}];
    (* Test a value that doesn't fit in a 63-bit int. *)
    check "0xffffffffff22f000";
    [%expect {| ((int64 0xffffffffff22f000) (int 0x7fffffffff22f000)) |}]
  ;;
end

let experimental_flag ~default flag =
  if Env_vars.experimental then flag else Command.Param.return default
;;
