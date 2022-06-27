open! Core
open! Async

(* Generated as per this program:

  {[
    exception Test

    let[@inline never] foo () = ()

    let[@inline never] rec raise_after = function
      | 0 -> raise Test
      | n -> 1 + raise_after (n - 1)
    ;;
    let () =
      while true do
        let _ =
          try raise_after 20 with
          | Test -> 0
        in
        for i = 0 to 1000000; do Sys.opaque_identity () done;
        ()
      done
    ;;
  ]}
*)

let%expect_test "A raise_notrace OCaml exception" =
  let ocaml_exception_info =
    Magic_trace_core.Ocaml_exception_info.create
      ~entertraps:[| 0x411030L |]
      ~pushtraps:[| 0x41100bL |]
      ~poptraps:[| 0x411026L |]
  in
  let%map () =
    Perf_script.run ~ocaml_exception_info ~trace_scope:Userspace "ocaml_exceptions.perf"
  in
  [%expect
    {|
    23860/23860 426567.068172167:                            1   branches:uH:   call                           411021 camlRaise_test__entry+0x71 (foo.so) =>           410f70 camlRaise_test__raise_after_265+0x0 (foo.so)
    ->      3ns BEGIN camlRaise_test__raise_after_265
    ->      6ns BEGIN camlRaise_test__raise_after_265
    ->      9ns BEGIN camlRaise_test__raise_after_265
    ->     13ns BEGIN camlRaise_test__raise_after_265
    ->     13ns BEGIN camlRaise_test__raise_after_265
    ->     13ns BEGIN camlRaise_test__raise_after_265
    ->     13ns BEGIN camlRaise_test__raise_after_265
    ->     14ns BEGIN camlRaise_test__raise_after_265
    ->     15ns BEGIN camlRaise_test__raise_after_265
    ->     16ns BEGIN camlRaise_test__raise_after_265
    ->     16ns BEGIN camlRaise_test__raise_after_265
    ->     16ns BEGIN camlRaise_test__raise_after_265
    ->     17ns BEGIN camlRaise_test__raise_after_265
    ->     18ns BEGIN camlRaise_test__raise_after_265
    ->     19ns BEGIN camlRaise_test__raise_after_265
    23860/23860 426567.068172190:                            1   branches:uH:   jmp                            410fa0 camlRaise_test__raise_after_265+0x30 (foo.so) =>           411030 camlRaise_test__entry+0x80 (foo.so)
    ->     20ns BEGIN camlRaise_test__raise_after_265
    ->     20ns BEGIN camlRaise_test__raise_after_265
    ->     20ns BEGIN camlRaise_test__raise_after_265
    ->     21ns BEGIN camlRaise_test__raise_after_265
    ->     22ns BEGIN camlRaise_test__raise_after_265
    END
    ->      0ns BEGIN camlRaise_test__entry [inferred start time]
    ->      0ns BEGIN camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     23ns END   camlRaise_test__raise_after_265
    ->     24ns END   camlRaise_test__entry |}]
;;
