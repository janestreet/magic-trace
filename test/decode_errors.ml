open! Core

let%expect_test "decode error during memmove" =
  Perf_script.run ~trace_mode:Userspace "memmove_decode_error.perf";
  [%expect
    {|
    293415/293415 47170.086912824:   call                           40b06c itch_bbo::book::Book::add_order+0x51c =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    293415/293415 47170.086912825:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 =>           40b072 itch_bbo::book::Book::add_order+0x522
    ->     19ns BEGIN __memmove_avx_unaligned_erms
    293415/293415 47170.086912826:   call                           40b093 itch_bbo::book::Book::add_order+0x543 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->     20ns END   __memmove_avx_unaligned_erms
     instruction trace error type 1 time 47170.086912826 cpu -1 pid 293415 tid 293415 ip 0x7ffff7327730 code 7: Overflow packet
    ->     21ns BEGIN [decode error: Overflow packet]
    ->          END   [decode error: Overflow packet]
    ->      0ns BEGIN itch_bbo::book::Book::add_order [inferred start time]
    ->     21ns BEGIN __memmove_avx_unaligned_erms
    ->     21ns END   __memmove_avx_unaligned_erms
    ->     21ns END   itch_bbo::book::Book::add_order
    293415/293415 47170.086912872:   tr strt                             0 [unknown] =>     7ffff7327786 __memmove_avx_unaligned_erms+0x56
    293415/293415 47170.086912946:   return                   7ffff73277d4 __memmove_avx_unaligned_erms+0xa4 =>           40b099 itch_bbo::book::Book::add_order+0x549
    ->     67ns BEGIN __memmove_avx_unaligned_erms
    END
    ->     21ns BEGIN itch_bbo::book::Book::add_order [inferred start time]
    ->    141ns END   __memmove_avx_unaligned_erms
    ->    141ns END   itch_bbo::book::Book::add_order |}]
;;

let%expect_test "decode error during rust B-tree rebalance" =
  Perf_script.run ~trace_mode:Userspace "btree_rebalance_decode_error.perf";
  [%expect
    {|
    364691/364691 62709.735347729:   call                           40bc5a itch_bbo::book::Book::delete_order+0x3ca =>           40a550 remove_leaf_kv+0x0
    364691/364691 62709.735347731:   call                           40a5b2 remove_leaf_kv+0x62 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->     28ns BEGIN remove_leaf_kv
    364691/364691 62709.735347733:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 =>           40a5b5 remove_leaf_kv+0x65
    ->     30ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347733:   call                           40a5d6 remove_leaf_kv+0x86 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    364691/364691 62709.735347737:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 =>           40a5d9 remove_leaf_kv+0x89
    ->     32ns END   __memmove_avx_unaligned_erms
    ->     32ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347741:   call                           40a6c3 remove_leaf_kv+0x173 =>           40a1d0 merge_tracking_child_edge+0x0
    ->     36ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347757:   call                           40a297 merge_tracking_child_edge+0xc7 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->     40ns BEGIN merge_tracking_child_edge
    364691/364691 62709.735347758:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 =>           40a29d merge_tracking_child_edge+0xcd
    ->     56ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347759:   call                           40a2c9 merge_tracking_child_edge+0xf9 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->     57ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347760:   return                   7ffff73277b6 __memmove_avx_unaligned_erms+0x86 =>           40a2cf merge_tracking_child_edge+0xff
    ->     58ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347760:   call                           40a2ee merge_tracking_child_edge+0x11e =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
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
    364691/364691 62709.735347806:   tr strt                             0 [unknown] =>     7ffff7327786 __memmove_avx_unaligned_erms+0x56
    364691/364691 62709.735347959:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 =>           40a2f4 merge_tracking_child_edge+0x124
    ->    105ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347962:   call                           40a320 merge_tracking_child_edge+0x150 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->    258ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347963:   return                   7ffff73277c7 __memmove_avx_unaligned_erms+0x97 =>           40a326 merge_tracking_child_edge+0x156
    ->    261ns BEGIN __memmove_avx_unaligned_erms
    364691/364691 62709.735347964:   call                           40a340 merge_tracking_child_edge+0x170 =>     7ffff7327730 __memmove_avx_unaligned_erms+0x0
    ->    262ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735347964:   return                   7ffff732775e __memmove_avx_unaligned_erms+0x2e =>           40a346 merge_tracking_child_edge+0x176
    364691/364691 62709.735348001:   call                           40a4dd merge_tracking_child_edge+0x30d =>           40e1d0 __rust_dealloc+0x0
    ->    263ns BEGIN __memmove_avx_unaligned_erms
    ->    300ns END   __memmove_avx_unaligned_erms
    364691/364691 62709.735348001:   jmp                            40e1d0 __rust_dealloc+0x0 =>           4269f0 __rdl_dealloc+0x0
    364691/364691 62709.735348001:   jmp                            4269f0 __rdl_dealloc+0x0 =>     7ffff724d0e0 cfree@GLIBC_2.2.5+0x0
    364691/364691 62709.735348001:   jmp                      7ffff724d13d cfree@GLIBC_2.2.5+0x5d =>     7ffff7249c00 _int_free+0x0
    364691/364691 62709.735348120:   return                   7ffff7249d52 _int_free+0x152 =>           40a4e3 merge_tracking_child_edge+0x313
    ->    300ns BEGIN __rust_dealloc
    ->    329ns END   __rust_dealloc
    ->    329ns BEGIN __rdl_dealloc
    ->    359ns END   __rdl_dealloc
    ->    359ns BEGIN cfree@GLIBC_2.2.5
    ->    389ns END   cfree@GLIBC_2.2.5
    ->    389ns BEGIN _int_free
    364691/364691 62709.735348120:   return                         40a517 merge_tracking_child_edge+0x347 =>           40a6c8 remove_leaf_kv+0x178
     instruction trace error type 1 time 62709.735348121 cpu -1 pid 364691 tid 364691 ip 0x7ffff7327730 code 7: Overflow packet
    ->    420ns BEGIN [decode error: Overflow packet]
    ->          END   [decode error: Overflow packet]
    ->     59ns BEGIN remove_leaf_kv [inferred start time]
    ->     59ns BEGIN merge_tracking_child_edge [inferred start time]
    ->    419ns END   _int_free
    ->    419ns END   merge_tracking_child_edge
    ->    420ns END   remove_leaf_kv
    END

    |}]
;;
