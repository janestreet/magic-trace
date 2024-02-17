open! Core
open! Async

let%expect_test "decode error during memmove" =
  let%map () = Perf_script.run ~trace_scope:Userspace "memmove_decode_error.perf" in
  [%expect
    {|
    293415/293415 47170.086912824:                            1   branches:uH:   call                           40b06c itch_bbo::book::Book::add_order+0x51c (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    293415/293415 47170.086912825:                            1   branches:uH:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 (foo.so) =>           40b072 itch_bbo::book::Book::add_order+0x522 (foo.so)
    ->     19ns BEGIN __memmove_avx_unaligned_erms
    293415/293415 47170.086912826:                            1   branches:uH:   call                           40b093 itch_bbo::book::Book::add_order+0x543 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->     20ns END   __memmove_avx_unaligned_erms
     instruction trace error type 1 time 47170.086912826 cpu -1 pid 293415 tid 293415 ip 0x7ffff7327730 code 7: Overflow packet
    ->     21ns BEGIN [decode error: Overflow packet]
    ->          END   [decode error: Overflow packet]
    ->      0ns BEGIN itch_bbo::book::Book::add_order [inferred start time]
    ->     21ns BEGIN __memmove_avx_unaligned_erms
    ->     21ns END   __memmove_avx_unaligned_erms
    ->     21ns END   itch_bbo::book::Book::add_order
    293415/293415 47170.086912872:                            1   branches:uH:   tr strt                             0 [unknown] (foo.so) =>     7ffff7327786 __memmove_avx_unaligned_erms+0x56 (foo.so)
    293415/293415 47170.086912946:                            1   branches:uH:   return                   7ffff73277d4 __memmove_avx_unaligned_erms+0xa4 (foo.so) =>           40b099 itch_bbo::book::Book::add_order+0x549 (foo.so)
    ->     67ns BEGIN __memmove_avx_unaligned_erms
    INPUT TRACE STREAM ENDED, any lines printed below this were deferred
    ->     21ns BEGIN itch_bbo::book::Book::add_order [inferred start time]
    ->    141ns END   __memmove_avx_unaligned_erms
    ->    141ns END   itch_bbo::book::Book::add_order
    Warning: perf reported an error decoding the trace: 'Overflow packet' @ IP 0x7ffff7327730.
    ! |}]
;;

let%expect_test "decode error during rust B-tree rebalance" =
  let%map () =
    Perf_script.run ~trace_scope:Userspace "btree_rebalance_decode_error.perf"
  in
  [%expect
    {|
    364691/364691 62709.735347729:                            1   branches:uH:   call                           40bc5a itch_bbo::book::Book::delete_order+0x3ca (foo.so) =>           40a550 remove_leaf_kv+0x0 (foo.so)
    364691/364691 62709.735347731:                            1   branches:uH:   call                           40a5b2 remove_leaf_kv+0x62 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->     28ns BEGIN remove_leaf_kv
    364691/364691 62709.735347733:                            1   branches:uH:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 (foo.so) =>           40a5b5 remove_leaf_kv+0x65 (foo.so)
    ->     30ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347733:                            1   branches:uH:   call                           40a5d6 remove_leaf_kv+0x86 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    364691/364691 62709.735347737:                            1   branches:uH:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 (foo.so) =>           40a5d9 remove_leaf_kv+0x89 (foo.so)
    ->     32ns END   __memmove_avx_unaligned_erms
    ->     32ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347741:                            1   branches:uH:   call                           40a6c3 remove_leaf_kv+0x173 (foo.so) =>           40a1d0 merge_tracking_child_edge+0x0 (foo.so)
    ->     36ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347757:                            1   branches:uH:   call                           40a297 merge_tracking_child_edge+0xc7 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->     40ns BEGIN merge_tracking_child_edge
    364691/364691 62709.735347758:                            1   branches:uH:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 (foo.so) =>           40a29d merge_tracking_child_edge+0xcd (foo.so)
    ->     56ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347759:                            1   branches:uH:   call                           40a2c9 merge_tracking_child_edge+0xf9 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->     57ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347760:                            1   branches:uH:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 (foo.so) =>           40a2cf merge_tracking_child_edge+0xff (foo.so)
    ->     58ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347760:                            1   branches:uH:   call                           40a2ee merge_tracking_child_edge+0x11e (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
     instruction trace error type 1 time 62709.735347760 cpu -1 pid 364691 tid 364691 ip 0x7ffff7327730 code 7: Overflow packet
    ->     59ns BEGIN [decode error: Overflow packet]
    ->          END   [decode error: Overflow packet]
    ->      0ns BEGIN itch_bbo::book::Book::delete_order [inferred start time]
    ->     59ns END   __memmove_avx_unaligned_erms
    ->     59ns BEGIN __memmove_avx_unaligned_erms
    ->     59ns END   __memmove_avx_unaligned_erms
    ->     59ns END   merge_tracking_child_edge
    ->     59ns END   remove_leaf_kv
    ->     59ns END   itch_bbo::book::Book::delete_order
    364691/364691 62709.735347806:                            1   branches:uH:   tr strt                             0 [unknown] (foo.so) =>     7ffff7327786 __memmove_avx_unaligned_erms+0x56 (foo.so)
    364691/364691 62709.735347959:                            1   branches:uH:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 (foo.so) =>           40a2f4 merge_tracking_child_edge+0x124 (foo.so)
    ->    105ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347962:                            1   branches:uH:   call                           40a320 merge_tracking_child_edge+0x150 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->    258ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347963:                            1   branches:uH:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 (foo.so) =>           40a326 merge_tracking_child_edge+0x156 (foo.so)
    ->    261ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347964:                            1   branches:uH:   call                           40a340 merge_tracking_child_edge+0x170 (foo.so) =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0 (foo.so)
    ->    262ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347964:                            1   branches:uH:   return                   7ffff732775e __memmove_avx_unaligned_erms+0x2e (foo.so) =>           40a346 merge_tracking_child_edge+0x176 (foo.so)
    364691/364691 62709.735348001:                            1   branches:uH:   call                           40a4dd merge_tracking_child_edge+0x30d (foo.so) =>           40e1d0 __rust_dealloc+0x0 (foo.so)
    ->    263ns BEGIN __memmove_avx_unaligned_erms
    ->    300ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735348001:                            1   branches:uH:   jmp                            40e1d0 __rust_dealloc+0x0 (foo.so) =>           4269f0 __rdl_dealloc+0x0 (foo.so)
    364691/364691 62709.735348001:                            1   branches:uH:   jmp                            4269f0 __rdl_dealloc+0x0 (foo.so) =>     7ffff724d0e0 cfree@GLIBC_2.2.5+0x0 (foo.so)
    364691/364691 62709.735348001:                            1   branches:uH:   jmp                      7ffff724d13d cfree@GLIBC_2.2.5+0x5d (foo.so) =>     7ffff7249c00 _int_free+0x0 (foo.so)
    364691/364691 62709.735348120:                            1   branches:uH:   return                   7ffff7249d52 _int_free+0x152 (foo.so) =>           40a4e3 merge_tracking_child_edge+0x313 (foo.so)
    ->    300ns BEGIN __rust_dealloc
    ->    329ns END   __rust_dealloc
    ->    329ns BEGIN __rdl_dealloc
    ->    359ns END   __rdl_dealloc
    ->    359ns BEGIN cfree@GLIBC_2.2.5
    ->    389ns END   cfree@GLIBC_2.2.5
    ->    389ns BEGIN _int_free
    364691/364691 62709.735348120:                            1   branches:uH:   return                         40a517 merge_tracking_child_edge+0x347 (foo.so) =>           40a6c8 remove_leaf_kv+0x178 (foo.so)
     instruction trace error type 1 time 62709.735348121 cpu -1 pid 364691 tid 364691 ip 0x7ffff7327730 code 7: Overflow packet
    ->    420ns BEGIN [decode error: Overflow packet]
    ->          END   [decode error: Overflow packet]
    ->     59ns BEGIN remove_leaf_kv [inferred start time]
    ->     59ns BEGIN merge_tracking_child_edge [inferred start time]
    ->    419ns END   _int_free
    ->    419ns END   merge_tracking_child_edge
    ->    420ns END   remove_leaf_kv
    INPUT TRACE STREAM ENDED, any lines printed below this were deferred
    Warning: perf reported an error decoding the trace: 'Overflow packet' @ IP 0x7ffff7327730.
    !Warning: perf reported an error decoding the trace: 'Overflow packet' @ IP 0x7ffff7327730.
    ! |}]
;;
