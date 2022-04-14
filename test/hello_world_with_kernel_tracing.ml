open! Core

let%expect_test "C hello world with kernel tracing" =
  Perf_script.run ~trace_mode:Userspace_and_kernel "hello_world_with_kernel_tracing.perf";
  [%expect
    {|
    681400/681400 2065408.180095561:   tr strt                             0 [unknown] =>     7faea66c088d _dl_map_object_from_fd+0xa6d
    681400/681400 2065408.180095842:   hw int                   7faea66c0a6e _dl_map_object_from_fd+0xc4e => ffffffffae200ab0 asm_exc_page_fault+0x0
    681400/681400 2065408.180097200:   tr strt                             0 [unknown] =>     7faea66c0a6e _dl_map_object_from_fd+0xc4e
    ->    281ns BEGIN asm_exc_page_fault
    681400/681400 2065408.180097225:   call                     7faea66c0a5b _dl_map_object_from_fd+0xc3b =>     7faea66bfdb0 _dl_process_pt_gnu_property+0x0
    ->  1.639us END   asm_exc_page_fault
    681400/681400 2065408.180097230:   return                   7faea66bfe16 _dl_process_pt_gnu_property+0x66 =>     7faea66c0a61 _dl_map_object_from_fd+0xc41
    ->  1.664us BEGIN _dl_process_pt_gnu_property
    681400/681400 2065408.180097250:   syscall                  7faea66dbbf9 __GI___close_nocancel+0x9 => ffffffffae200000 __entry_text_start+0x0
    ->  1.669us END   _dl_process_pt_gnu_property
    681400/681400 2065408.180097372:   tr strt                             0 [unknown] =>     7faea66dbbfb __GI___close_nocancel+0xb
    ->  1.689us BEGIN __entry_text_start
    681400/681400 2065408.180097373:   return                   7faea66dbc03 __GI___close_nocancel+0x13 =>     7faea66c0bfb _dl_map_object_from_fd+0xddb
    ->  1.811us END   __entry_text_start
    681400/681400 2065408.180097374:   call                     7faea66c0c34 _dl_map_object_from_fd+0xe14 =>     7faea66ca040 _dl_setup_hash+0x0
    681400/681400 2065408.180097394:   return                   7faea66ca0ad _dl_setup_hash+0x6d =>     7faea66c0c39 _dl_map_object_from_fd+0xe19
    ->  1.813us BEGIN _dl_setup_hash
    681400/681400 2065408.180097395:   call                     7faea66c0cd5 _dl_map_object_from_fd+0xeb5 =>     7faea66c4710 _dl_add_to_namespace_list+0x0
    ->  1.833us END   _dl_setup_hash
    681400/681400 2065408.180097396:   call                     7faea66c4728 _dl_add_to_namespace_list+0x18 =>     7faea65298a0 __pthread_mutex_lock+0x0
    ->  1.834us BEGIN _dl_add_to_namespace_list
    681400/681400 2065408.180097398:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c472e _dl_add_to_namespace_list+0x1e
    ->  1.835us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180097414:   jmp                      7faea66c4791 _dl_add_to_namespace_list+0x81 =>     7faea652b430 __pthread_mutex_unlock+0x0
    ->  1.837us END   __pthread_mutex_lock
    681400/681400 2065408.180097416:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c0cda _dl_map_object_from_fd+0xeba
    ->  1.853us END   _dl_add_to_namespace_list
    ->  1.853us BEGIN __pthread_mutex_unlock
    ->  1.854us END   __pthread_mutex_unlock
    ->  1.854us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180097416:   call                     7faea66c0edf _dl_map_object_from_fd+0x10bf =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    681400/681400 2065408.180097418:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66c0ee4 _dl_map_object_from_fd+0x10c4
    ->  1.855us END   __pthread_mutex_unlock_usercnt
    ->  1.855us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180097418:   call                     7faea66c0d07 _dl_map_object_from_fd+0xee7 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180097419:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66c0d0c _dl_map_object_from_fd+0xeec
    ->  1.857us END   _dl_audit_activity_nsid
    ->  1.857us BEGIN _dl_debug_state
    681400/681400 2065408.180097419:   call                     7faea66c0d38 _dl_map_object_from_fd+0xf18 =>     7faea66d0ef0 _dl_audit_objopen+0x0
    681400/681400 2065408.180097420:   return                   7faea66d0efe _dl_audit_objopen+0xe =>     7faea66c0d3d _dl_map_object_from_fd+0xf1d
    ->  1.858us END   _dl_debug_state
    ->  1.858us BEGIN _dl_audit_objopen
    681400/681400 2065408.180097420:   return                   7faea66c03de _dl_map_object_from_fd+0x5be =>     7faea66c17ac _dl_map_object+0x1fc
    681400/681400 2065408.180097426:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66c55b9 dl_open_worker_begin+0xa9
    ->  1.859us END   _dl_audit_objopen
    ->  1.859us END   _dl_map_object_from_fd
    681400/681400 2065408.180097437:   call                     7faea66c561a dl_open_worker_begin+0x10a =>     7faea66bb2c0 _dl_map_object_deps+0x0
    ->  1.865us END   _dl_map_object
    681400/681400 2065408.180097459:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    ->  1.876us BEGIN _dl_map_object_deps
    681400/681400 2065408.180097459:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180097472:   return                   7faea66dfa8a strchr+0x5a =>     7faea66bf219 _dl_dst_count+0x19
    ->  1.898us BEGIN _dl_dst_count
    ->  1.904us BEGIN strchr
    681400/681400 2065408.180097472:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    681400/681400 2065408.180097474:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    ->  1.911us END   strchr
    ->  1.911us END   _dl_dst_count
    681400/681400 2065408.180097492:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    ->  1.913us BEGIN _dl_catch_exception
    681400/681400 2065408.180097492:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180097494:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    ->  1.931us BEGIN __sigsetjmp
    ->  1.932us END   __sigsetjmp
    ->  1.932us BEGIN __sigjmp_save
    681400/681400 2065408.180097494:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    681400/681400 2065408.180097494:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180097495:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->  1.933us END   __sigjmp_save
    ->  1.933us BEGIN openaux
    ->  1.933us BEGIN _dl_map_object
    681400/681400 2065408.180097495:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097501:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  1.934us BEGIN _dl_name_match_p
    ->  1.937us BEGIN strcmp
    681400/681400 2065408.180097501:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097508:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->   1.94us END   strcmp
    ->   1.94us BEGIN strcmp
    681400/681400 2065408.180097509:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  1.947us END   strcmp
    681400/681400 2065408.180097509:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097509:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097526:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  1.948us END   _dl_name_match_p
    ->  1.948us BEGIN _dl_name_match_p
    ->  1.956us BEGIN strcmp
    681400/681400 2065408.180097526:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097532:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  1.965us END   strcmp
    ->  1.965us BEGIN strcmp
    681400/681400 2065408.180097533:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  1.971us END   strcmp
    681400/681400 2065408.180097533:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097542:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  1.972us END   _dl_name_match_p
    ->  1.972us BEGIN strcmp
    681400/681400 2065408.180097542:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097542:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097546:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  1.981us END   strcmp
    ->  1.981us BEGIN _dl_name_match_p
    ->  1.983us BEGIN strcmp
    681400/681400 2065408.180097546:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097553:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  1.985us END   strcmp
    ->  1.985us BEGIN strcmp
    681400/681400 2065408.180097553:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180097554:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    ->  1.992us END   strcmp
    ->  1.992us END   _dl_name_match_p
    681400/681400 2065408.180097554:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180097555:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    ->  1.993us END   _dl_map_object
    ->  1.993us END   openaux
    681400/681400 2065408.180097555:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    681400/681400 2065408.180097555:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180097565:   return                   7faea66dfbb4 strchr+0x184 =>     7faea66bf219 _dl_dst_count+0x19
    ->  1.994us END   _dl_catch_exception
    ->  1.994us BEGIN _dl_dst_count
    ->  1.999us BEGIN strchr
    681400/681400 2065408.180097565:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    681400/681400 2065408.180097566:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    ->  2.004us END   strchr
    ->  2.004us END   _dl_dst_count
    681400/681400 2065408.180097571:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    ->  2.005us BEGIN _dl_catch_exception
    681400/681400 2065408.180097571:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180097575:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    ->   2.01us BEGIN __sigsetjmp
    ->  2.012us END   __sigsetjmp
    ->  2.012us BEGIN __sigjmp_save
    681400/681400 2065408.180097575:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    681400/681400 2065408.180097575:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180097579:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->  2.014us END   __sigjmp_save
    ->  2.014us BEGIN openaux
    ->  2.016us BEGIN _dl_map_object
    681400/681400 2065408.180097579:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097586:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.018us BEGIN _dl_name_match_p
    ->  2.021us BEGIN strcmp
    681400/681400 2065408.180097586:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097587:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.025us END   strcmp
    ->  2.025us BEGIN strcmp
    681400/681400 2065408.180097588:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.026us END   strcmp
    681400/681400 2065408.180097589:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->  2.027us END   _dl_name_match_p
    681400/681400 2065408.180097589:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097595:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.028us BEGIN _dl_name_match_p
    ->  2.031us BEGIN strcmp
    681400/681400 2065408.180097595:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097600:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.034us END   strcmp
    ->  2.034us BEGIN strcmp
    681400/681400 2065408.180097600:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180097600:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097606:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  2.039us END   strcmp
    ->  2.039us END   _dl_name_match_p
    ->  2.039us BEGIN strcmp
    681400/681400 2065408.180097606:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097606:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097610:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.045us END   strcmp
    ->  2.045us BEGIN _dl_name_match_p
    ->  2.047us BEGIN strcmp
    681400/681400 2065408.180097610:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097623:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.049us END   strcmp
    ->  2.049us BEGIN strcmp
    681400/681400 2065408.180097624:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.062us END   strcmp
    681400/681400 2065408.180097624:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097639:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  2.063us END   _dl_name_match_p
    ->  2.063us BEGIN strcmp
    681400/681400 2065408.180097639:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097639:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097642:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.078us END   strcmp
    ->  2.078us BEGIN _dl_name_match_p
    ->  2.079us BEGIN strcmp
    681400/681400 2065408.180097642:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097644:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.081us END   strcmp
    ->  2.081us BEGIN strcmp
    681400/681400 2065408.180097644:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097649:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.083us END   strcmp
    ->  2.083us BEGIN strcmp
    681400/681400 2065408.180097649:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180097650:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    ->  2.088us END   strcmp
    ->  2.088us END   _dl_name_match_p
    681400/681400 2065408.180097650:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180097652:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    ->  2.089us END   _dl_map_object
    ->  2.089us END   openaux
    681400/681400 2065408.180097831:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    ->  2.091us END   _dl_catch_exception
    681400/681400 2065408.180097831:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180097843:   return                   7faea66dfbb4 strchr+0x184 =>     7faea66bf219 _dl_dst_count+0x19
    ->   2.27us BEGIN _dl_dst_count
    ->  2.276us BEGIN strchr
    681400/681400 2065408.180097843:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    681400/681400 2065408.180097844:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    ->  2.282us END   strchr
    ->  2.282us END   _dl_dst_count
    681400/681400 2065408.180097846:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    ->  2.283us BEGIN _dl_catch_exception
    681400/681400 2065408.180097850:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    ->  2.285us BEGIN __sigsetjmp
    681400/681400 2065408.180097850:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    681400/681400 2065408.180097851:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    ->  2.289us END   __sigsetjmp
    ->  2.289us BEGIN __sigjmp_save
    ->   2.29us END   __sigjmp_save
    681400/681400 2065408.180097851:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180097853:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->   2.29us BEGIN openaux
    ->  2.291us BEGIN _dl_map_object
    681400/681400 2065408.180097853:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097862:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.292us BEGIN _dl_name_match_p
    ->  2.296us BEGIN strcmp
    681400/681400 2065408.180097862:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097867:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.301us END   strcmp
    ->  2.301us BEGIN strcmp
    681400/681400 2065408.180097868:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.306us END   strcmp
    681400/681400 2065408.180097868:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097868:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097877:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.307us END   _dl_name_match_p
    ->  2.307us BEGIN _dl_name_match_p
    ->  2.311us BEGIN strcmp
    681400/681400 2065408.180097877:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097886:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.316us END   strcmp
    ->  2.316us BEGIN strcmp
    681400/681400 2065408.180097887:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.325us END   strcmp
    681400/681400 2065408.180097887:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097890:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  2.326us END   _dl_name_match_p
    ->  2.326us BEGIN strcmp
    681400/681400 2065408.180097891:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->  2.329us END   strcmp
    681400/681400 2065408.180097891:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097895:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->   2.33us BEGIN _dl_name_match_p
    ->  2.332us BEGIN strcmp
    681400/681400 2065408.180097895:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097904:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.334us END   strcmp
    ->  2.334us BEGIN strcmp
    681400/681400 2065408.180097905:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.343us END   strcmp
    681400/681400 2065408.180097905:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097914:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  2.344us END   _dl_name_match_p
    ->  2.344us BEGIN strcmp
    681400/681400 2065408.180097914:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180097914:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097917:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.353us END   strcmp
    ->  2.353us BEGIN _dl_name_match_p
    ->  2.354us BEGIN strcmp
    681400/681400 2065408.180097917:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180097919:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.356us END   strcmp
    ->  2.356us BEGIN strcmp
    681400/681400 2065408.180097920:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    ->  2.358us END   strcmp
    681400/681400 2065408.180097927:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.359us BEGIN strcmp
    681400/681400 2065408.180097928:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    ->  2.366us END   strcmp
    681400/681400 2065408.180097929:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    ->  2.367us END   _dl_name_match_p
    681400/681400 2065408.180097929:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180097932:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    ->  2.368us END   _dl_map_object
    ->  2.368us END   openaux
    ->  2.371us END   _dl_catch_exception
    681400/681400 2065408.180097984:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66bba55 _dl_map_object_deps+0x795
    ->  2.412us END   _dl_map_object_deps
    ->  2.412us BEGIN __libc_malloc
    681400/681400 2065408.180097986:   call                     7faea66bbf83 _dl_map_object_deps+0xcc3 =>     7faea66e01d0 memcpy+0x0
    ->  2.423us END   __libc_malloc
    ->  2.423us END   dl_open_worker_begin
    ->  2.423us BEGIN _dl_map_object_deps
    681400/681400 2065408.180097992:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66bbf89 _dl_map_object_deps+0xcc9
    ->  2.425us BEGIN memcpy
    681400/681400 2065408.180097992:   call                     7faea66bbd4a _dl_map_object_deps+0xa8a =>     7faea66ca220 _dl_sort_maps+0x0
    681400/681400 2065408.180097999:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    ->  2.431us END   memcpy
    ->  2.431us BEGIN _dl_sort_maps
    681400/681400 2065408.180098001:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    ->  2.438us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180098001:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    681400/681400 2065408.180098008:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    ->   2.44us END   dfs_traversal.part.0
    ->   2.44us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180098009:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    ->  2.447us END   dfs_traversal.part.0
    681400/681400 2065408.180098010:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    ->  2.448us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180098010:   call                     7faea66ca674 _dl_sort_maps+0x454 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180098015:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66ca67a _dl_sort_maps+0x45a
    ->  2.449us END   dfs_traversal.part.0
    ->  2.449us BEGIN memcpy
    681400/681400 2065408.180098016:   return                   7faea66ca36e _dl_sort_maps+0x14e =>     7faea66bbd4f _dl_map_object_deps+0xa8f
    ->  2.454us END   memcpy
    681400/681400 2065408.180098021:   return                   7faea66bbdaf _dl_map_object_deps+0xaef =>     7faea66c561f dl_open_worker_begin+0x10f
    ->  2.455us END   _dl_sort_maps
    681400/681400 2065408.180098034:   call                     7faea66c565e dl_open_worker_begin+0x14e =>     7faea66cc690 _dl_check_map_versions+0x0
    ->   2.46us END   _dl_map_object_deps
    681400/681400 2065408.180098034:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098034:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098055:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.473us BEGIN _dl_check_map_versions
    ->   2.48us BEGIN _dl_name_match_p
    ->  2.487us BEGIN strcmp
    681400/681400 2065408.180098055:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098057:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.494us END   strcmp
    ->  2.494us BEGIN strcmp
    681400/681400 2065408.180098058:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->  2.496us END   strcmp
    681400/681400 2065408.180098058:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098058:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098062:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.497us END   _dl_name_match_p
    ->  2.497us BEGIN _dl_name_match_p
    ->  2.499us BEGIN strcmp
    681400/681400 2065408.180098062:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098065:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.501us END   strcmp
    ->  2.501us BEGIN strcmp
    681400/681400 2065408.180098066:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->  2.504us END   strcmp
    681400/681400 2065408.180098066:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098066:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098069:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.505us END   _dl_name_match_p
    ->  2.505us BEGIN _dl_name_match_p
    ->  2.506us BEGIN strcmp
    681400/681400 2065408.180098069:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098072:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.508us END   strcmp
    ->  2.508us BEGIN strcmp
    681400/681400 2065408.180098073:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->  2.511us END   strcmp
    681400/681400 2065408.180098073:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098073:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098076:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.512us END   _dl_name_match_p
    ->  2.512us BEGIN _dl_name_match_p
    ->  2.513us BEGIN strcmp
    681400/681400 2065408.180098076:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098077:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.515us END   strcmp
    ->  2.515us BEGIN strcmp
    681400/681400 2065408.180098077:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098081:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.516us END   strcmp
    ->  2.516us BEGIN strcmp
    681400/681400 2065408.180098082:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->   2.52us END   strcmp
    681400/681400 2065408.180098100:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    ->  2.521us END   _dl_name_match_p
    681400/681400 2065408.180098114:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    ->  2.539us BEGIN strcmp
    681400/681400 2065408.180098114:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098114:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098118:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.553us END   strcmp
    ->  2.553us BEGIN _dl_name_match_p
    ->  2.555us BEGIN strcmp
    681400/681400 2065408.180098118:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098120:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.557us END   strcmp
    ->  2.557us BEGIN strcmp
    681400/681400 2065408.180098120:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    681400/681400 2065408.180098121:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->  2.559us END   strcmp
    ->  2.559us END   _dl_name_match_p
    681400/681400 2065408.180098121:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098125:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->   2.56us BEGIN _dl_name_match_p
    ->  2.562us BEGIN strcmp
    681400/681400 2065408.180098125:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098128:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.564us END   strcmp
    ->  2.564us BEGIN strcmp
    681400/681400 2065408.180098130:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->  2.567us END   strcmp
    681400/681400 2065408.180098130:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180098130:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098132:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  2.569us END   _dl_name_match_p
    ->  2.569us BEGIN _dl_name_match_p
    ->   2.57us BEGIN strcmp
    681400/681400 2065408.180098132:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098138:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  2.571us END   strcmp
    ->  2.571us BEGIN strcmp
    681400/681400 2065408.180098138:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66cc769 _dl_check_map_versions+0xd9
    681400/681400 2065408.180098223:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    ->  2.577us END   strcmp
    ->  2.577us END   _dl_name_match_p
    681400/681400 2065408.180098240:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    ->  2.662us BEGIN strcmp
    681400/681400 2065408.180098251:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    ->  2.679us END   strcmp
    681400/681400 2065408.180098263:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    ->   2.69us BEGIN strcmp
    681400/681400 2065408.180098322:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    ->  2.702us END   strcmp
    681400/681400 2065408.180098336:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    ->  2.761us BEGIN strcmp
    681400/681400 2065408.180098339:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    ->  2.775us END   strcmp
    681400/681400 2065408.180098361:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    ->  2.778us BEGIN strcmp
    681400/681400 2065408.180098396:   call                     7faea66ccb77 _dl_check_map_versions+0x4e7 =>     7faea65373b0 calloc+0x0
    ->    2.8us END   strcmp
    681400/681400 2065408.180098397:   call                     7faea6537484 calloc+0xd4 =>     7faea6534f00 _int_malloc+0x0
    ->  2.835us BEGIN calloc
    681400/681400 2065408.180098409:   call                     7faea6535db4 _int_malloc+0xeb4 =>     7faea6532590 alloc_perturb+0x0
    ->  2.836us BEGIN _int_malloc
    681400/681400 2065408.180098411:   return                   7faea653259a alloc_perturb+0xa =>     7faea6535db9 _int_malloc+0xeb9
    ->  2.848us BEGIN alloc_perturb
    681400/681400 2065408.180098413:   return                   7faea6535016 _int_malloc+0x116 =>     7faea6537489 calloc+0xd9
    ->   2.85us END   alloc_perturb
    681400/681400 2065408.180098416:   jmp                      7faea653768f calloc+0x2df =>     7faea662e680 __memset_evex_unaligned_erms+0x0
    ->  2.852us END   _int_malloc
    681400/681400 2065408.180098422:   return                   7faea662e77f __memset_evex_unaligned_erms+0xff =>     7faea66ccb7d _dl_check_map_versions+0x4ed
    ->  2.855us END   calloc
    ->  2.855us BEGIN __memset_evex_unaligned_erms
    681400/681400 2065408.180098473:   return                   7faea66cccb1 _dl_check_map_versions+0x621 =>     7faea66c5663 dl_open_worker_begin+0x153
    ->  2.861us END   __memset_evex_unaligned_erms
    681400/681400 2065408.180098473:   call                     7faea66c5676 dl_open_worker_begin+0x166 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    681400/681400 2065408.180098475:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66c567b dl_open_worker_begin+0x16b
    ->  2.912us END   _dl_check_map_versions
    ->  2.912us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180098475:   call                     7faea66c567f dl_open_worker_begin+0x16f =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180098476:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66c5684 dl_open_worker_begin+0x174
    ->  2.914us END   _dl_audit_activity_nsid
    ->  2.914us BEGIN _dl_debug_update
    681400/681400 2065408.180098476:   call                     7faea66c5693 dl_open_worker_begin+0x183 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180098477:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66c5698 dl_open_worker_begin+0x188
    ->  2.915us END   _dl_debug_update
    ->  2.915us BEGIN _dl_debug_state
    681400/681400 2065408.180098585:   call                     7faea66c5703 dl_open_worker_begin+0x1f3 =>     7faea66d0d30 _dl_cet_open_check+0x0
    ->  2.916us END   _dl_debug_state
    681400/681400 2065408.180098585:   jmp                      7faea66d0d36 _dl_cet_open_check+0x6 =>     7faea66d08a0 dl_cet_check+0x0
    681400/681400 2065408.180098590:   return                   7faea66d0a95 dl_cet_check+0x1f5 =>     7faea66c5708 dl_open_worker_begin+0x1f8
    ->  3.024us BEGIN _dl_cet_open_check
    ->  3.026us END   _dl_cet_open_check
    ->  3.026us BEGIN dl_cet_check
    681400/681400 2065408.180098595:   call                     7faea66c57d9 dl_open_worker_begin+0x2c9 =>     7faea66c78e0 _dl_relocate_object+0x0
    ->  3.029us END   dl_cet_check
    681400/681400 2065408.180098634:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.034us BEGIN _dl_relocate_object
    681400/681400 2065408.180098660:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.073us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098703:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.099us BEGIN do_lookup_x
    681400/681400 2065408.180098712:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  3.142us BEGIN check_match
    681400/681400 2065408.180098726:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.151us BEGIN strcmp
    681400/681400 2065408.180098726:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098730:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.165us END   strcmp
    ->  3.165us BEGIN strcmp
    681400/681400 2065408.180098731:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.169us END   strcmp
    681400/681400 2065408.180098733:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->   3.17us END   check_match
    681400/681400 2065408.180098734:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.172us END   do_lookup_x
    681400/681400 2065408.180098737:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.173us END   _dl_lookup_symbol_x
    681400/681400 2065408.180098742:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.176us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098767:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.181us BEGIN do_lookup_x
    681400/681400 2065408.180098767:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098785:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.206us BEGIN check_match
    ->  3.215us BEGIN strcmp
    681400/681400 2065408.180098785:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098790:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.224us END   strcmp
    ->  3.224us BEGIN strcmp
    681400/681400 2065408.180098791:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.229us END   strcmp
    681400/681400 2065408.180098792:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->   3.23us END   check_match
    681400/681400 2065408.180098793:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.231us END   do_lookup_x
    681400/681400 2065408.180098796:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.232us END   _dl_lookup_symbol_x
    681400/681400 2065408.180098801:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.235us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098817:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->   3.24us BEGIN do_lookup_x
    681400/681400 2065408.180098840:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.256us BEGIN strcmp
    681400/681400 2065408.180098840:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098845:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.279us END   strcmp
    ->  3.279us END   do_lookup_x
    ->  3.279us BEGIN check_match
    ->  3.281us BEGIN strcmp
    681400/681400 2065408.180098846:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.284us END   strcmp
    681400/681400 2065408.180098847:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.285us END   check_match
    ->  3.285us END   _dl_lookup_symbol_x
    ->  3.285us BEGIN do_lookup_x
    681400/681400 2065408.180098848:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.286us END   do_lookup_x
    ->  3.286us END   _dl_relocate_object
    ->  3.286us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098851:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.287us END   _dl_lookup_symbol_x
    ->  3.287us END   dl_open_worker_begin
    ->  3.287us BEGIN _dl_relocate_object
    681400/681400 2065408.180098859:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->   3.29us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098879:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.298us BEGIN do_lookup_x
    681400/681400 2065408.180098884:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  3.318us BEGIN check_match
    681400/681400 2065408.180098897:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.323us BEGIN strcmp
    681400/681400 2065408.180098897:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098899:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.336us END   strcmp
    ->  3.336us BEGIN strcmp
    681400/681400 2065408.180098900:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.338us END   strcmp
    681400/681400 2065408.180098902:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.339us END   check_match
    681400/681400 2065408.180098902:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    681400/681400 2065408.180098905:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.341us END   do_lookup_x
    ->  3.341us END   _dl_lookup_symbol_x
    681400/681400 2065408.180098928:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.344us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098939:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.367us BEGIN do_lookup_x
    681400/681400 2065408.180098939:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180098950:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.378us END   do_lookup_x
    ->  3.378us BEGIN do_lookup_x
    681400/681400 2065408.180098952:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.389us END   do_lookup_x
    681400/681400 2065408.180098954:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.391us END   _dl_lookup_symbol_x
    681400/681400 2065408.180098959:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.393us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180098969:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.398us BEGIN do_lookup_x
    681400/681400 2065408.180098969:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098987:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.408us BEGIN check_match
    ->  3.417us BEGIN strcmp
    681400/681400 2065408.180098987:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180098990:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.426us END   strcmp
    ->  3.426us BEGIN strcmp
    681400/681400 2065408.180098990:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180098992:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.429us END   strcmp
    ->  3.429us END   check_match
    681400/681400 2065408.180098993:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.431us END   do_lookup_x
    681400/681400 2065408.180098997:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.432us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099001:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.436us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099017:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->   3.44us BEGIN do_lookup_x
    681400/681400 2065408.180099025:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  3.456us BEGIN check_match
    681400/681400 2065408.180099038:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.464us BEGIN strcmp
    681400/681400 2065408.180099038:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099043:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.477us END   strcmp
    ->  3.477us BEGIN strcmp
    681400/681400 2065408.180099043:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099045:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.482us END   strcmp
    ->  3.482us END   check_match
    681400/681400 2065408.180099046:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.484us END   do_lookup_x
    681400/681400 2065408.180099049:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.485us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099059:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.488us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099076:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.498us BEGIN do_lookup_x
    681400/681400 2065408.180099076:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099090:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.515us BEGIN check_match
    ->  3.522us BEGIN strcmp
    681400/681400 2065408.180099090:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099092:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.529us END   strcmp
    ->  3.529us BEGIN strcmp
    681400/681400 2065408.180099093:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.531us END   strcmp
    681400/681400 2065408.180099094:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.532us END   check_match
    681400/681400 2065408.180099095:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.533us END   do_lookup_x
    681400/681400 2065408.180099100:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.534us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099107:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.539us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099120:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.546us BEGIN do_lookup_x
    681400/681400 2065408.180099120:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180099126:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.559us END   do_lookup_x
    ->  3.559us BEGIN do_lookup_x
    681400/681400 2065408.180099143:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    ->  3.565us BEGIN check_match
    681400/681400 2065408.180099153:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.582us BEGIN strcmp
    681400/681400 2065408.180099154:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.592us END   strcmp
    681400/681400 2065408.180099156:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.593us END   check_match
    681400/681400 2065408.180099158:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.595us END   do_lookup_x
    681400/681400 2065408.180099162:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.597us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099171:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.601us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099192:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->   3.61us BEGIN do_lookup_x
    681400/681400 2065408.180099194:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  3.631us BEGIN check_match
    681400/681400 2065408.180099203:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.633us BEGIN strcmp
    681400/681400 2065408.180099203:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099207:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.642us END   strcmp
    ->  3.642us BEGIN strcmp
    681400/681400 2065408.180099208:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.646us END   strcmp
    681400/681400 2065408.180099209:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.647us END   check_match
    681400/681400 2065408.180099210:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.648us END   do_lookup_x
    681400/681400 2065408.180099212:   call                     7faea66c85d5 _dl_relocate_object+0xcf5 =>     7faea65391f0 strlen+0x0
    ->  3.649us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099213:   return                   7faea6539267 strlen+0x77 =>     7faea66c85d8 _dl_relocate_object+0xcf8
    ->  3.651us BEGIN strlen
    681400/681400 2065408.180099216:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.652us END   strlen
    681400/681400 2065408.180099236:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.655us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099259:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.675us BEGIN do_lookup_x
    681400/681400 2065408.180099259:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099270:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.698us BEGIN check_match
    ->  3.703us BEGIN strcmp
    681400/681400 2065408.180099270:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099275:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.709us END   strcmp
    ->  3.709us BEGIN strcmp
    681400/681400 2065408.180099275:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099277:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.714us END   strcmp
    ->  3.714us END   check_match
    681400/681400 2065408.180099278:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.716us END   do_lookup_x
    681400/681400 2065408.180099282:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.717us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099297:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  3.721us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099439:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.736us BEGIN do_lookup_x
    681400/681400 2065408.180099463:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  3.878us BEGIN check_match
    681400/681400 2065408.180099489:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.902us BEGIN strcmp
    681400/681400 2065408.180099489:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099495:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.928us END   strcmp
    ->  3.928us BEGIN strcmp
    681400/681400 2065408.180099496:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  3.934us END   strcmp
    681400/681400 2065408.180099498:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  3.935us END   check_match
    681400/681400 2065408.180099499:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  3.937us END   do_lookup_x
    681400/681400 2065408.180099501:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  3.938us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099519:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->   3.94us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099544:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  3.958us BEGIN do_lookup_x
    681400/681400 2065408.180099544:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099557:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  3.983us BEGIN check_match
    ->  3.989us BEGIN strcmp
    681400/681400 2065408.180099557:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099563:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  3.996us END   strcmp
    ->  3.996us BEGIN strcmp
    681400/681400 2065408.180099563:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099565:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.002us END   strcmp
    ->  4.002us END   check_match
    681400/681400 2065408.180099566:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.004us END   do_lookup_x
    681400/681400 2065408.180099571:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.005us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099576:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->   4.01us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099583:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.015us BEGIN do_lookup_x
    681400/681400 2065408.180099600:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  4.022us BEGIN check_match
    681400/681400 2065408.180099609:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.039us BEGIN strcmp
    681400/681400 2065408.180099609:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099613:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.048us END   strcmp
    ->  4.048us BEGIN strcmp
    681400/681400 2065408.180099614:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.052us END   strcmp
    681400/681400 2065408.180099616:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.053us END   check_match
    681400/681400 2065408.180099617:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.055us END   do_lookup_x
    681400/681400 2065408.180099621:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.056us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099636:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->   4.06us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099646:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.075us BEGIN do_lookup_x
    681400/681400 2065408.180099646:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099674:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.085us BEGIN check_match
    ->  4.099us BEGIN strcmp
    681400/681400 2065408.180099676:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.113us END   strcmp
    681400/681400 2065408.180099676:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    681400/681400 2065408.180099676:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099682:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.115us END   check_match
    ->  4.115us BEGIN check_match
    ->  4.118us BEGIN strcmp
    681400/681400 2065408.180099682:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099684:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.121us END   strcmp
    ->  4.121us BEGIN strcmp
    681400/681400 2065408.180099684:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099686:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.123us END   strcmp
    ->  4.123us END   check_match
    681400/681400 2065408.180099687:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.125us END   do_lookup_x
    681400/681400 2065408.180099690:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.126us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099699:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.129us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099712:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.138us BEGIN do_lookup_x
    681400/681400 2065408.180099712:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180099729:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.151us END   do_lookup_x
    ->  4.151us BEGIN do_lookup_x
    681400/681400 2065408.180099740:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    ->  4.168us BEGIN check_match
    681400/681400 2065408.180099746:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.179us BEGIN strcmp
    681400/681400 2065408.180099747:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.185us END   strcmp
    681400/681400 2065408.180099750:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.186us END   check_match
    681400/681400 2065408.180099761:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.189us END   do_lookup_x
    681400/681400 2065408.180099767:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->    4.2us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099784:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.206us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099814:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.223us BEGIN do_lookup_x
    681400/681400 2065408.180099814:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180099830:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.253us END   do_lookup_x
    ->  4.253us BEGIN do_lookup_x
    681400/681400 2065408.180099832:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.269us END   do_lookup_x
    681400/681400 2065408.180099834:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.271us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099850:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.273us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099863:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.289us BEGIN do_lookup_x
    681400/681400 2065408.180099863:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099879:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.302us BEGIN check_match
    ->   4.31us BEGIN strcmp
    681400/681400 2065408.180099879:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099884:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.318us END   strcmp
    ->  4.318us BEGIN strcmp
    681400/681400 2065408.180099884:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099885:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.323us END   strcmp
    ->  4.323us END   check_match
    681400/681400 2065408.180099887:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.324us END   do_lookup_x
    681400/681400 2065408.180099889:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.326us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099907:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.328us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099924:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.346us BEGIN do_lookup_x
    681400/681400 2065408.180099934:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  4.363us BEGIN check_match
    681400/681400 2065408.180099942:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.373us BEGIN strcmp
    681400/681400 2065408.180099942:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099947:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.381us END   strcmp
    ->  4.381us BEGIN strcmp
    681400/681400 2065408.180099947:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180099949:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.386us END   strcmp
    ->  4.386us END   check_match
    681400/681400 2065408.180099950:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.388us END   do_lookup_x
    681400/681400 2065408.180099953:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.389us END   _dl_lookup_symbol_x
    681400/681400 2065408.180099958:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.392us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180099975:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.397us BEGIN do_lookup_x
    681400/681400 2065408.180099978:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  4.414us BEGIN check_match
    681400/681400 2065408.180099986:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.417us BEGIN strcmp
    681400/681400 2065408.180099986:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180099991:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.425us END   strcmp
    ->  4.425us BEGIN strcmp
    681400/681400 2065408.180099992:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->   4.43us END   strcmp
    681400/681400 2065408.180099993:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.431us END   check_match
    681400/681400 2065408.180099994:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.432us END   do_lookup_x
    681400/681400 2065408.180099997:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.433us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100003:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.436us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100046:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.442us BEGIN do_lookup_x
    681400/681400 2065408.180100046:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180100065:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.485us END   do_lookup_x
    ->  4.485us BEGIN do_lookup_x
    681400/681400 2065408.180100067:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    ->  4.504us BEGIN check_match
    681400/681400 2065408.180100072:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.506us BEGIN strcmp
    681400/681400 2065408.180100073:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.511us END   strcmp
    681400/681400 2065408.180100075:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.512us END   check_match
    681400/681400 2065408.180100076:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.514us END   do_lookup_x
    681400/681400 2065408.180100079:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.515us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100087:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.518us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100098:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.526us BEGIN do_lookup_x
    681400/681400 2065408.180100098:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100109:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.537us BEGIN check_match
    ->  4.542us BEGIN strcmp
    681400/681400 2065408.180100109:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100111:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.548us END   strcmp
    ->  4.548us BEGIN strcmp
    681400/681400 2065408.180100112:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->   4.55us END   strcmp
    681400/681400 2065408.180100114:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.551us END   check_match
    681400/681400 2065408.180100115:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.553us END   do_lookup_x
    681400/681400 2065408.180100118:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.554us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100128:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.557us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100139:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.567us BEGIN do_lookup_x
    681400/681400 2065408.180100139:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180100252:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.578us END   do_lookup_x
    ->  4.578us BEGIN do_lookup_x
    681400/681400 2065408.180100262:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    ->  4.691us BEGIN check_match
    681400/681400 2065408.180100270:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.701us BEGIN strcmp
    681400/681400 2065408.180100271:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.709us END   strcmp
    681400/681400 2065408.180100273:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->   4.71us END   check_match
    681400/681400 2065408.180100276:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.712us END   do_lookup_x
    681400/681400 2065408.180100280:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.715us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100286:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.719us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100317:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.725us BEGIN do_lookup_x
    681400/681400 2065408.180100317:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100331:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.756us BEGIN check_match
    ->  4.763us BEGIN strcmp
    681400/681400 2065408.180100331:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100336:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->   4.77us END   strcmp
    ->   4.77us BEGIN strcmp
    681400/681400 2065408.180100337:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.775us END   strcmp
    681400/681400 2065408.180100339:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.776us END   check_match
    681400/681400 2065408.180100340:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.778us END   do_lookup_x
    681400/681400 2065408.180100342:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.779us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100365:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.781us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100375:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.804us BEGIN do_lookup_x
    681400/681400 2065408.180100375:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180100385:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.814us END   do_lookup_x
    ->  4.814us BEGIN do_lookup_x
    681400/681400 2065408.180100387:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.824us END   do_lookup_x
    681400/681400 2065408.180100389:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.826us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100399:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.828us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100417:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.838us BEGIN do_lookup_x
    681400/681400 2065408.180100417:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100428:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.856us BEGIN check_match
    ->  4.861us BEGIN strcmp
    681400/681400 2065408.180100429:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.867us END   strcmp
    681400/681400 2065408.180100429:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    681400/681400 2065408.180100429:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100435:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.868us END   check_match
    ->  4.868us BEGIN check_match
    ->  4.871us BEGIN strcmp
    681400/681400 2065408.180100435:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100437:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.874us END   strcmp
    ->  4.874us BEGIN strcmp
    681400/681400 2065408.180100438:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.876us END   strcmp
    681400/681400 2065408.180100440:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.877us END   check_match
    681400/681400 2065408.180100440:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    681400/681400 2065408.180100443:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.879us END   do_lookup_x
    ->  4.879us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100455:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.882us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100471:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.894us BEGIN do_lookup_x
    681400/681400 2065408.180100471:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100489:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->   4.91us BEGIN check_match
    ->  4.919us BEGIN strcmp
    681400/681400 2065408.180100489:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100494:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.928us END   strcmp
    ->  4.928us BEGIN strcmp
    681400/681400 2065408.180100495:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.933us END   strcmp
    681400/681400 2065408.180100496:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.934us END   check_match
    681400/681400 2065408.180100497:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.935us END   do_lookup_x
    681400/681400 2065408.180100500:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.936us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100513:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.939us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100519:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.952us BEGIN do_lookup_x
    681400/681400 2065408.180100532:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  4.958us BEGIN check_match
    681400/681400 2065408.180100542:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  4.971us BEGIN strcmp
    681400/681400 2065408.180100542:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100546:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  4.981us END   strcmp
    ->  4.981us BEGIN strcmp
    681400/681400 2065408.180100547:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  4.985us END   strcmp
    681400/681400 2065408.180100549:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  4.986us END   check_match
    681400/681400 2065408.180100550:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  4.988us END   do_lookup_x
    681400/681400 2065408.180100553:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  4.989us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100558:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  4.992us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180100566:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  4.997us BEGIN do_lookup_x
    681400/681400 2065408.180100566:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100581:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  5.005us BEGIN check_match
    ->  5.012us BEGIN strcmp
    681400/681400 2065408.180100581:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180100587:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->   5.02us END   strcmp
    ->   5.02us BEGIN strcmp
    681400/681400 2065408.180100588:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    ->  5.026us END   strcmp
    681400/681400 2065408.180100590:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  5.027us END   check_match
    681400/681400 2065408.180100591:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  5.029us END   do_lookup_x
    681400/681400 2065408.180100640:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63de530 sinf32x+0x0
    ->   5.03us END   _dl_lookup_symbol_x
    681400/681400 2065408.180100844:   hw int                   7faea63de530 sinf32x+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->  5.079us BEGIN sinf32x
    681400/681400 2065408.180102146:   tr strt                             0 [unknown] =>     7faea63de530 sinf32x+0x0
    ->  5.283us BEGIN asm_exc_page_fault
    681400/681400 2065408.180102176:   return                   7faea63de57e sinf32x+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    ->  6.585us END   asm_exc_page_fault
    681400/681400 2065408.180102186:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d58b0 __atan2_finite+0x0
    ->  6.615us END   sinf32x
    681400/681400 2065408.180102200:   return                   7faea63d58fe __atan2_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    ->  6.625us BEGIN __atan2_finite
    681400/681400 2065408.180102204:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63f65b0 exp2f+0x0
    ->  6.639us END   __atan2_finite
    681400/681400 2065408.180102387:   hw int                   7faea63f65b0 exp2f+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->  6.643us BEGIN exp2f
    681400/681400 2065408.180103581:   tr strt                             0 [unknown] =>     7faea63f65b0 exp2f+0x0
    ->  6.826us BEGIN asm_exc_page_fault
    681400/681400 2065408.180103606:   return                   7faea63f65dd exp2f+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->   8.02us END   asm_exc_page_fault
    681400/681400 2065408.180103610:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d4d20 __asin_finite+0x0
    681400/681400 2065408.180103617:   return                   7faea63d4d5d __asin_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  8.049us BEGIN __asin_finite
    681400/681400 2065408.180103621:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63e0dd0 fmaf32x+0x0
    ->  8.056us END   __asin_finite
    681400/681400 2065408.180103801:   hw int                   7faea63e0dd0 fmaf32x+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->   8.06us BEGIN fmaf32x
    681400/681400 2065408.180105022:   tr strt                             0 [unknown] =>     7faea63e0dd0 fmaf32x+0x0
    ->   8.24us BEGIN asm_exc_page_fault
    681400/681400 2065408.180105048:   return                   7faea63e0e04 fmaf32x+0x34 =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.461us END   asm_exc_page_fault
    681400/681400 2065408.180105051:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ef720 sinf+0x0
    ->  9.487us END   fmaf32x
    681400/681400 2065408.180105057:   return                   7faea63ef74d sinf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->   9.49us BEGIN sinf
    681400/681400 2065408.180105060:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d4d60 __acos_finite+0x0
    ->  9.496us END   sinf
    681400/681400 2065408.180105061:   return                   7faea63d4d9d __acos_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.499us BEGIN __acos_finite
    681400/681400 2065408.180105066:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d9340 __log_finite+0x0
    ->    9.5us END   __acos_finite
    681400/681400 2065408.180105077:   return                   7faea63d938e __log_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.505us BEGIN __log_finite
    681400/681400 2065408.180105079:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63efd90 __log2f_finite+0x0
    ->  9.516us END   __log_finite
    681400/681400 2065408.180105080:   return                   7faea63efdbd __log2f_finite+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.518us BEGIN __log2f_finite
    681400/681400 2065408.180105085:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d9c00 __pow_finite+0x0
    ->  9.519us END   __log2f_finite
    681400/681400 2065408.180105087:   return                   7faea63d9c3d __pow_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.524us BEGIN __pow_finite
    681400/681400 2065408.180105090:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ece50 powf+0x0
    ->  9.526us END   __pow_finite
    681400/681400 2065408.180105098:   return                   7faea63ece7d powf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.529us BEGIN powf
    681400/681400 2065408.180105101:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63efe60 sincosf32+0x0
    ->  9.537us END   powf
    681400/681400 2065408.180105102:   return                   7faea63efe8d sincosf32+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->   9.54us BEGIN sincosf32
    681400/681400 2065408.180105108:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ec960 logf+0x0
    ->  9.541us END   sincosf32
    681400/681400 2065408.180105109:   return                   7faea63ec98d logf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.547us BEGIN logf
    681400/681400 2065408.180105113:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63de580 cos+0x0
    ->  9.548us END   logf
    681400/681400 2065408.180105114:   return                   7faea63de5ce cos+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.552us BEGIN cos
    681400/681400 2065408.180105117:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63e8e10 expf+0x0
    ->  9.553us END   cos
    681400/681400 2065408.180105122:   return                   7faea63e8e3d expf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.556us BEGIN expf
    681400/681400 2065408.180105125:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d5dd0 __exp_finite+0x0
    ->  9.561us END   expf
    681400/681400 2065408.180105126:   return                   7faea63d5e1e __exp_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.564us BEGIN __exp_finite
    681400/681400 2065408.180105128:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ee210 cosf+0x0
    ->  9.565us END   __exp_finite
    681400/681400 2065408.180105135:   return                   7faea63ee23d cosf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  9.567us BEGIN cosf
    681400/681400 2065408.180105143:   call                     7faea66c8913 _dl_relocate_object+0x1033 =>     7faea66c77a0 _dl_protect_relro+0x0
    ->  9.574us END   cosf
    681400/681400 2065408.180105143:   call                     7faea66c77e0 _dl_protect_relro+0x40 =>     7faea66dbf40 mprotect+0x0
    681400/681400 2065408.180105162:   syscall                  7faea66dbf49 mprotect+0x9 => ffffffffae200000 __entry_text_start+0x0
    ->  9.582us BEGIN _dl_protect_relro
    ->  9.591us BEGIN mprotect
    681400/681400 2065408.180106350:   tr strt                             0 [unknown] =>     7faea66dbf4b mprotect+0xb
    ->  9.601us BEGIN __entry_text_start
    681400/681400 2065408.180106353:   return                   7faea66dbf53 mprotect+0x13 =>     7faea66c77e5 _dl_protect_relro+0x45
    -> 10.789us END   __entry_text_start
    681400/681400 2065408.180106363:   return                   7faea66c77d2 _dl_protect_relro+0x32 =>     7faea66c8918 _dl_relocate_object+0x1038
    681400/681400 2065408.180106366:   return                   7faea66c8926 _dl_relocate_object+0x1046 =>     7faea66c57de dl_open_worker_begin+0x2ce
    -> 10.802us END   _dl_protect_relro
    681400/681400 2065408.180106398:   call                     7faea66c58f3 dl_open_worker_begin+0x3e3 =>     7faea66bd430 _dl_find_object_update+0x0
    -> 10.805us END   _dl_relocate_object
    681400/681400 2065408.180106400:   call                     7faea66bd491 _dl_find_object_update+0x61 =>     7faea6536590 __libc_malloc+0x0
    -> 10.837us BEGIN _dl_find_object_update
    681400/681400 2065408.180106418:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66bd493 _dl_find_object_update+0x63
    -> 10.839us BEGIN __libc_malloc
    681400/681400 2065408.180106431:   call                     7faea66bd693 _dl_find_object_update+0x263 =>     7faea66bcc40 _dl_find_object_from_map+0x0
    -> 10.857us END   __libc_malloc
    681400/681400 2065408.180106435:   return                   7faea66bcc9c _dl_find_object_from_map+0x5c =>     7faea66bd698 _dl_find_object_update+0x268
    ->  10.87us BEGIN _dl_find_object_from_map
    681400/681400 2065408.180106442:   call                     7faea66bd7ad _dl_find_object_update+0x37d =>     7faea6536b70 __libc_free+0x0
    -> 10.874us END   _dl_find_object_from_map
    681400/681400 2065408.180106446:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    -> 10.881us BEGIN __libc_free
    681400/681400 2065408.180106462:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 10.885us BEGIN _int_free
    681400/681400 2065408.180106465:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bd7b3 _dl_find_object_update+0x383
    -> 10.901us END   _int_free
    681400/681400 2065408.180106466:   return                   7faea66bd6f4 _dl_find_object_update+0x2c4 =>     7faea66c58f8 dl_open_worker_begin+0x3e8
    -> 10.904us END   __libc_free
    681400/681400 2065408.180106476:   return                   7faea66c592b dl_open_worker_begin+0x41b =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 10.905us END   _dl_find_object_update
    681400/681400 2065408.180106490:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c4d7b dl_open_worker+0x3b
    -> 10.915us END   dl_open_worker_begin
    681400/681400 2065408.180106510:   call                     7faea66c4d80 dl_open_worker+0x40 =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 10.929us END   _dl_catch_exception
    681400/681400 2065408.180106510:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180106519:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c4d86 dl_open_worker+0x46
    -> 10.949us BEGIN __pthread_mutex_unlock
    -> 10.953us END   __pthread_mutex_unlock
    -> 10.953us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180106521:   call                     7faea66c4dd9 dl_open_worker+0x99 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 10.958us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180106523:   call                     7faea65f3e73 _dl_catch_exception+0xe3 =>     7faea66c4e40 call_dl_init+0x0
    ->  10.96us BEGIN _dl_catch_exception
    681400/681400 2065408.180106523:   jmp                      7faea66c4e52 call_dl_init+0x12 =>     7faea66bdf50 _dl_init+0x0
    681400/681400 2065408.180106534:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    -> 10.962us BEGIN call_dl_init
    -> 10.967us END   call_dl_init
    -> 10.967us BEGIN _dl_init
    681400/681400 2065408.180106538:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 10.973us BEGIN call_init
    681400/681400 2065408.180106538:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    681400/681400 2065408.180106543:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 10.977us END   call_init
    -> 10.977us BEGIN call_init
    681400/681400 2065408.180106543:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    681400/681400 2065408.180106558:   call                     7faea66bde97 call_init+0x77 =>     7faea63be000 _init+0x0
    -> 10.982us END   call_init
    -> 10.982us BEGIN call_init
    681400/681400 2065408.180106744:   hw int                   7faea63be000 _init+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 10.997us BEGIN _init
    681400/681400 2065408.180107893:   tr strt                             0 [unknown] => ffffffffad83be84 filemap_map_pages+0x3c4
    -> 11.183us BEGIN asm_exc_page_fault
    681400/681400 2065408.180108035:   tr strt                             0 [unknown] =>     7faea63be000 _init+0x0
    -> 12.332us END   asm_exc_page_fault
    681400/681400 2065408.180108061:   return                   7faea63be01a _init+0x1a =>     7faea66bde99 call_init+0x79
    -> 12.474us BEGIN _init
    681400/681400 2065408.180108075:   call                     7faea66bdedc call_init+0xbc =>     7faea63be520 frame_dummy+0x0
    ->   12.5us END   _init
    681400/681400 2065408.180108075:   jmp                      7faea63be524 frame_dummy+0x4 =>     7faea63be490 register_tm_clones+0x0
    681400/681400 2065408.180108076:   return                   7faea63be4c8 register_tm_clones+0x38 =>     7faea66bdede call_init+0xbe
    -> 12.514us BEGIN frame_dummy
    -> 12.514us END   frame_dummy
    -> 12.514us BEGIN register_tm_clones
    681400/681400 2065408.180108077:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 12.515us END   register_tm_clones
    681400/681400 2065408.180108083:   return                   7faea66bdfe0 _dl_init+0x90 =>     7faea65f3e75 _dl_catch_exception+0xe5
    -> 12.516us END   call_init
    681400/681400 2065408.180108089:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c4ddf dl_open_worker+0x9f
    -> 12.522us END   _dl_init
    681400/681400 2065408.180108094:   return                   7faea66c4da2 dl_open_worker+0x62 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 12.528us END   _dl_catch_exception
    681400/681400 2065408.180108109:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c515d _dl_open+0xad
    -> 12.533us END   dl_open_worker
    681400/681400 2065408.180108109:   call                     7faea66c5160 _dl_open+0xb0 =>     7faea66cda00 _dl_unload_cache+0x0
    681400/681400 2065408.180108117:   call                     7faea66cda2b _dl_unload_cache+0x2b =>     7faea66dbf10 __munmap+0x0
    -> 12.548us END   _dl_catch_exception
    -> 12.548us BEGIN _dl_unload_cache
    681400/681400 2065408.180108132:   syscall                  7faea66dbf19 __munmap+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 12.556us BEGIN __munmap
    681400/681400 2065408.180111518:   tr strt                             0 [unknown] =>     7faea66dbf1b __munmap+0xb
    -> 12.571us BEGIN __entry_text_start
    681400/681400 2065408.180111658:   return                   7faea66dbf23 __munmap+0x13 =>     7faea66cda30 _dl_unload_cache+0x30
    -> 15.957us END   __entry_text_start
    681400/681400 2065408.180111667:   return                   7faea66cda49 _dl_unload_cache+0x49 =>     7faea66c5165 _dl_open+0xb5
    681400/681400 2065408.180111674:   call                     7faea66c5192 _dl_open+0xe2 =>     7faea66bb0a0 _dl_debug_update+0x0
    -> 16.106us END   _dl_unload_cache
    681400/681400 2065408.180111685:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66c5197 _dl_open+0xe7
    -> 16.113us BEGIN _dl_debug_update
    681400/681400 2065408.180111685:   call                     7faea66c51a5 _dl_open+0xf5 =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180111685:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180111693:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c51ab _dl_open+0xfb
    -> 16.124us END   _dl_debug_update
    -> 16.124us BEGIN __pthread_mutex_unlock
    -> 16.128us END   __pthread_mutex_unlock
    -> 16.128us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180111695:   return                   7faea66c51c1 _dl_open+0x111 =>     7faea652274c dlopen_doit+0x5c
    -> 16.132us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180111715:   return                   7faea6522753 dlopen_doit+0x63 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 16.134us END   _dl_open
    681400/681400 2065408.180111740:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    -> 16.154us END   dlopen_doit
    681400/681400 2065408.180111749:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 16.179us END   _dl_catch_exception
    681400/681400 2065408.180111762:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea65227d8 dlopen+0x48
    -> 16.188us END   _dl_catch_error
    681400/681400 2065408.180111773:   return                   7faea65227f9 dlopen+0x69 =>     55cf38e4f1d2 main+0x39
    -> 16.201us END   _dlerror_run
    681400/681400 2065408.180111795:   call                     55cf38e4f20d main+0x74 =>     55cf38e4f030 _init+0x30
    -> 16.212us END   dlopen
    681400/681400 2065408.180111799:   jmp                      55cf38e4f030 _init+0x30 =>     7faea6521f90 dlerror+0x0
    -> 16.234us BEGIN _init
    681400/681400 2065408.180111808:   return                   7faea652207a dlerror+0xea =>     55cf38e4f212 main+0x79
    -> 16.238us END   _init
    -> 16.238us BEGIN dlerror
    681400/681400 2065408.180111808:   call                     55cf38e4f223 main+0x8a =>     55cf38e4f070 dlsym@plt+0x0
    681400/681400 2065408.180111809:   jmp                      55cf38e4f070 dlsym@plt+0x0 =>     7faea6522850 dlsym+0x0
    -> 16.247us END   dlerror
    -> 16.247us BEGIN dlsym@plt
    681400/681400 2065408.180111812:   call                     7faea65228a1 dlsym+0x51 =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 16.248us END   dlsym@plt
    -> 16.248us BEGIN dlsym
    681400/681400 2065408.180111821:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea65228a6 dlsym+0x56
    -> 16.251us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180111821:   call                     7faea65228b0 dlsym+0x60 =>     7faea65221c0 _dlerror_run+0x0
    681400/681400 2065408.180111826:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    ->  16.26us END   __pthread_mutex_lock
    ->  16.26us BEGIN _dlerror_run
    681400/681400 2065408.180111831:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 16.265us BEGIN _rtld_catch_error
    681400/681400 2065408.180111831:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180111836:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    ->  16.27us END   _rtld_catch_error
    ->  16.27us BEGIN _dl_catch_error
    -> 16.272us BEGIN _dl_catch_exception
    681400/681400 2065408.180111836:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180111844:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 16.275us BEGIN __sigsetjmp
    -> 16.279us END   __sigsetjmp
    -> 16.279us BEGIN __sigjmp_save
    681400/681400 2065408.180111844:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea6522830 dlsym_doit+0x0
    681400/681400 2065408.180111844:   call                     7faea6522843 dlsym_doit+0x13 =>     7faea65f4ac0 _dl_sym+0x0
    681400/681400 2065408.180111844:   jmp                      7faea65f4acc _dl_sym+0xc =>     7faea65f4670 do_sym+0x0
    681400/681400 2065408.180111849:   call                     7faea65f46d7 do_sym+0x67 =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 16.283us END   __sigjmp_save
    -> 16.283us BEGIN dlsym_doit
    -> 16.284us BEGIN _dl_sym
    -> 16.286us END   _dl_sym
    -> 16.286us BEGIN do_sym
    681400/681400 2065408.180111886:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 16.288us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180111912:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 16.325us BEGIN do_lookup_x
    681400/681400 2065408.180111912:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180111925:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 16.351us BEGIN check_match
    -> 16.357us BEGIN strcmp
    681400/681400 2065408.180111927:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 16.364us END   strcmp
    681400/681400 2065408.180111930:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 16.366us END   check_match
    681400/681400 2065408.180111931:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea65f46dd do_sym+0x6d
    -> 16.369us END   do_lookup_x
    681400/681400 2065408.180111932:   call                     7faea65f4890 do_sym+0x220 =>     7faea63de580 cos+0x0
    ->  16.37us END   _dl_lookup_symbol_x
    681400/681400 2065408.180111941:   return                   7faea63de5ce cos+0x4e =>     7faea65f4892 do_sym+0x222
    -> 16.371us BEGIN cos
    681400/681400 2065408.180111945:   return                   7faea65f4762 do_sym+0xf2 =>     7faea6522848 dlsym_doit+0x18
    ->  16.38us END   cos
    681400/681400 2065408.180111945:   return                   7faea652284d dlsym_doit+0x1d =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180111950:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    -> 16.384us END   do_sym
    -> 16.384us END   dlsym_doit
    681400/681400 2065408.180111962:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 16.389us END   _dl_catch_exception
    681400/681400 2065408.180111964:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea65228b5 dlsym+0x65
    -> 16.401us END   _dl_catch_error
    681400/681400 2065408.180111964:   call                     7faea65228c0 dlsym+0x70 =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180111964:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180111968:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea65228c5 dlsym+0x75
    -> 16.403us END   _dlerror_run
    -> 16.403us BEGIN __pthread_mutex_unlock
    -> 16.405us END   __pthread_mutex_unlock
    -> 16.405us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180111969:   return                   7faea65228df dlsym+0x8f =>     55cf38e4f228 main+0x8f
    -> 16.407us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180111969:   call                     55cf38e4f22c main+0x93 =>     55cf38e4f030 _init+0x30
    681400/681400 2065408.180111973:   jmp                      55cf38e4f030 _init+0x30 =>     7faea6521f90 dlerror+0x0
    -> 16.408us END   dlsym
    -> 16.408us BEGIN _init
    681400/681400 2065408.180111978:   return                   7faea652207a dlerror+0xea =>     55cf38e4f231 main+0x98
    -> 16.412us END   _init
    -> 16.412us BEGIN dlerror
    681400/681400 2065408.180111981:   call                     55cf38e4f278 main+0xdf =>     7faea6422040 __cos_fma+0x0
    -> 16.417us END   dlerror
    681400/681400 2065408.180112179:   hw int                   7faea6422040 __cos_fma+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->  16.42us BEGIN __cos_fma
    681400/681400 2065408.180113525:   tr strt                             0 [unknown] =>     7faea6422040 __cos_fma+0x0
    -> 16.618us BEGIN asm_exc_page_fault
    681400/681400 2065408.180113694:   hw int                   7faea6422193 __cos_fma+0x153 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 17.964us END   asm_exc_page_fault
    681400/681400 2065408.180115015:   tr strt                             0 [unknown] =>     7faea6422193 __cos_fma+0x153
    -> 18.133us BEGIN asm_exc_page_fault
    681400/681400 2065408.180115176:   hw int                   7faea64221a3 __cos_fma+0x163 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 19.454us END   asm_exc_page_fault
    681400/681400 2065408.180116633:   tr strt                             0 [unknown] =>     7faea64221a3 __cos_fma+0x163
    -> 19.615us BEGIN asm_exc_page_fault
    681400/681400 2065408.180116822:   hw int                   7faea642222f __cos_fma+0x1ef => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 21.072us END   asm_exc_page_fault
    681400/681400 2065408.180118607:   tr strt                             0 [unknown] =>     7faea642222f __cos_fma+0x1ef
    -> 21.261us BEGIN asm_exc_page_fault
    681400/681400 2065408.180118776:   hw int                   7faea6422238 __cos_fma+0x1f8 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 23.046us END   asm_exc_page_fault
    681400/681400 2065408.180119205:   tr strt                             0 [unknown] =>     7faea6422238 __cos_fma+0x1f8
    -> 23.215us BEGIN asm_exc_page_fault
    681400/681400 2065408.180119237:   return                   7faea6422173 __cos_fma+0x133 =>     55cf38e4f27a main+0xe1
    -> 23.644us END   asm_exc_page_fault
    681400/681400 2065408.180119237:   call                     55cf38e4f29a main+0x101 =>     55cf38e4f050 fprintf@plt+0x0
    681400/681400 2065408.180119238:   jmp                      55cf38e4f050 fprintf@plt+0x0 =>     7faea64f6700 fprintf+0x0
    -> 23.676us END   __cos_fma
    -> 23.676us BEGIN fprintf@plt
    681400/681400 2065408.180119239:   call                     7faea64f6795 fprintf+0x95 =>     7faea6509480 __vfprintf_internal+0x0
    -> 23.677us END   fprintf@plt
    -> 23.677us BEGIN fprintf
    681400/681400 2065408.180119247:   call                     7faea650951c __vfprintf_internal+0x9c =>     7faea6630240 __strchrnul_evex+0x0
    -> 23.678us BEGIN __vfprintf_internal
    681400/681400 2065408.180119256:   return                   7faea663028a __strchrnul_evex+0x4a =>     7faea6509522 __vfprintf_internal+0xa2
    -> 23.686us BEGIN __strchrnul_evex
    681400/681400 2065408.180119257:   call                     7faea6509917 __vfprintf_internal+0x497 =>     7faea6523230 __GI___libc_cleanup_push_defer+0x0
    -> 23.695us END   __strchrnul_evex
    681400/681400 2065408.180119277:   return                   7faea6523263 __GI___libc_cleanup_push_defer+0x33 =>     7faea650991c __vfprintf_internal+0x49c
    -> 23.696us BEGIN __GI___libc_cleanup_push_defer
    681400/681400 2065408.180119286:   call                     7faea650958b __vfprintf_internal+0x10b =>     7faea651e5d0 _IO_file_xsputn+0x0
    -> 23.716us END   __GI___libc_cleanup_push_defer
    681400/681400 2065408.180119288:   return                   7faea651e656 _IO_file_xsputn+0x86 =>     7faea650958e __vfprintf_internal+0x10e
    -> 23.725us BEGIN _IO_file_xsputn
    681400/681400 2065408.180119317:   call                     7faea650ad50 __vfprintf_internal+0x18d0 =>     7faea64f38f0 __printf_fp+0x0
    -> 23.727us END   _IO_file_xsputn
    681400/681400 2065408.180119317:   jmp                      7faea64f3908 __printf_fp+0x18 =>     7faea64f0db0 __GI___printf_fp_l+0x0
    681400/681400 2065408.180119363:   call                     7faea64f140a __GI___printf_fp_l+0x65a =>     7faea64ed020 __mpn_extract_double+0x0
    -> 23.756us BEGIN __printf_fp
    -> 23.779us END   __printf_fp
    -> 23.779us BEGIN __GI___printf_fp_l
    681400/681400 2065408.180119375:   return                   7faea64ed08d __mpn_extract_double+0x6d =>     7faea64f140f __GI___printf_fp_l+0x65f
    -> 23.802us BEGIN __mpn_extract_double
    681400/681400 2065408.180119388:   call                     7faea64f28a4 __GI___printf_fp_l+0x1af4 =>     7faea64ebb00 __mpn_lshift+0x0
    -> 23.814us END   __mpn_extract_double
    681400/681400 2065408.180119414:   return                   7faea64ebb5f __mpn_lshift+0x5f =>     7faea64f28a9 __GI___printf_fp_l+0x1af9
    -> 23.827us BEGIN __mpn_lshift
    681400/681400 2065408.180119431:   call                     7faea64f2f28 __GI___printf_fp_l+0x2178 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 23.853us END   __mpn_lshift
    681400/681400 2065408.180119446:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f2f2d __GI___printf_fp_l+0x217d
    ->  23.87us BEGIN __mpn_mul_1
    681400/681400 2065408.180119453:   call                     7faea64f34a1 __GI___printf_fp_l+0x26f1 =>     7faea64ebc20 __mpn_rshift+0x0
    -> 23.885us END   __mpn_mul_1
    681400/681400 2065408.180119458:   return                   7faea64ebcab __mpn_rshift+0x8b =>     7faea64f34a6 __GI___printf_fp_l+0x26f6
    -> 23.892us BEGIN __mpn_rshift
    681400/681400 2065408.180119472:   call                     7faea64f191e __GI___printf_fp_l+0xb6e =>     7faea6522a90 __libc_alloca_cutoff+0x0
    -> 23.897us END   __mpn_rshift
    681400/681400 2065408.180119476:   return                   7faea6522ad7 __libc_alloca_cutoff+0x47 =>     7faea64f1923 __GI___printf_fp_l+0xb73
    -> 23.911us BEGIN __libc_alloca_cutoff
    681400/681400 2065408.180119477:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    -> 23.915us END   __libc_alloca_cutoff
    681400/681400 2065408.180119490:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 23.916us BEGIN hack_digit
    681400/681400 2065408.180119496:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 23.929us BEGIN __mpn_mul_1
    681400/681400 2065408.180119499:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 23.935us END   __mpn_mul_1
    681400/681400 2065408.180119500:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    -> 23.938us END   hack_digit
    681400/681400 2065408.180119500:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180119506:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 23.939us BEGIN hack_digit
    -> 23.942us BEGIN __mpn_mul_1
    681400/681400 2065408.180119509:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 23.945us END   __mpn_mul_1
    681400/681400 2065408.180119510:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    -> 23.948us END   hack_digit
    681400/681400 2065408.180119510:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180119516:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 23.949us BEGIN hack_digit
    -> 23.952us BEGIN __mpn_mul_1
    681400/681400 2065408.180119517:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 23.955us END   __mpn_mul_1
    681400/681400 2065408.180119517:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180119517:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180119523:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 23.956us END   hack_digit
    -> 23.956us BEGIN hack_digit
    -> 23.959us BEGIN __mpn_mul_1
    681400/681400 2065408.180119524:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 23.962us END   __mpn_mul_1
    681400/681400 2065408.180119525:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    -> 23.963us END   hack_digit
    681400/681400 2065408.180119685:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 23.964us BEGIN hack_digit
    681400/681400 2065408.180119688:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 24.124us BEGIN __mpn_mul_1
    681400/681400 2065408.180119689:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 24.127us END   __mpn_mul_1
    681400/681400 2065408.180119689:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180119689:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180119695:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 24.128us END   hack_digit
    -> 24.128us BEGIN hack_digit
    -> 24.131us BEGIN __mpn_mul_1
    681400/681400 2065408.180119695:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    681400/681400 2065408.180119695:   call                     7faea64f1dcc __GI___printf_fp_l+0x101c =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180119700:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 24.134us END   __mpn_mul_1
    -> 24.134us END   hack_digit
    -> 24.134us BEGIN hack_digit
    681400/681400 2065408.180119705:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 24.139us BEGIN __mpn_mul_1
    681400/681400 2065408.180119706:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1dd1 __GI___printf_fp_l+0x1021
    -> 24.144us END   __mpn_mul_1
    681400/681400 2065408.180119755:   call                     7faea64f21fb __GI___printf_fp_l+0x144b =>     7faea64c52c0 [unknown]
    -> 24.145us END   hack_digit
    681400/681400 2065408.180119758:   jmp                      7faea64c52c4 [unknown] =>     7faea6630d60 __strlen_evex+0x0
    -> 24.194us BEGIN [unknown]
    681400/681400 2065408.180119773:   return                   7faea6630d8f __strlen_evex+0x2f =>     7faea64f2200 __GI___printf_fp_l+0x1450
    -> 24.197us END   [unknown]
    -> 24.197us BEGIN __strlen_evex
    681400/681400 2065408.180119894:   call                     7faea64f2325 __GI___printf_fp_l+0x1575 =>     7faea662da40 __mempcpy_evex_unaligned_erms+0x0
    -> 24.212us END   __strlen_evex
    681400/681400 2065408.180119894:   jmp                      7faea662da4a __mempcpy_evex_unaligned_erms+0xa =>     7faea662da87 __memmove_evex_unaligned_erms+0x7
    681400/681400 2065408.180119910:   return                   7faea662dae5 __memmove_evex_unaligned_erms+0x65 =>     7faea64f232b __GI___printf_fp_l+0x157b
    -> 24.333us BEGIN __mempcpy_evex_unaligned_erms
    -> 24.341us END   __mempcpy_evex_unaligned_erms
    -> 24.341us BEGIN __memmove_evex_unaligned_erms
    681400/681400 2065408.180119959:   return                   7faea64f1349 __GI___printf_fp_l+0x599 =>     7faea650ad55 __vfprintf_internal+0x18d5
    -> 24.349us END   __memmove_evex_unaligned_erms
    681400/681400 2065408.180119975:   call                     7faea6509af9 __vfprintf_internal+0x679 =>     7faea6630240 __strchrnul_evex+0x0
    -> 24.398us END   __GI___printf_fp_l
    681400/681400 2065408.180119980:   return                   7faea663028a __strchrnul_evex+0x4a =>     7faea6509aff __vfprintf_internal+0x67f
    -> 24.414us BEGIN __strchrnul_evex
    681400/681400 2065408.180119981:   call                     7faea6509b35 __vfprintf_internal+0x6b5 =>     7faea651e5d0 _IO_file_xsputn+0x0
    -> 24.419us END   __strchrnul_evex
    681400/681400 2065408.180119982:   call                     7faea651e62a _IO_file_xsputn+0x5a =>     7faea662da40 __mempcpy_evex_unaligned_erms+0x0
    ->  24.42us BEGIN _IO_file_xsputn
    681400/681400 2065408.180119982:   jmp                      7faea662da4a __mempcpy_evex_unaligned_erms+0xa =>     7faea662da87 __memmove_evex_unaligned_erms+0x7
    681400/681400 2065408.180119984:   return                   7faea662dae5 __memmove_evex_unaligned_erms+0x65 =>     7faea651e630 _IO_file_xsputn+0x60
    -> 24.421us BEGIN __mempcpy_evex_unaligned_erms
    -> 24.422us END   __mempcpy_evex_unaligned_erms
    -> 24.422us BEGIN __memmove_evex_unaligned_erms
    681400/681400 2065408.180119987:   return                   7faea651e656 _IO_file_xsputn+0x86 =>     7faea6509b39 __vfprintf_internal+0x6b9
    -> 24.423us END   __memmove_evex_unaligned_erms
    681400/681400 2065408.180119991:   call                     7faea6509978 __vfprintf_internal+0x4f8 =>     7faea6523270 __GI___libc_cleanup_pop_restore+0x0
    -> 24.426us END   _IO_file_xsputn
    681400/681400 2065408.180120003:   return                   7faea6523291 __GI___libc_cleanup_pop_restore+0x21 =>     7faea650997d __vfprintf_internal+0x4fd
    ->  24.43us BEGIN __GI___libc_cleanup_pop_restore
    681400/681400 2065408.180120004:   return                   7faea65096dd __vfprintf_internal+0x25d =>     7faea64f679a fprintf+0x9a
    -> 24.442us END   __GI___libc_cleanup_pop_restore
    681400/681400 2065408.180120005:   return                   7faea64f67b1 fprintf+0xb1 =>     55cf38e4f29f main+0x106
    -> 24.443us END   __vfprintf_internal
    681400/681400 2065408.180120005:   call                     55cf38e4f2a6 main+0x10d =>     55cf38e4f090 dlclose@plt+0x0
    681400/681400 2065408.180120007:   jmp                      55cf38e4f090 dlclose@plt+0x0 =>     7faea6521f40 dlclose+0x0
    -> 24.444us END   fprintf
    -> 24.444us BEGIN dlclose@plt
    681400/681400 2065408.180120016:   call                     7faea6521f63 dlclose+0x23 =>     7faea65221c0 _dlerror_run+0x0
    -> 24.446us END   dlclose@plt
    -> 24.446us BEGIN dlclose
    681400/681400 2065408.180120019:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    -> 24.455us BEGIN _dlerror_run
    681400/681400 2065408.180120020:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 24.458us BEGIN _rtld_catch_error
    681400/681400 2065408.180120020:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180120027:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 24.459us END   _rtld_catch_error
    -> 24.459us BEGIN _dl_catch_error
    -> 24.462us BEGIN _dl_catch_exception
    681400/681400 2065408.180120027:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180120033:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 24.466us BEGIN __sigsetjmp
    -> 24.469us END   __sigsetjmp
    -> 24.469us BEGIN __sigjmp_save
    681400/681400 2065408.180120033:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb020 _dl_close+0x0
    681400/681400 2065408.180120034:   call                     7faea66bb038 _dl_close+0x18 =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 24.472us END   __sigjmp_save
    -> 24.472us BEGIN _dl_close
    681400/681400 2065408.180120044:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66bb03e _dl_close+0x1e
    -> 24.473us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180120044:   call                     7faea66bb056 _dl_close+0x36 =>     7faea66ba240 _dl_close_worker+0x0
    681400/681400 2065408.180120111:   call                     7faea66ba567 _dl_close_worker+0x327 =>     7faea66ca220 _dl_sort_maps+0x0
    -> 24.483us END   __pthread_mutex_lock
    -> 24.483us BEGIN _dl_close_worker
    681400/681400 2065408.180120115:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    ->  24.55us BEGIN _dl_sort_maps
    -> 24.554us BEGIN dfs_traversal.part.0
    -> 24.564us BEGIN dfs_traversal.part.0
    ->  24.57us BEGIN dfs_traversal.part.0
    -> 24.575us END   dfs_traversal.part.0
    681400/681400 2065408.180120139:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 24.576us END   dfs_traversal.part.0
    681400/681400 2065408.180120141:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    -> 24.578us END   dfs_traversal.part.0
    681400/681400 2065408.180120143:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    ->  24.58us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180120143:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    681400/681400 2065408.180120151:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 24.582us END   dfs_traversal.part.0
    -> 24.582us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180120151:   call                     7faea66ca674 _dl_sort_maps+0x454 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180120156:   return                   7faea66e025c memcpy+0x8c =>     7faea66ca67a _dl_sort_maps+0x45a
    ->  24.59us END   dfs_traversal.part.0
    ->  24.59us BEGIN memcpy
    681400/681400 2065408.180120157:   return                   7faea66ca36e _dl_sort_maps+0x14e =>     7faea66ba56c _dl_close_worker+0x32c
    -> 24.595us END   memcpy
    681400/681400 2065408.180120170:   call                     7faea66ba5e1 _dl_close_worker+0x3a1 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 24.596us END   _dl_sort_maps
    681400/681400 2065408.180120177:   call                     7faea65f3e73 _dl_catch_exception+0xe3 =>     7faea66ba090 call_destructors+0x0
    -> 24.609us BEGIN _dl_catch_exception
    681400/681400 2065408.180120193:   call                     7faea66ba0d0 call_destructors+0x40 =>     7faea63be4d0 __do_global_dtors_aux+0x0
    -> 24.616us BEGIN call_destructors
    681400/681400 2065408.180120194:   call                     7faea63be4f2 __do_global_dtors_aux+0x22 =>     7faea64de040 __cxa_finalize+0x0
    -> 24.632us BEGIN __do_global_dtors_aux
    681400/681400 2065408.180120209:   call                     7faea64de194 __cxa_finalize+0x154 =>     7faea6576e60 __unregister_atfork+0x0
    -> 24.633us BEGIN __cxa_finalize
    681400/681400 2065408.180120228:   return                   7faea6576f59 __unregister_atfork+0xf9 =>     7faea64de199 __cxa_finalize+0x159
    -> 24.648us BEGIN __unregister_atfork
    681400/681400 2065408.180120233:   return                   7faea64de1b1 __cxa_finalize+0x171 =>     7faea63be4f8 __do_global_dtors_aux+0x28
    -> 24.667us END   __unregister_atfork
    681400/681400 2065408.180120233:   call                     7faea63be4f8 __do_global_dtors_aux+0x28 =>     7faea63be460 deregister_tm_clones+0x0
    681400/681400 2065408.180120234:   return                   7faea63be488 deregister_tm_clones+0x28 =>     7faea63be4fd __do_global_dtors_aux+0x2d
    -> 24.672us END   __cxa_finalize
    -> 24.672us BEGIN deregister_tm_clones
    681400/681400 2065408.180120238:   return                   7faea63be505 __do_global_dtors_aux+0x35 =>     7faea66ba0d2 call_destructors+0x42
    -> 24.673us END   deregister_tm_clones
    681400/681400 2065408.180120242:   jmp                      7faea66ba0f7 call_destructors+0x67 =>     7faea6437e18 _fini+0x0
    -> 24.677us END   __do_global_dtors_aux
    681400/681400 2065408.180120435:   hw int                   7faea6437e18 _fini+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 24.681us END   call_destructors
    -> 24.681us BEGIN _fini
    681400/681400 2065408.180121760:   tr strt                             0 [unknown] =>     7faea6437e18 _fini+0x0
    -> 24.874us BEGIN asm_exc_page_fault
    681400/681400 2065408.180121787:   return                   7faea6437e24 _fini+0xc =>     7faea65f3e75 _dl_catch_exception+0xe5
    -> 26.199us END   asm_exc_page_fault
    681400/681400 2065408.180121788:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66ba5e7 _dl_close_worker+0x3a7
    681400/681400 2065408.180121788:   call                     7faea66ba5ea _dl_close_worker+0x3aa =>     7faea66d0fa0 _dl_audit_objclose+0x0
    681400/681400 2065408.180121798:   return                   7faea66d0fae _dl_audit_objclose+0xe =>     7faea66ba5ef _dl_close_worker+0x3af
    -> 26.227us END   _dl_catch_exception
    -> 26.227us BEGIN _dl_audit_objclose
    681400/681400 2065408.180121803:   call                     7faea66ba956 _dl_close_worker+0x716 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    -> 26.237us END   _dl_audit_objclose
    681400/681400 2065408.180121805:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66ba95b _dl_close_worker+0x71b
    -> 26.242us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180121805:   call                     7faea66ba95e _dl_close_worker+0x71e =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180121810:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66ba963 _dl_close_worker+0x723
    -> 26.244us END   _dl_audit_activity_nsid
    -> 26.244us BEGIN _dl_debug_update
    681400/681400 2065408.180121810:   call                     7faea66ba971 _dl_close_worker+0x731 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180121811:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66ba976 _dl_close_worker+0x736
    -> 26.249us END   _dl_debug_update
    -> 26.249us BEGIN _dl_debug_state
    681400/681400 2065408.180121812:   call                     7faea66ba9c0 _dl_close_worker+0x780 =>     7faea65298a0 __pthread_mutex_lock+0x0
    ->  26.25us END   _dl_debug_state
    681400/681400 2065408.180121818:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66ba9c6 _dl_close_worker+0x786
    -> 26.251us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180121822:   call                     7faea66ba9cd _dl_close_worker+0x78d =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 26.257us END   __pthread_mutex_lock
    681400/681400 2065408.180121824:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66ba9d3 _dl_close_worker+0x793
    -> 26.261us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180121824:   call                     7faea66baa6f _dl_close_worker+0x82f =>     7faea66ce550 _dl_unmap+0x0
    681400/681400 2065408.180121824:   call                     7faea66ce56c _dl_unmap+0x1c =>     7faea66dbf10 __munmap+0x0
    681400/681400 2065408.180121845:   syscall                  7faea66dbf19 __munmap+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 26.263us END   __pthread_mutex_lock
    -> 26.263us BEGIN _dl_unmap
    -> 26.273us BEGIN __munmap
    681400/681400 2065408.180124357:   tr strt                             0 [unknown] => ffffffffad87b4f0 unmap_page_range+0x590
    -> 26.284us BEGIN __entry_text_start
    681400/681400 2065408.180130911:   tr strt                             0 [unknown] => ffffffffad67b158 flush_tlb_func+0xc8
    -> 28.796us END   __entry_text_start
    681400/681400 2065408.180133501:   tr strt                             0 [unknown] =>     7faea66dbf1b __munmap+0xb
    ->  35.35us BEGIN flush_tlb_func
    681400/681400 2065408.180133533:   return                   7faea66dbf23 __munmap+0x13 =>     7faea66ce571 _dl_unmap+0x21
    ->  37.94us END   flush_tlb_func
    681400/681400 2065408.180133556:   return                   7faea66ce5c4 _dl_unmap+0x74 =>     7faea66baa74 _dl_close_worker+0x834
    681400/681400 2065408.180133570:   call                     7faea66baa9a _dl_close_worker+0x85a =>     7faea66bd940 _dl_find_object_dlclose+0x0
    -> 37.995us END   _dl_unmap
    681400/681400 2065408.180133605:   return                   7faea66bd9bf _dl_find_object_dlclose+0x7f =>     7faea66baa9f _dl_close_worker+0x85f
    -> 38.009us BEGIN _dl_find_object_dlclose
    681400/681400 2065408.180133605:   call                     7faea66baaa6 _dl_close_worker+0x866 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180133639:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    -> 38.044us END   _dl_find_object_dlclose
    -> 38.044us BEGIN __libc_free
    681400/681400 2065408.180133675:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 38.078us BEGIN _int_free
    681400/681400 2065408.180133678:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baaac _dl_close_worker+0x86c
    -> 38.114us END   _int_free
    681400/681400 2065408.180133678:   call                     7faea66baab9 _dl_close_worker+0x879 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180133678:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180133687:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 38.117us END   __libc_free
    -> 38.117us BEGIN __libc_free
    -> 38.121us BEGIN _int_free
    681400/681400 2065408.180133688:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baabf _dl_close_worker+0x87f
    -> 38.126us END   _int_free
    681400/681400 2065408.180133688:   call                     7faea66baac6 _dl_close_worker+0x886 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180133689:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66baacc _dl_close_worker+0x88c
    -> 38.127us END   __libc_free
    -> 38.127us BEGIN __libc_free
    681400/681400 2065408.180133691:   call                     7faea66baadd _dl_close_worker+0x89d =>     7faea6536b70 __libc_free+0x0
    -> 38.128us END   __libc_free
    681400/681400 2065408.180133692:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    ->  38.13us BEGIN __libc_free
    681400/681400 2065408.180133703:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 38.131us BEGIN _int_free
    681400/681400 2065408.180133704:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baae3 _dl_close_worker+0x8a3
    -> 38.142us END   _int_free
    681400/681400 2065408.180133707:   call                     7faea66bab10 _dl_close_worker+0x8d0 =>     7faea6536b70 __libc_free+0x0
    -> 38.143us END   __libc_free
    681400/681400 2065408.180133707:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180133715:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 38.146us BEGIN __libc_free
    ->  38.15us BEGIN _int_free
    681400/681400 2065408.180133715:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bab16 _dl_close_worker+0x8d6
    681400/681400 2065408.180133717:   call                     7faea66bab53 _dl_close_worker+0x913 =>     7faea6536b70 __libc_free+0x0
    -> 38.154us END   _int_free
    -> 38.154us END   __libc_free
    681400/681400 2065408.180133719:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66bab59 _dl_close_worker+0x919
    -> 38.156us BEGIN __libc_free
    681400/681400 2065408.180133720:   call                     7faea66bab66 _dl_close_worker+0x926 =>     7faea6536b70 __libc_free+0x0
    -> 38.158us END   __libc_free
    681400/681400 2065408.180133724:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66bab6c _dl_close_worker+0x92c
    -> 38.159us BEGIN __libc_free
    681400/681400 2065408.180133725:   call                     7faea66bab7c _dl_close_worker+0x93c =>     7faea6536b70 __libc_free+0x0
    -> 38.163us END   __libc_free
    681400/681400 2065408.180133725:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180133747:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 38.164us BEGIN __libc_free
    -> 38.175us BEGIN _int_free
    681400/681400 2065408.180133748:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bab82 _dl_close_worker+0x942
    -> 38.186us END   _int_free
    681400/681400 2065408.180133762:   call                     7faea66bab9a _dl_close_worker+0x95a =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 38.187us END   __libc_free
    681400/681400 2065408.180133762:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180133769:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66baba0 _dl_close_worker+0x960
    -> 38.201us BEGIN __pthread_mutex_unlock
    -> 38.204us END   __pthread_mutex_unlock
    -> 38.204us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180133769:   call                     7faea66babdd _dl_close_worker+0x99d =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180133769:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180133777:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66babe3 _dl_close_worker+0x9a3
    -> 38.208us END   __pthread_mutex_unlock_usercnt
    -> 38.208us BEGIN __pthread_mutex_unlock
    -> 38.212us END   __pthread_mutex_unlock
    -> 38.212us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180133777:   call                     7faea66babe8 _dl_close_worker+0x9a8 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    681400/681400 2065408.180133795:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66babed _dl_close_worker+0x9ad
    -> 38.216us END   __pthread_mutex_unlock_usercnt
    -> 38.216us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180133796:   call                     7faea66bac06 _dl_close_worker+0x9c6 =>     7faea66bb090 _dl_debug_state+0x0
    -> 38.234us END   _dl_audit_activity_nsid
    681400/681400 2065408.180133803:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66bac0b _dl_close_worker+0x9cb
    -> 38.235us BEGIN _dl_debug_state
    681400/681400 2065408.180133827:   return                   7faea66ba486 _dl_close_worker+0x246 =>     7faea66bb05b _dl_close+0x3b
    -> 38.242us END   _dl_debug_state
    681400/681400 2065408.180133830:   jmp                      7faea66bb065 _dl_close+0x45 =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 38.266us END   _dl_close_worker
    681400/681400 2065408.180133830:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180133835:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 38.269us END   _dl_close
    -> 38.269us BEGIN __pthread_mutex_unlock
    -> 38.271us END   __pthread_mutex_unlock
    -> 38.271us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180133866:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    -> 38.274us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180133876:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 38.305us END   _dl_catch_exception
    681400/681400 2065408.180133908:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea6521f68 dlclose+0x28
    -> 38.315us END   _dl_catch_error
    681400/681400 2065408.180133930:   return                   7faea6521f70 dlclose+0x30 =>     55cf38e4f2ab main+0x112
    -> 38.347us END   _dlerror_run
    681400/681400 2065408.180133930:   call                     55cf38e4f1cd main+0x34 =>     55cf38e4f040 dlopen@plt+0x0
    681400/681400 2065408.180133973:   jmp                      55cf38e4f040 dlopen@plt+0x0 =>     7faea6522790 dlopen+0x0
    -> 38.369us END   dlclose
    -> 38.369us BEGIN dlopen@plt
    681400/681400 2065408.180133974:   call                     7faea65227d3 dlopen+0x43 =>     7faea65221c0 _dlerror_run+0x0
    -> 38.412us END   dlopen@plt
    -> 38.412us BEGIN dlopen
    681400/681400 2065408.180133976:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    -> 38.413us BEGIN _dlerror_run
    681400/681400 2065408.180133990:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 38.415us BEGIN _rtld_catch_error
    681400/681400 2065408.180133990:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180133992:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 38.429us END   _rtld_catch_error
    -> 38.429us BEGIN _dl_catch_error
    ->  38.43us BEGIN _dl_catch_exception
    681400/681400 2065408.180134002:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    -> 38.431us BEGIN __sigsetjmp
    681400/681400 2065408.180134002:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    681400/681400 2065408.180134003:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea65226f0 dlopen_doit+0x0
    -> 38.441us END   __sigsetjmp
    -> 38.441us BEGIN __sigjmp_save
    -> 38.442us END   __sigjmp_save
    681400/681400 2065408.180134012:   call                     7faea652274a dlopen_doit+0x5a =>     7faea66c50b0 _dl_open+0x0
    -> 38.442us BEGIN dlopen_doit
    681400/681400 2065408.180134017:   call                     7faea66c50ec _dl_open+0x3c =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 38.451us BEGIN _dl_open
    681400/681400 2065408.180134029:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c50f2 _dl_open+0x42
    -> 38.456us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180134030:   call                     7faea66c5157 _dl_open+0xa7 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 38.468us END   __pthread_mutex_lock
    681400/681400 2065408.180134043:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 38.469us BEGIN _dl_catch_exception
    681400/681400 2065408.180134043:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180134044:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 38.482us BEGIN __sigsetjmp
    -> 38.482us END   __sigsetjmp
    -> 38.482us BEGIN __sigjmp_save
    681400/681400 2065408.180134045:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66c4d40 dl_open_worker+0x0
    -> 38.483us END   __sigjmp_save
    681400/681400 2065408.180134046:   call                     7faea66c4d5f dl_open_worker+0x1f =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 38.484us BEGIN dl_open_worker
    681400/681400 2065408.180134049:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c4d65 dl_open_worker+0x25
    -> 38.485us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180134049:   call                     7faea66c4d75 dl_open_worker+0x35 =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180134052:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 38.488us END   __pthread_mutex_lock
    -> 38.488us BEGIN _dl_catch_exception
    681400/681400 2065408.180134052:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180134056:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 38.491us BEGIN __sigsetjmp
    -> 38.493us END   __sigsetjmp
    -> 38.493us BEGIN __sigjmp_save
    681400/681400 2065408.180134056:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66c5510 dl_open_worker_begin+0x0
    681400/681400 2065408.180134056:   call                     7faea66c5534 dl_open_worker_begin+0x24 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180134255:   return                   7faea66dfa8a strchr+0x5a =>     7faea66c5539 dl_open_worker_begin+0x29
    -> 38.495us END   __sigjmp_save
    -> 38.495us BEGIN dl_open_worker_begin
    -> 38.594us BEGIN strchr
    681400/681400 2065408.180134261:   call                     7faea66c554d dl_open_worker_begin+0x3d =>     7faea66c4fe0 _dl_find_dso_for_object+0x0
    -> 38.694us END   strchr
    681400/681400 2065408.180134273:   return                   7faea66c5084 _dl_find_dso_for_object+0xa4 =>     7faea66c5552 dl_open_worker_begin+0x42
    ->   38.7us BEGIN _dl_find_dso_for_object
    681400/681400 2065408.180134273:   call                     7faea66c5594 dl_open_worker_begin+0x84 =>     7faea66bb0f0 _dl_debug_initialize+0x0
    681400/681400 2065408.180134276:   return                   7faea66bb159 _dl_debug_initialize+0x69 =>     7faea66c5599 dl_open_worker_begin+0x89
    -> 38.712us END   _dl_find_dso_for_object
    -> 38.712us BEGIN _dl_debug_initialize
    681400/681400 2065408.180134276:   call                     7faea66c55b4 dl_open_worker_begin+0xa4 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180134287:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 38.715us END   _dl_debug_initialize
    -> 38.715us BEGIN _dl_map_object
    681400/681400 2065408.180134287:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134304:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 38.726us BEGIN _dl_name_match_p
    -> 38.734us BEGIN strcmp
    681400/681400 2065408.180134304:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134313:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 38.743us END   strcmp
    -> 38.743us BEGIN strcmp
    681400/681400 2065408.180134314:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 38.752us END   strcmp
    681400/681400 2065408.180134314:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180134314:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134335:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 38.753us END   _dl_name_match_p
    -> 38.753us BEGIN _dl_name_match_p
    -> 38.763us BEGIN strcmp
    681400/681400 2065408.180134335:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134338:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 38.774us END   strcmp
    -> 38.774us BEGIN strcmp
    681400/681400 2065408.180134339:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 38.777us END   strcmp
    681400/681400 2065408.180134339:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134343:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 38.778us END   _dl_name_match_p
    -> 38.778us BEGIN strcmp
    681400/681400 2065408.180134343:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180134343:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134352:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 38.782us END   strcmp
    -> 38.782us BEGIN _dl_name_match_p
    -> 38.786us BEGIN strcmp
    681400/681400 2065408.180134352:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134356:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 38.791us END   strcmp
    -> 38.791us BEGIN strcmp
    681400/681400 2065408.180134357:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 38.795us END   strcmp
    681400/681400 2065408.180134357:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134379:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 38.796us END   _dl_name_match_p
    -> 38.796us BEGIN strcmp
    681400/681400 2065408.180134379:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180134379:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134381:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 38.818us END   strcmp
    -> 38.818us BEGIN _dl_name_match_p
    -> 38.819us BEGIN strcmp
    681400/681400 2065408.180134381:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134383:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  38.82us END   strcmp
    ->  38.82us BEGIN strcmp
    681400/681400 2065408.180134383:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134385:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 38.822us END   strcmp
    -> 38.822us BEGIN strcmp
    681400/681400 2065408.180134386:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 38.824us END   strcmp
    681400/681400 2065408.180134386:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180134389:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 38.825us END   _dl_name_match_p
    -> 38.825us BEGIN strcmp
    681400/681400 2065408.180134389:   call                     7faea66c1713 _dl_map_object+0x163 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180134391:   return                   7faea66dfa8a strchr+0x5a =>     7faea66c1718 _dl_map_object+0x168
    -> 38.828us END   strcmp
    -> 38.828us BEGIN strchr
    681400/681400 2065408.180134391:   call                     7faea66c17eb _dl_map_object+0x23b =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180134393:   return                   7faea66dfc9d strlen+0x3d =>     7faea66c17f0 _dl_map_object+0x240
    ->  38.83us END   strchr
    ->  38.83us BEGIN strlen
    681400/681400 2065408.180134393:   call                     7faea66c1a3b _dl_map_object+0x48b =>     7faea66bf9c0 cache_rpath+0x0
    681400/681400 2065408.180134427:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1a40 _dl_map_object+0x490
    -> 38.832us END   strlen
    -> 38.832us BEGIN cache_rpath
    681400/681400 2065408.180134428:   call                     7faea66c1b44 _dl_map_object+0x594 =>     7faea66bf9c0 cache_rpath+0x0
    -> 38.866us END   cache_rpath
    681400/681400 2065408.180134438:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1b49 _dl_map_object+0x599
    -> 38.867us BEGIN cache_rpath
    681400/681400 2065408.180134439:   call                     7faea66c188b _dl_map_object+0x2db =>     7faea66bf9c0 cache_rpath+0x0
    -> 38.877us END   cache_rpath
    681400/681400 2065408.180134453:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1890 _dl_map_object+0x2e0
    -> 38.878us BEGIN cache_rpath
    681400/681400 2065408.180134453:   call                     7faea66c18c0 _dl_map_object+0x310 =>     7faea66cd670 _dl_load_cache_lookup+0x0
    681400/681400 2065408.180134465:   call                     7faea66cd7df _dl_load_cache_lookup+0x16f =>     7faea66c4450 _dl_sysdep_read_whole_file+0x0
    -> 38.892us END   cache_rpath
    -> 38.892us BEGIN _dl_load_cache_lookup
    681400/681400 2065408.180134465:   call                     7faea66c4475 _dl_sysdep_read_whole_file+0x25 =>     7faea66dbd00 __open64_nocancel+0x0
    681400/681400 2065408.180134481:   syscall                  7faea66dbd36 __open64_nocancel+0x36 => ffffffffae200000 __entry_text_start+0x0
    -> 38.904us BEGIN _dl_sysdep_read_whole_file
    -> 38.912us BEGIN __open64_nocancel
    681400/681400 2065408.180136047:   tr strt                             0 [unknown] =>     7faea66dbd38 __open64_nocancel+0x38
    ->  38.92us BEGIN __entry_text_start
    681400/681400 2065408.180136053:   return                   7faea66dbd40 __open64_nocancel+0x40 =>     7faea66c447a _dl_sysdep_read_whole_file+0x2a
    -> 40.486us END   __entry_text_start
    681400/681400 2065408.180136053:   call                     7faea66c4497 _dl_sysdep_read_whole_file+0x47 =>     7faea66dbaa0 __fstat+0x0
    681400/681400 2065408.180136053:   jmp                      7faea66dbab7 __fstat+0x17 =>     7faea66dbaf0 __GI___fstatat64+0x0
    681400/681400 2065408.180136066:   syscall                  7faea66dbafc __GI___fstatat64+0xc => ffffffffae200000 __entry_text_start+0x0
    -> 40.492us BEGIN __fstat
    -> 40.498us END   __fstat
    -> 40.498us BEGIN __GI___fstatat64
    681400/681400 2065408.180136955:   tr strt                             0 [unknown] =>     7faea66dbafe __GI___fstatat64+0xe
    -> 40.505us BEGIN __entry_text_start
    681400/681400 2065408.180136955:   return                   7faea66dbb07 __GI___fstatat64+0x17 =>     7faea66c449c _dl_sysdep_read_whole_file+0x4c
    681400/681400 2065408.180136957:   call                     7faea66c44d0 _dl_sysdep_read_whole_file+0x80 =>     7faea66dbec0 mmap64+0x0
    -> 41.394us END   __entry_text_start
    681400/681400 2065408.180136972:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    -> 41.396us BEGIN mmap64
    681400/681400 2065408.180138280:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 41.411us BEGIN __entry_text_start
    681400/681400 2065408.180138286:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c44d5 _dl_sysdep_read_whole_file+0x85
    -> 42.719us END   __entry_text_start
    681400/681400 2065408.180138286:   call                     7faea66c44b6 _dl_sysdep_read_whole_file+0x66 =>     7faea66dbbf0 __GI___close_nocancel+0x0
    681400/681400 2065408.180138301:   syscall                  7faea66dbbf9 __GI___close_nocancel+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 42.725us BEGIN __GI___close_nocancel
    681400/681400 2065408.180138562:   tr strt                             0 [unknown] => ffffffffad7706cf __audit_syscall_exit+0x13f
    ->  42.74us BEGIN __entry_text_start
    681400/681400 2065408.180138603:   tr strt                             0 [unknown] =>     7faea66dbbfb __GI___close_nocancel+0xb
    -> 43.001us END   __entry_text_start
    681400/681400 2065408.180138605:   return                   7faea66dbc03 __GI___close_nocancel+0x13 =>     7faea66c44bb _dl_sysdep_read_whole_file+0x6b
    -> 43.042us BEGIN __GI___close_nocancel
    681400/681400 2065408.180138609:   return                   7faea66c448e _dl_sysdep_read_whole_file+0x3e =>     7faea66cd7e4 _dl_load_cache_lookup+0x174
    -> 43.044us END   __GI___close_nocancel
    681400/681400 2065408.180138762:   hw int                   7faea66cd808 _dl_load_cache_lookup+0x198 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 43.048us END   _dl_sysdep_read_whole_file
    681400/681400 2065408.180140358:   tr strt                             0 [unknown] =>     7faea66cd808 _dl_load_cache_lookup+0x198
    -> 43.201us BEGIN asm_exc_page_fault
    681400/681400 2065408.180140379:   call                     7faea66cd6d1 _dl_load_cache_lookup+0x61 =>     7faea66ccf90 search_cache+0x0
    -> 44.797us END   asm_exc_page_fault
    681400/681400 2065408.180140395:   call                     7faea66ccfd2 search_cache+0x42 =>     7faea66dc440 strcmp+0x0
    -> 44.818us BEGIN search_cache
    681400/681400 2065408.180140406:   return                   7faea66dd86e strcmp+0x142e =>     7faea66ccfd7 search_cache+0x47
    -> 44.834us BEGIN strcmp
    681400/681400 2065408.180140407:   call                     7faea66cd029 search_cache+0x99 =>     7faea66ce230 __tunable_get_val+0x0
    -> 44.845us END   strcmp
    681400/681400 2065408.180140412:   return                   7faea66ce290 __tunable_get_val+0x60 =>     7faea66cd02e search_cache+0x9e
    -> 44.846us BEGIN __tunable_get_val
    681400/681400 2065408.180140418:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    -> 44.851us END   __tunable_get_val
    681400/681400 2065408.180140436:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.857us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140436:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140457:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.875us END   _dl_cache_libcmp
    -> 44.875us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140457:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140475:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.896us END   _dl_cache_libcmp
    -> 44.896us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140475:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140482:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.914us END   _dl_cache_libcmp
    -> 44.914us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140482:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140488:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.921us END   _dl_cache_libcmp
    -> 44.921us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140488:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140505:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.927us END   _dl_cache_libcmp
    -> 44.927us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140505:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140512:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.944us END   _dl_cache_libcmp
    -> 44.944us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140512:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140525:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.951us END   _dl_cache_libcmp
    -> 44.951us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140525:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140534:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 44.964us END   _dl_cache_libcmp
    -> 44.964us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140534:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180140558:   return                   7faea66ccef5 _dl_cache_libcmp+0x45 =>     7faea66cd090 search_cache+0x100
    -> 44.973us END   _dl_cache_libcmp
    -> 44.973us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140560:   call                     7faea66cd106 search_cache+0x176 =>     7faea66cceb0 _dl_cache_libcmp+0x0
    -> 44.997us END   _dl_cache_libcmp
    681400/681400 2065408.180140579:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd10b search_cache+0x17b
    -> 44.999us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180140724:   return                   7faea66cd0bf search_cache+0x12f =>     7faea66cd6d6 _dl_load_cache_lookup+0x66
    -> 45.018us END   _dl_cache_libcmp
    681400/681400 2065408.180140725:   call                     7faea66cd6f2 _dl_load_cache_lookup+0x82 =>     7faea66dfc60 strlen+0x0
    -> 45.163us END   search_cache
    681400/681400 2065408.180140735:   return                   7faea66dfce6 strlen+0x86 =>     7faea66cd6f7 _dl_load_cache_lookup+0x87
    -> 45.164us BEGIN strlen
    681400/681400 2065408.180140736:   call                     7faea66cd74b _dl_load_cache_lookup+0xdb =>     7faea66e01d0 memcpy+0x0
    -> 45.174us END   strlen
    681400/681400 2065408.180140759:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66cd751 _dl_load_cache_lookup+0xe1
    -> 45.175us BEGIN memcpy
    681400/681400 2065408.180140759:   call                     7faea66cd754 _dl_load_cache_lookup+0xe4 =>     7faea66dc3e0 strdup+0x0
    681400/681400 2065408.180140759:   call                     7faea66dc3ee strdup+0xe =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180140773:   return                   7faea66dfce6 strlen+0x86 =>     7faea66dc3f3 strdup+0x13
    -> 45.198us END   memcpy
    -> 45.198us BEGIN strdup
    -> 45.205us BEGIN strlen
    681400/681400 2065408.180140773:   call                     7faea66dc3fa strdup+0x1a =>     7faea6536590 __libc_malloc+0x0
    681400/681400 2065408.180140803:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66dc400 strdup+0x20
    -> 45.212us END   strlen
    -> 45.212us BEGIN __libc_malloc
    681400/681400 2065408.180140803:   jmp                      7faea66dc415 strdup+0x35 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180140805:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66cd759 _dl_load_cache_lookup+0xe9
    -> 45.242us END   __libc_malloc
    -> 45.242us END   strdup
    -> 45.242us BEGIN memcpy
    681400/681400 2065408.180140806:   return                   7faea66cd75e _dl_load_cache_lookup+0xee =>     7faea66c18c5 _dl_map_object+0x315
    -> 45.244us END   memcpy
    681400/681400 2065408.180140806:   call                     7faea66c1905 _dl_map_object+0x355 =>     7faea66be290 open_verify.constprop.0+0x0
    681400/681400 2065408.180140806:   call                     7faea66be2c8 open_verify.constprop.0+0x38 =>     7faea66dbd00 __open64_nocancel+0x0
    681400/681400 2065408.180140830:   syscall                  7faea66dbd36 __open64_nocancel+0x36 => ffffffffae200000 __entry_text_start+0x0
    -> 45.245us END   _dl_load_cache_lookup
    -> 45.245us BEGIN open_verify.constprop.0
    -> 45.257us BEGIN __open64_nocancel
    681400/681400 2065408.180141859:   tr strt                             0 [unknown] =>     7faea66dbd38 __open64_nocancel+0x38
    -> 45.269us BEGIN __entry_text_start
    681400/681400 2065408.180141866:   return                   7faea66dbd40 __open64_nocancel+0x40 =>     7faea66be2cd open_verify.constprop.0+0x3d
    -> 46.298us END   __entry_text_start
    681400/681400 2065408.180141866:   call                     7faea66be30c open_verify.constprop.0+0x7c =>     7faea66dbd80 __GI___read_nocancel+0x0
    681400/681400 2065408.180141881:   syscall                  7faea66dbd86 __GI___read_nocancel+0x6 => ffffffffae200000 __entry_text_start+0x0
    -> 46.305us BEGIN __GI___read_nocancel
    681400/681400 2065408.180142877:   tr strt                             0 [unknown] =>     7faea66dbd88 __GI___read_nocancel+0x8
    ->  46.32us BEGIN __entry_text_start
    681400/681400 2065408.180142879:   return                   7faea66dbd90 __GI___read_nocancel+0x10 =>     7faea66be311 open_verify.constprop.0+0x81
    -> 47.316us END   __entry_text_start
    681400/681400 2065408.180142933:   call                     7faea66be3a5 open_verify.constprop.0+0x115 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180142947:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66be3ab open_verify.constprop.0+0x11b
    -> 47.372us BEGIN __libc_free
    681400/681400 2065408.180142948:   return                   7faea66be3bc open_verify.constprop.0+0x12c =>     7faea66c190a _dl_map_object+0x35a
    -> 47.386us END   __libc_free
    681400/681400 2065408.180142948:   call                     7faea66c17a7 _dl_map_object+0x1f7 =>     7faea66bfe20 _dl_map_object_from_fd+0x0
    681400/681400 2065408.180142948:   call                     7faea66bfe5d _dl_map_object_from_fd+0x3d =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180142967:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66bfe62 _dl_map_object_from_fd+0x42
    -> 47.387us END   open_verify.constprop.0
    -> 47.387us BEGIN _dl_map_object_from_fd
    -> 47.396us BEGIN _dl_debug_update
    681400/681400 2065408.180142968:   call                     7faea66c0335 _dl_map_object_from_fd+0x515 =>     7faea66dbaa0 __fstat+0x0
    -> 47.406us END   _dl_debug_update
    681400/681400 2065408.180142968:   jmp                      7faea66dbab7 __fstat+0x17 =>     7faea66dbaf0 __GI___fstatat64+0x0
    681400/681400 2065408.180142991:   syscall                  7faea66dbafc __GI___fstatat64+0xc => ffffffffae200000 __entry_text_start+0x0
    -> 47.407us BEGIN __fstat
    -> 47.418us END   __fstat
    -> 47.418us BEGIN __GI___fstatat64
    681400/681400 2065408.180143444:   tr strt                             0 [unknown] =>     7faea66dbafe __GI___fstatat64+0xe
    ->  47.43us BEGIN __entry_text_start
    681400/681400 2065408.180143445:   return                   7faea66dbb07 __GI___fstatat64+0x17 =>     7faea66c033a _dl_map_object_from_fd+0x51a
    -> 47.883us END   __entry_text_start
    681400/681400 2065408.180143481:   call                     7faea66bfece _dl_map_object_from_fd+0xae =>     7faea66c47b0 _dl_new_object+0x0
    681400/681400 2065408.180143481:   call                     7faea66c47f3 _dl_new_object+0x43 =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180143483:   return                   7faea66dfc9d strlen+0x3d =>     7faea66c47f8 _dl_new_object+0x48
    ->  47.92us BEGIN _dl_new_object
    -> 47.921us BEGIN strlen
    681400/681400 2065408.180143484:   call                     7faea66c481d _dl_new_object+0x6d =>     7faea65373b0 calloc+0x0
    -> 47.922us END   strlen
    681400/681400 2065408.180143501:   call                     7faea6537484 calloc+0xd4 =>     7faea6534f00 _int_malloc+0x0
    -> 47.923us BEGIN calloc
    681400/681400 2065408.180143777:   return                   7faea6535016 _int_malloc+0x116 =>     7faea6537489 calloc+0xd9
    ->  47.94us BEGIN _int_malloc
    681400/681400 2065408.180143808:   jmp                      7faea653768f calloc+0x2df =>     7faea662e680 __memset_evex_unaligned_erms+0x0
    -> 48.216us END   _int_malloc
    681400/681400 2065408.180143849:   return                   7faea662e77f __memset_evex_unaligned_erms+0xff =>     7faea66c4823 _dl_new_object+0x73
    -> 48.247us END   calloc
    -> 48.247us BEGIN __memset_evex_unaligned_erms
    681400/681400 2065408.180143853:   call                     7faea66c4860 _dl_new_object+0xb0 =>     7faea66e01d0 memcpy+0x0
    -> 48.288us END   __memset_evex_unaligned_erms
    681400/681400 2065408.180143869:   return                   7faea66e0240 memcpy+0x70 =>     7faea66c4866 _dl_new_object+0xb6
    -> 48.292us BEGIN memcpy
    681400/681400 2065408.180143891:   call                     7faea66c49a1 _dl_new_object+0x1f1 =>     7faea66dfc60 strlen+0x0
    -> 48.308us END   memcpy
    681400/681400 2065408.180143909:   return                   7faea66dfce6 strlen+0x86 =>     7faea66c49a6 _dl_new_object+0x1f6
    ->  48.33us BEGIN strlen
    681400/681400 2065408.180143910:   call                     7faea66c4b13 _dl_new_object+0x363 =>     7faea6536590 __libc_malloc+0x0
    -> 48.348us END   strlen
    681400/681400 2065408.180143924:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66c4b19 _dl_new_object+0x369
    -> 48.349us BEGIN __libc_malloc
    681400/681400 2065408.180143924:   call                     7faea66c4a42 _dl_new_object+0x292 =>     7faea66e01c0 __mempcpy+0x0
    681400/681400 2065408.180143924:   jmp                      7faea66e01ca __mempcpy+0xa =>     7faea66e01d7 memcpy+0x7
    681400/681400 2065408.180143927:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66c4a48 _dl_new_object+0x298
    -> 48.363us END   __libc_malloc
    -> 48.363us BEGIN __mempcpy
    -> 48.364us END   __mempcpy
    -> 48.364us BEGIN memcpy
    681400/681400 2065408.180143932:   return                   7faea66c4a7e _dl_new_object+0x2ce =>     7faea66bfed3 _dl_map_object_from_fd+0xb3
    -> 48.366us END   memcpy
    681400/681400 2065408.180143993:   call                     7faea66c016a _dl_map_object_from_fd+0x34a =>     7faea66dbec0 mmap64+0x0
    -> 48.371us END   _dl_new_object
    681400/681400 2065408.180144012:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    -> 48.432us BEGIN mmap64
    681400/681400 2065408.180144826:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 48.451us BEGIN __entry_text_start
    681400/681400 2065408.180144828:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c016f _dl_map_object_from_fd+0x34f
    -> 49.265us END   __entry_text_start
    681400/681400 2065408.180144841:   call                     7faea66c02f2 _dl_map_object_from_fd+0x4d2 =>     7faea66dbec0 mmap64+0x0
    681400/681400 2065408.180144859:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    ->  49.28us BEGIN mmap64
    681400/681400 2065408.180146886:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 49.298us BEGIN __entry_text_start
    681400/681400 2065408.180146889:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c02f7 _dl_map_object_from_fd+0x4d7
    -> 51.325us END   __entry_text_start
    681400/681400 2065408.180146891:   call                     7faea66c02f2 _dl_map_object_from_fd+0x4d2 =>     7faea66dbec0 mmap64+0x0
    681400/681400 2065408.180146910:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    ->  51.33us BEGIN mmap64
    681400/681400 2065408.180148038:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 51.349us BEGIN __entry_text_start
    681400/681400 2065408.180148044:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c02f7 _dl_map_object_from_fd+0x4d7
    -> 52.477us END   __entry_text_start
    681400/681400 2065408.180148045:   call                     7faea66c02f2 _dl_map_object_from_fd+0x4d2 =>     7faea66dbec0 mmap64+0x0
    681400/681400 2065408.180148063:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    -> 52.484us BEGIN mmap64
    681400/681400 2065408.180149281:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 52.502us BEGIN __entry_text_start
    681400/681400 2065408.180149286:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c02f7 _dl_map_object_from_fd+0x4d7
    ->  53.72us END   __entry_text_start
    681400/681400 2065408.180149286:   call                     7faea66c0288 _dl_map_object_from_fd+0x468 =>     7faea66e03c0 memset+0x0
    681400/681400 2065408.180149447:   hw int                   7faea66e03fa memset+0x3a => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 53.725us BEGIN memset
    681400/681400 2065408.180150528:   tr strt                             0 [unknown] =>     7faea66e03fa memset+0x3a
    -> 53.886us BEGIN asm_exc_page_fault
    681400/681400 2065408.180150558:   return                   7faea66e0457 memset+0x97 =>     7faea66c028e _dl_map_object_from_fd+0x46e
    -> 54.967us END   asm_exc_page_fault
    681400/681400 2065408.180150704:   hw int                   7faea66c07d8 _dl_map_object_from_fd+0x9b8 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 54.997us END   memset
    681400/681400 2065408.180151113:   tr strt                             0 [unknown] =>     7faea66c07d8 _dl_map_object_from_fd+0x9b8
    -> 55.143us BEGIN asm_exc_page_fault
    681400/681400 2065408.180151281:   hw int                   7faea66c088d _dl_map_object_from_fd+0xa6d => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 55.552us END   asm_exc_page_fault
    681400/681400 2065408.180152095:   tr strt                             0 [unknown] =>     7faea66c088d _dl_map_object_from_fd+0xa6d
    ->  55.72us BEGIN asm_exc_page_fault
    681400/681400 2065408.180152263:   hw int                   7faea66c0a6e _dl_map_object_from_fd+0xc4e => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 56.534us END   asm_exc_page_fault
    681400/681400 2065408.180152590:   tr strt                             0 [unknown] => ffffffffad880124 __handle_mm_fault+0x1d4
    -> 56.702us BEGIN asm_exc_page_fault
    681400/681400 2065408.180153793:   tr strt                             0 [unknown] =>     7faea66c0a6e _dl_map_object_from_fd+0xc4e
    -> 57.029us END   asm_exc_page_fault
    681400/681400 2065408.180153817:   call                     7faea66c0a5b _dl_map_object_from_fd+0xc3b =>     7faea66bfdb0 _dl_process_pt_gnu_property+0x0
    -> 58.232us BEGIN _dl_map_object_from_fd
    681400/681400 2065408.180153820:   return                   7faea66bfe16 _dl_process_pt_gnu_property+0x66 =>     7faea66c0a61 _dl_map_object_from_fd+0xc41
    -> 58.256us BEGIN _dl_process_pt_gnu_property
    681400/681400 2065408.180153832:   call                     7faea66c0bf6 _dl_map_object_from_fd+0xdd6 =>     7faea66dbbf0 __GI___close_nocancel+0x0
    -> 58.259us END   _dl_process_pt_gnu_property
    681400/681400 2065408.180153843:   syscall                  7faea66dbbf9 __GI___close_nocancel+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 58.271us BEGIN __GI___close_nocancel
    681400/681400 2065408.180153974:   tr strt                             0 [unknown] =>     7faea66dbbfb __GI___close_nocancel+0xb
    -> 58.282us BEGIN __entry_text_start
    681400/681400 2065408.180153975:   return                   7faea66dbc03 __GI___close_nocancel+0x13 =>     7faea66c0bfb _dl_map_object_from_fd+0xddb
    -> 58.413us END   __entry_text_start
    681400/681400 2065408.180153976:   call                     7faea66c0c34 _dl_map_object_from_fd+0xe14 =>     7faea66ca040 _dl_setup_hash+0x0
    681400/681400 2065408.180153993:   return                   7faea66ca0ad _dl_setup_hash+0x6d =>     7faea66c0c39 _dl_map_object_from_fd+0xe19
    -> 58.415us BEGIN _dl_setup_hash
    681400/681400 2065408.180153994:   call                     7faea66c0cd5 _dl_map_object_from_fd+0xeb5 =>     7faea66c4710 _dl_add_to_namespace_list+0x0
    -> 58.432us END   _dl_setup_hash
    681400/681400 2065408.180153995:   call                     7faea66c4728 _dl_add_to_namespace_list+0x18 =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 58.433us BEGIN _dl_add_to_namespace_list
    681400/681400 2065408.180154002:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c472e _dl_add_to_namespace_list+0x1e
    -> 58.434us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180154017:   jmp                      7faea66c4791 _dl_add_to_namespace_list+0x81 =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 58.441us END   __pthread_mutex_lock
    681400/681400 2065408.180154017:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180154110:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c0cda _dl_map_object_from_fd+0xeba
    -> 58.456us END   _dl_add_to_namespace_list
    -> 58.456us BEGIN __pthread_mutex_unlock
    -> 58.502us END   __pthread_mutex_unlock
    -> 58.502us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180154113:   call                     7faea66c0edf _dl_map_object_from_fd+0x10bf =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    -> 58.549us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180154122:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66c0ee4 _dl_map_object_from_fd+0x10c4
    -> 58.552us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180154122:   call                     7faea66c0d07 _dl_map_object_from_fd+0xee7 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180154126:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66c0d0c _dl_map_object_from_fd+0xeec
    -> 58.561us END   _dl_audit_activity_nsid
    -> 58.561us BEGIN _dl_debug_state
    681400/681400 2065408.180154130:   call                     7faea66c0d38 _dl_map_object_from_fd+0xf18 =>     7faea66d0ef0 _dl_audit_objopen+0x0
    -> 58.565us END   _dl_debug_state
    681400/681400 2065408.180154131:   return                   7faea66d0efe _dl_audit_objopen+0xe =>     7faea66c0d3d _dl_map_object_from_fd+0xf1d
    -> 58.569us BEGIN _dl_audit_objopen
    681400/681400 2065408.180154135:   return                   7faea66c03de _dl_map_object_from_fd+0x5be =>     7faea66c17ac _dl_map_object+0x1fc
    ->  58.57us END   _dl_audit_objopen
    681400/681400 2065408.180154151:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66c55b9 dl_open_worker_begin+0xa9
    -> 58.574us END   _dl_map_object_from_fd
    681400/681400 2065408.180154159:   call                     7faea66c561a dl_open_worker_begin+0x10a =>     7faea66bb2c0 _dl_map_object_deps+0x0
    ->  58.59us END   _dl_map_object
    681400/681400 2065408.180154204:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    -> 58.598us BEGIN _dl_map_object_deps
    681400/681400 2065408.180154204:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180154221:   return                   7faea66dfa8a strchr+0x5a =>     7faea66bf219 _dl_dst_count+0x19
    -> 58.643us BEGIN _dl_dst_count
    -> 58.651us BEGIN strchr
    681400/681400 2065408.180154221:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    681400/681400 2065408.180154223:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    ->  58.66us END   strchr
    ->  58.66us END   _dl_dst_count
    681400/681400 2065408.180154243:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 58.662us BEGIN _dl_catch_exception
    681400/681400 2065408.180154243:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180154247:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 58.682us BEGIN __sigsetjmp
    -> 58.684us END   __sigsetjmp
    -> 58.684us BEGIN __sigjmp_save
    681400/681400 2065408.180154247:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    681400/681400 2065408.180154247:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180154251:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 58.686us END   __sigjmp_save
    -> 58.686us BEGIN openaux
    -> 58.688us BEGIN _dl_map_object
    681400/681400 2065408.180154251:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154260:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  58.69us BEGIN _dl_name_match_p
    -> 58.694us BEGIN strcmp
    681400/681400 2065408.180154260:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154272:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.699us END   strcmp
    -> 58.699us BEGIN strcmp
    681400/681400 2065408.180154273:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.711us END   strcmp
    681400/681400 2065408.180154273:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154273:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154281:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.712us END   _dl_name_match_p
    -> 58.712us BEGIN _dl_name_match_p
    -> 58.716us BEGIN strcmp
    681400/681400 2065408.180154281:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154292:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  58.72us END   strcmp
    ->  58.72us BEGIN strcmp
    681400/681400 2065408.180154293:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.731us END   strcmp
    681400/681400 2065408.180154293:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154304:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 58.732us END   _dl_name_match_p
    -> 58.732us BEGIN strcmp
    681400/681400 2065408.180154304:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154304:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154311:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.743us END   strcmp
    -> 58.743us BEGIN _dl_name_match_p
    -> 58.746us BEGIN strcmp
    681400/681400 2065408.180154311:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154319:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  58.75us END   strcmp
    ->  58.75us BEGIN strcmp
    681400/681400 2065408.180154319:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180154320:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    -> 58.758us END   strcmp
    -> 58.758us END   _dl_name_match_p
    681400/681400 2065408.180154320:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180154321:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    -> 58.759us END   _dl_map_object
    -> 58.759us END   openaux
    681400/681400 2065408.180154321:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    681400/681400 2065408.180154321:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180154336:   return                   7faea66dfbb4 strchr+0x184 =>     7faea66bf219 _dl_dst_count+0x19
    ->  58.76us END   _dl_catch_exception
    ->  58.76us BEGIN _dl_dst_count
    -> 58.767us BEGIN strchr
    681400/681400 2065408.180154337:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    -> 58.775us END   strchr
    681400/681400 2065408.180154337:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180154342:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 58.776us END   _dl_dst_count
    -> 58.776us BEGIN _dl_catch_exception
    681400/681400 2065408.180154342:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180154347:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 58.781us BEGIN __sigsetjmp
    -> 58.783us END   __sigsetjmp
    -> 58.783us BEGIN __sigjmp_save
    681400/681400 2065408.180154347:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    681400/681400 2065408.180154347:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180154350:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 58.786us END   __sigjmp_save
    -> 58.786us BEGIN openaux
    -> 58.787us BEGIN _dl_map_object
    681400/681400 2065408.180154350:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154357:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.789us BEGIN _dl_name_match_p
    -> 58.792us BEGIN strcmp
    681400/681400 2065408.180154357:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154360:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.796us END   strcmp
    -> 58.796us BEGIN strcmp
    681400/681400 2065408.180154361:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.799us END   strcmp
    681400/681400 2065408.180154361:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154361:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154366:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->   58.8us END   _dl_name_match_p
    ->   58.8us BEGIN _dl_name_match_p
    -> 58.802us BEGIN strcmp
    681400/681400 2065408.180154366:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154370:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.805us END   strcmp
    -> 58.805us BEGIN strcmp
    681400/681400 2065408.180154371:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.809us END   strcmp
    681400/681400 2065408.180154371:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154378:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    ->  58.81us END   _dl_name_match_p
    ->  58.81us BEGIN strcmp
    681400/681400 2065408.180154378:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154378:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154383:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.817us END   strcmp
    -> 58.817us BEGIN _dl_name_match_p
    -> 58.819us BEGIN strcmp
    681400/681400 2065408.180154383:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154386:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.822us END   strcmp
    -> 58.822us BEGIN strcmp
    681400/681400 2065408.180154387:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.825us END   strcmp
    681400/681400 2065408.180154387:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154400:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 58.826us END   _dl_name_match_p
    -> 58.826us BEGIN strcmp
    681400/681400 2065408.180154400:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154400:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154403:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.839us END   strcmp
    -> 58.839us BEGIN _dl_name_match_p
    ->  58.84us BEGIN strcmp
    681400/681400 2065408.180154403:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154404:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.842us END   strcmp
    -> 58.842us BEGIN strcmp
    681400/681400 2065408.180154404:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154408:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.843us END   strcmp
    -> 58.843us BEGIN strcmp
    681400/681400 2065408.180154408:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180154409:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    -> 58.847us END   strcmp
    -> 58.847us END   _dl_name_match_p
    681400/681400 2065408.180154409:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180154410:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    -> 58.848us END   _dl_map_object
    -> 58.848us END   openaux
    681400/681400 2065408.180154442:   call                     7faea66bb5fe _dl_map_object_deps+0x33e =>     7faea66bf200 _dl_dst_count+0x0
    -> 58.849us END   _dl_catch_exception
    681400/681400 2065408.180154442:   call                     7faea66bf214 _dl_dst_count+0x14 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180154457:   return                   7faea66dfbb4 strchr+0x184 =>     7faea66bf219 _dl_dst_count+0x19
    -> 58.881us BEGIN _dl_dst_count
    -> 58.888us BEGIN strchr
    681400/681400 2065408.180154457:   return                   7faea66bf229 _dl_dst_count+0x29 =>     7faea66bb603 _dl_map_object_deps+0x343
    681400/681400 2065408.180154458:   call                     7faea66bb706 _dl_map_object_deps+0x446 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 58.896us END   strchr
    -> 58.896us END   _dl_dst_count
    681400/681400 2065408.180154458:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    681400/681400 2065408.180154458:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180154460:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 58.897us BEGIN _dl_catch_exception
    -> 58.897us BEGIN __sigsetjmp
    -> 58.898us END   __sigsetjmp
    -> 58.898us BEGIN __sigjmp_save
    681400/681400 2065408.180154461:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb280 openaux+0x0
    -> 58.899us END   __sigjmp_save
    681400/681400 2065408.180154461:   call                     7faea66bb2b0 openaux+0x30 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180154462:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    ->   58.9us BEGIN openaux
    ->   58.9us BEGIN _dl_map_object
    681400/681400 2065408.180154462:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154468:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.901us BEGIN _dl_name_match_p
    -> 58.904us BEGIN strcmp
    681400/681400 2065408.180154468:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154473:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 58.907us END   strcmp
    -> 58.907us BEGIN strcmp
    681400/681400 2065408.180154475:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 58.912us END   strcmp
    681400/681400 2065408.180154475:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154475:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154591:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 58.914us END   _dl_name_match_p
    -> 58.914us BEGIN _dl_name_match_p
    -> 58.972us BEGIN strcmp
    681400/681400 2065408.180154591:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154595:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  59.03us END   strcmp
    ->  59.03us BEGIN strcmp
    681400/681400 2065408.180154596:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 59.034us END   strcmp
    681400/681400 2065408.180154596:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154601:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 59.035us END   _dl_name_match_p
    -> 59.035us BEGIN strcmp
    681400/681400 2065408.180154601:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154601:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154606:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  59.04us END   strcmp
    ->  59.04us BEGIN _dl_name_match_p
    -> 59.042us BEGIN strcmp
    681400/681400 2065408.180154606:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154610:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.045us END   strcmp
    -> 59.045us BEGIN strcmp
    681400/681400 2065408.180154612:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 59.049us END   strcmp
    681400/681400 2065408.180154612:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154615:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 59.051us END   _dl_name_match_p
    -> 59.051us BEGIN strcmp
    681400/681400 2065408.180154615:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154615:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154618:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.054us END   strcmp
    -> 59.054us BEGIN _dl_name_match_p
    -> 59.055us BEGIN strcmp
    681400/681400 2065408.180154618:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154620:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.057us END   strcmp
    -> 59.057us BEGIN strcmp
    681400/681400 2065408.180154621:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    -> 59.059us END   strcmp
    681400/681400 2065408.180154624:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  59.06us BEGIN strcmp
    681400/681400 2065408.180154624:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66c164b _dl_map_object+0x9b
    681400/681400 2065408.180154625:   return                   7faea66c16be _dl_map_object+0x10e =>     7faea66bb2b5 openaux+0x35
    -> 59.063us END   strcmp
    -> 59.063us END   _dl_name_match_p
    681400/681400 2065408.180154627:   return                   7faea66bb2ba openaux+0x3a =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 59.064us END   _dl_map_object
    681400/681400 2065408.180154631:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66bb70c _dl_map_object_deps+0x44c
    -> 59.066us END   openaux
    681400/681400 2065408.180154668:   call                     7faea66bba4f _dl_map_object_deps+0x78f =>     7faea6536590 __libc_malloc+0x0
    ->  59.07us END   _dl_catch_exception
    681400/681400 2065408.180154681:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66bba55 _dl_map_object_deps+0x795
    -> 59.107us BEGIN __libc_malloc
    681400/681400 2065408.180154683:   call                     7faea66bbf83 _dl_map_object_deps+0xcc3 =>     7faea66e01d0 memcpy+0x0
    ->  59.12us END   __libc_malloc
    681400/681400 2065408.180154688:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66bbf89 _dl_map_object_deps+0xcc9
    -> 59.122us BEGIN memcpy
    681400/681400 2065408.180154688:   call                     7faea66bbd4a _dl_map_object_deps+0xa8a =>     7faea66ca220 _dl_sort_maps+0x0
    681400/681400 2065408.180154699:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    -> 59.127us END   memcpy
    -> 59.127us BEGIN _dl_sort_maps
    681400/681400 2065408.180154705:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 59.138us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180154705:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    681400/681400 2065408.180154715:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 59.144us END   dfs_traversal.part.0
    -> 59.144us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180154716:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    -> 59.154us END   dfs_traversal.part.0
    681400/681400 2065408.180154718:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 59.155us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180154719:   call                     7faea66ca674 _dl_sort_maps+0x454 =>     7faea66e01d0 memcpy+0x0
    -> 59.157us END   dfs_traversal.part.0
    681400/681400 2065408.180154724:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66ca67a _dl_sort_maps+0x45a
    -> 59.158us BEGIN memcpy
    681400/681400 2065408.180154735:   return                   7faea66ca36e _dl_sort_maps+0x14e =>     7faea66bbd4f _dl_map_object_deps+0xa8f
    -> 59.163us END   memcpy
    681400/681400 2065408.180154741:   return                   7faea66bbdaf _dl_map_object_deps+0xaef =>     7faea66c561f dl_open_worker_begin+0x10f
    -> 59.174us END   _dl_sort_maps
    681400/681400 2065408.180154744:   call                     7faea66c565e dl_open_worker_begin+0x14e =>     7faea66cc690 _dl_check_map_versions+0x0
    ->  59.18us END   _dl_map_object_deps
    681400/681400 2065408.180154758:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 59.183us BEGIN _dl_check_map_versions
    681400/681400 2065408.180154758:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154776:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.197us BEGIN _dl_name_match_p
    -> 59.206us BEGIN strcmp
    681400/681400 2065408.180154776:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154777:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.215us END   strcmp
    -> 59.215us BEGIN strcmp
    681400/681400 2065408.180154778:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.216us END   strcmp
    681400/681400 2065408.180154779:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 59.217us END   _dl_name_match_p
    681400/681400 2065408.180154779:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154782:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.218us BEGIN _dl_name_match_p
    -> 59.219us BEGIN strcmp
    681400/681400 2065408.180154782:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154786:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.221us END   strcmp
    -> 59.221us BEGIN strcmp
    681400/681400 2065408.180154787:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.225us END   strcmp
    681400/681400 2065408.180154787:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154787:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154789:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.226us END   _dl_name_match_p
    -> 59.226us BEGIN _dl_name_match_p
    -> 59.227us BEGIN strcmp
    681400/681400 2065408.180154789:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154792:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.228us END   strcmp
    -> 59.228us BEGIN strcmp
    681400/681400 2065408.180154793:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.231us END   strcmp
    681400/681400 2065408.180154794:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 59.232us END   _dl_name_match_p
    681400/681400 2065408.180154794:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154796:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.233us BEGIN _dl_name_match_p
    -> 59.234us BEGIN strcmp
    681400/681400 2065408.180154796:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154797:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.235us END   strcmp
    -> 59.235us BEGIN strcmp
    681400/681400 2065408.180154798:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    -> 59.236us END   strcmp
    681400/681400 2065408.180154801:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.237us BEGIN strcmp
    681400/681400 2065408.180154802:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66cc769 _dl_check_map_versions+0xd9
    ->  59.24us END   strcmp
    681400/681400 2065408.180154819:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    -> 59.241us END   _dl_name_match_p
    681400/681400 2065408.180154834:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    -> 59.258us BEGIN strcmp
    681400/681400 2065408.180154834:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154834:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154838:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.273us END   strcmp
    -> 59.273us BEGIN _dl_name_match_p
    -> 59.275us BEGIN strcmp
    681400/681400 2065408.180154838:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154840:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.277us END   strcmp
    -> 59.277us BEGIN strcmp
    681400/681400 2065408.180154841:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.279us END   strcmp
    681400/681400 2065408.180154841:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154841:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154844:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    ->  59.28us END   _dl_name_match_p
    ->  59.28us BEGIN _dl_name_match_p
    -> 59.281us BEGIN strcmp
    681400/681400 2065408.180154844:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154848:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 59.283us END   strcmp
    -> 59.283us BEGIN strcmp
    681400/681400 2065408.180154849:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.287us END   strcmp
    681400/681400 2065408.180154849:   call                     7faea66cc764 _dl_check_map_versions+0xd4 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180154849:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154851:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 59.288us END   _dl_name_match_p
    -> 59.288us BEGIN _dl_name_match_p
    -> 59.289us BEGIN strcmp
    681400/681400 2065408.180154851:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180154855:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    ->  59.29us END   strcmp
    ->  59.29us BEGIN strcmp
    681400/681400 2065408.180154856:   return                   7faea66c4533 _dl_name_match_p+0x53 =>     7faea66cc769 _dl_check_map_versions+0xd9
    -> 59.294us END   strcmp
    681400/681400 2065408.180154930:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    -> 59.295us END   _dl_name_match_p
    681400/681400 2065408.180154948:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    -> 59.369us BEGIN strcmp
    681400/681400 2065408.180154967:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    -> 59.387us END   strcmp
    681400/681400 2065408.180154977:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    -> 59.406us BEGIN strcmp
    681400/681400 2065408.180155038:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    -> 59.416us END   strcmp
    681400/681400 2065408.180155052:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    -> 59.477us BEGIN strcmp
    681400/681400 2065408.180155053:   call                     7faea66cc947 _dl_check_map_versions+0x2b7 =>     7faea66dc440 strcmp+0x0
    -> 59.491us END   strcmp
    681400/681400 2065408.180155072:   return                   7faea66dd86e strcmp+0x142e =>     7faea66cc94c _dl_check_map_versions+0x2bc
    -> 59.492us BEGIN strcmp
    681400/681400 2065408.180155110:   call                     7faea66ccb77 _dl_check_map_versions+0x4e7 =>     7faea65373b0 calloc+0x0
    -> 59.511us END   strcmp
    681400/681400 2065408.180155111:   call                     7faea6537484 calloc+0xd4 =>     7faea6534f00 _int_malloc+0x0
    -> 59.549us BEGIN calloc
    681400/681400 2065408.180155121:   call                     7faea6535db4 _int_malloc+0xeb4 =>     7faea6532590 alloc_perturb+0x0
    ->  59.55us BEGIN _int_malloc
    681400/681400 2065408.180155124:   return                   7faea653259a alloc_perturb+0xa =>     7faea6535db9 _int_malloc+0xeb9
    ->  59.56us BEGIN alloc_perturb
    681400/681400 2065408.180155125:   return                   7faea6535016 _int_malloc+0x116 =>     7faea6537489 calloc+0xd9
    -> 59.563us END   alloc_perturb
    681400/681400 2065408.180155127:   jmp                      7faea653768f calloc+0x2df =>     7faea662e680 __memset_evex_unaligned_erms+0x0
    -> 59.564us END   _int_malloc
    681400/681400 2065408.180155132:   return                   7faea662e77f __memset_evex_unaligned_erms+0xff =>     7faea66ccb7d _dl_check_map_versions+0x4ed
    -> 59.566us END   calloc
    -> 59.566us BEGIN __memset_evex_unaligned_erms
    681400/681400 2065408.180155217:   return                   7faea66cccb1 _dl_check_map_versions+0x621 =>     7faea66c5663 dl_open_worker_begin+0x153
    -> 59.571us END   __memset_evex_unaligned_erms
    681400/681400 2065408.180155220:   call                     7faea66c5676 dl_open_worker_begin+0x166 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    -> 59.656us END   _dl_check_map_versions
    681400/681400 2065408.180155222:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66c567b dl_open_worker_begin+0x16b
    -> 59.659us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180155222:   call                     7faea66c567f dl_open_worker_begin+0x16f =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180155222:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66c5684 dl_open_worker_begin+0x174
    681400/681400 2065408.180155222:   call                     7faea66c5693 dl_open_worker_begin+0x183 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180155223:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66c5698 dl_open_worker_begin+0x188
    -> 59.661us END   _dl_audit_activity_nsid
    -> 59.661us BEGIN _dl_debug_update
    -> 59.661us END   _dl_debug_update
    -> 59.661us BEGIN _dl_debug_state
    681400/681400 2065408.180155225:   call                     7faea66c5703 dl_open_worker_begin+0x1f3 =>     7faea66d0d30 _dl_cet_open_check+0x0
    -> 59.662us END   _dl_debug_state
    681400/681400 2065408.180155225:   jmp                      7faea66d0d36 _dl_cet_open_check+0x6 =>     7faea66d08a0 dl_cet_check+0x0
    681400/681400 2065408.180155227:   return                   7faea66d0a95 dl_cet_check+0x1f5 =>     7faea66c5708 dl_open_worker_begin+0x1f8
    -> 59.664us BEGIN _dl_cet_open_check
    -> 59.665us END   _dl_cet_open_check
    -> 59.665us BEGIN dl_cet_check
    681400/681400 2065408.180155229:   call                     7faea66c57d9 dl_open_worker_begin+0x2c9 =>     7faea66c78e0 _dl_relocate_object+0x0
    -> 59.666us END   dl_cet_check
    681400/681400 2065408.180155272:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 59.668us BEGIN _dl_relocate_object
    681400/681400 2065408.180155306:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 59.711us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155495:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 59.745us BEGIN do_lookup_x
    681400/681400 2065408.180155509:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 59.934us BEGIN check_match
    681400/681400 2065408.180155523:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 59.948us BEGIN strcmp
    681400/681400 2065408.180155523:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155528:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 59.962us END   strcmp
    -> 59.962us BEGIN strcmp
    681400/681400 2065408.180155528:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180155530:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 59.967us END   strcmp
    -> 59.967us END   check_match
    681400/681400 2065408.180155532:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 59.969us END   do_lookup_x
    681400/681400 2065408.180155537:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 59.971us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155541:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 59.976us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155561:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  59.98us BEGIN do_lookup_x
    681400/681400 2065408.180155561:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155589:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->     60us BEGIN check_match
    -> 60.014us BEGIN strcmp
    681400/681400 2065408.180155589:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155594:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.028us END   strcmp
    -> 60.028us BEGIN strcmp
    681400/681400 2065408.180155594:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180155596:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.033us END   strcmp
    -> 60.033us END   check_match
    681400/681400 2065408.180155597:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.035us END   do_lookup_x
    681400/681400 2065408.180155600:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.036us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155605:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.039us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155621:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.044us BEGIN do_lookup_x
    681400/681400 2065408.180155621:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155643:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  60.06us BEGIN check_match
    -> 60.071us BEGIN strcmp
    681400/681400 2065408.180155643:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155648:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.082us END   strcmp
    -> 60.082us BEGIN strcmp
    681400/681400 2065408.180155649:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.087us END   strcmp
    681400/681400 2065408.180155650:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.088us END   check_match
    681400/681400 2065408.180155651:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.089us END   do_lookup_x
    681400/681400 2065408.180155654:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  60.09us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155662:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.093us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155683:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.101us BEGIN do_lookup_x
    681400/681400 2065408.180155686:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.122us BEGIN check_match
    681400/681400 2065408.180155700:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.125us BEGIN strcmp
    681400/681400 2065408.180155700:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155702:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.139us END   strcmp
    -> 60.139us BEGIN strcmp
    681400/681400 2065408.180155703:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.141us END   strcmp
    681400/681400 2065408.180155704:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.142us END   check_match
    681400/681400 2065408.180155705:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.143us END   do_lookup_x
    681400/681400 2065408.180155708:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.144us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155728:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.147us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155739:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.167us BEGIN do_lookup_x
    681400/681400 2065408.180155740:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.178us END   do_lookup_x
    681400/681400 2065408.180155758:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.179us BEGIN do_lookup_x
    681400/681400 2065408.180155760:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.197us END   do_lookup_x
    681400/681400 2065408.180155769:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.199us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155775:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.208us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155793:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.214us BEGIN do_lookup_x
    681400/681400 2065408.180155793:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155808:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.232us BEGIN check_match
    -> 60.239us BEGIN strcmp
    681400/681400 2065408.180155808:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155810:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.247us END   strcmp
    -> 60.247us BEGIN strcmp
    681400/681400 2065408.180155811:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.249us END   strcmp
    681400/681400 2065408.180155812:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  60.25us END   check_match
    681400/681400 2065408.180155813:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.251us END   do_lookup_x
    681400/681400 2065408.180155817:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.252us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155821:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.256us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155841:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  60.26us BEGIN do_lookup_x
    681400/681400 2065408.180155851:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    ->  60.28us BEGIN check_match
    681400/681400 2065408.180155864:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  60.29us BEGIN strcmp
    681400/681400 2065408.180155864:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155869:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.303us END   strcmp
    -> 60.303us BEGIN strcmp
    681400/681400 2065408.180155869:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180155871:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.308us END   strcmp
    -> 60.308us END   check_match
    681400/681400 2065408.180155872:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  60.31us END   do_lookup_x
    681400/681400 2065408.180155875:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.311us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155883:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.314us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155900:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.322us BEGIN do_lookup_x
    681400/681400 2065408.180155900:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155914:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.339us BEGIN check_match
    -> 60.346us BEGIN strcmp
    681400/681400 2065408.180155914:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180155916:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.353us END   strcmp
    -> 60.353us BEGIN strcmp
    681400/681400 2065408.180155917:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.355us END   strcmp
    681400/681400 2065408.180155919:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.356us END   check_match
    681400/681400 2065408.180155919:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    681400/681400 2065408.180155923:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.358us END   do_lookup_x
    -> 60.358us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155933:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.362us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180155944:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.372us BEGIN do_lookup_x
    681400/681400 2065408.180155944:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180155949:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.383us END   do_lookup_x
    -> 60.383us BEGIN do_lookup_x
    681400/681400 2065408.180155965:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    -> 60.388us BEGIN check_match
    681400/681400 2065408.180155975:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.404us BEGIN strcmp
    681400/681400 2065408.180155975:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180155978:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.414us END   strcmp
    -> 60.414us END   check_match
    681400/681400 2065408.180155980:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.417us END   do_lookup_x
    681400/681400 2065408.180155984:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.419us END   _dl_lookup_symbol_x
    681400/681400 2065408.180155991:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.423us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156015:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  60.43us BEGIN do_lookup_x
    681400/681400 2065408.180156018:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.454us BEGIN check_match
    681400/681400 2065408.180156025:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.457us BEGIN strcmp
    681400/681400 2065408.180156025:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156030:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.464us END   strcmp
    -> 60.464us BEGIN strcmp
    681400/681400 2065408.180156031:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.469us END   strcmp
    681400/681400 2065408.180156032:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  60.47us END   check_match
    681400/681400 2065408.180156033:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.471us END   do_lookup_x
    681400/681400 2065408.180156035:   call                     7faea66c85d5 _dl_relocate_object+0xcf5 =>     7faea65391f0 strlen+0x0
    -> 60.472us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156055:   return                   7faea6539267 strlen+0x77 =>     7faea66c85d8 _dl_relocate_object+0xcf8
    -> 60.474us BEGIN strlen
    681400/681400 2065408.180156060:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.494us END   strlen
    681400/681400 2065408.180156079:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.499us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156101:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.518us BEGIN do_lookup_x
    681400/681400 2065408.180156101:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156114:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  60.54us BEGIN check_match
    -> 60.546us BEGIN strcmp
    681400/681400 2065408.180156114:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156118:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.553us END   strcmp
    -> 60.553us BEGIN strcmp
    681400/681400 2065408.180156119:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.557us END   strcmp
    681400/681400 2065408.180156120:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.558us END   check_match
    681400/681400 2065408.180156121:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.559us END   do_lookup_x
    681400/681400 2065408.180156124:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  60.56us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156140:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.563us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156156:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.579us BEGIN do_lookup_x
    681400/681400 2065408.180156162:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.595us BEGIN check_match
    681400/681400 2065408.180156172:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.601us BEGIN strcmp
    681400/681400 2065408.180156172:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156175:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.611us END   strcmp
    -> 60.611us BEGIN strcmp
    681400/681400 2065408.180156175:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180156283:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.614us END   strcmp
    -> 60.614us END   check_match
    681400/681400 2065408.180156292:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.722us END   do_lookup_x
    681400/681400 2065408.180156298:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.731us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156314:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.737us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156329:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.753us BEGIN do_lookup_x
    681400/681400 2065408.180156332:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.768us BEGIN check_match
    681400/681400 2065408.180156340:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.771us BEGIN strcmp
    681400/681400 2065408.180156340:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156346:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.779us END   strcmp
    -> 60.779us BEGIN strcmp
    681400/681400 2065408.180156346:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180156348:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.785us END   strcmp
    -> 60.785us END   check_match
    681400/681400 2065408.180156349:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.787us END   do_lookup_x
    681400/681400 2065408.180156352:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.788us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156357:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.791us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156369:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.796us BEGIN do_lookup_x
    681400/681400 2065408.180156381:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.808us BEGIN check_match
    681400/681400 2065408.180156389:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->  60.82us BEGIN strcmp
    681400/681400 2065408.180156389:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156394:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.828us END   strcmp
    -> 60.828us BEGIN strcmp
    681400/681400 2065408.180156394:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180156397:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.833us END   strcmp
    -> 60.833us END   check_match
    681400/681400 2065408.180156397:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    681400/681400 2065408.180156400:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.836us END   do_lookup_x
    -> 60.836us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156418:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.839us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156423:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.857us BEGIN do_lookup_x
    681400/681400 2065408.180156436:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 60.862us BEGIN check_match
    681400/681400 2065408.180156453:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.875us BEGIN strcmp
    681400/681400 2065408.180156454:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.892us END   strcmp
    681400/681400 2065408.180156454:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    681400/681400 2065408.180156454:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156459:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 60.893us END   check_match
    -> 60.893us BEGIN check_match
    -> 60.895us BEGIN strcmp
    681400/681400 2065408.180156459:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156462:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.898us END   strcmp
    -> 60.898us BEGIN strcmp
    681400/681400 2065408.180156463:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 60.901us END   strcmp
    681400/681400 2065408.180156464:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.902us END   check_match
    681400/681400 2065408.180156465:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.903us END   do_lookup_x
    681400/681400 2065408.180156470:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.904us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156479:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.909us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156489:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.918us BEGIN do_lookup_x
    681400/681400 2065408.180156489:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180156499:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 60.928us END   do_lookup_x
    -> 60.928us BEGIN do_lookup_x
    681400/681400 2065408.180156505:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    -> 60.938us BEGIN check_match
    681400/681400 2065408.180156512:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 60.944us BEGIN strcmp
    681400/681400 2065408.180156512:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180156514:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.951us END   strcmp
    -> 60.951us END   check_match
    681400/681400 2065408.180156515:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 60.953us END   do_lookup_x
    681400/681400 2065408.180156518:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.954us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156527:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.957us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156540:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.966us BEGIN do_lookup_x
    681400/681400 2065408.180156540:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180156551:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 60.979us END   do_lookup_x
    -> 60.979us BEGIN do_lookup_x
    681400/681400 2065408.180156553:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  60.99us END   do_lookup_x
    681400/681400 2065408.180156555:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 60.992us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156574:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 60.994us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156586:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.013us BEGIN do_lookup_x
    681400/681400 2065408.180156597:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.025us BEGIN check_match
    681400/681400 2065408.180156605:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.036us BEGIN strcmp
    681400/681400 2065408.180156605:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156609:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.044us END   strcmp
    -> 61.044us BEGIN strcmp
    681400/681400 2065408.180156610:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.048us END   strcmp
    681400/681400 2065408.180156611:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.049us END   check_match
    681400/681400 2065408.180156612:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  61.05us END   do_lookup_x
    681400/681400 2065408.180156615:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.051us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156635:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.054us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156650:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.074us BEGIN do_lookup_x
    681400/681400 2065408.180156657:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.089us BEGIN check_match
    681400/681400 2065408.180156670:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.096us BEGIN strcmp
    681400/681400 2065408.180156670:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156679:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.109us END   strcmp
    -> 61.109us BEGIN strcmp
    681400/681400 2065408.180156680:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.118us END   strcmp
    681400/681400 2065408.180156682:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.119us END   check_match
    681400/681400 2065408.180156682:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    681400/681400 2065408.180156685:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.121us END   do_lookup_x
    -> 61.121us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156692:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.124us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156706:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.131us BEGIN do_lookup_x
    681400/681400 2065408.180156714:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.145us BEGIN check_match
    681400/681400 2065408.180156722:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.153us BEGIN strcmp
    681400/681400 2065408.180156722:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156727:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.161us END   strcmp
    -> 61.161us BEGIN strcmp
    681400/681400 2065408.180156727:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180156729:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.166us END   strcmp
    -> 61.166us END   check_match
    681400/681400 2065408.180156730:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.168us END   do_lookup_x
    681400/681400 2065408.180156733:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.169us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156739:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.172us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156780:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.178us BEGIN do_lookup_x
    681400/681400 2065408.180156780:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180156785:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.219us END   do_lookup_x
    -> 61.219us BEGIN do_lookup_x
    681400/681400 2065408.180156801:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    -> 61.224us BEGIN check_match
    681400/681400 2065408.180156804:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    ->  61.24us BEGIN strcmp
    681400/681400 2065408.180156805:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.243us END   strcmp
    681400/681400 2065408.180156808:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.244us END   check_match
    681400/681400 2065408.180156821:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.247us END   do_lookup_x
    681400/681400 2065408.180156832:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    ->  61.26us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156848:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.271us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156854:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.287us BEGIN do_lookup_x
    681400/681400 2065408.180156861:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.293us BEGIN check_match
    681400/681400 2065408.180156870:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->   61.3us BEGIN strcmp
    681400/681400 2065408.180156870:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180156872:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.309us END   strcmp
    -> 61.309us BEGIN strcmp
    681400/681400 2065408.180156873:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.311us END   strcmp
    681400/681400 2065408.180156874:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.312us END   check_match
    681400/681400 2065408.180156875:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.313us END   do_lookup_x
    681400/681400 2065408.180156878:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.314us END   _dl_lookup_symbol_x
    681400/681400 2065408.180156887:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.317us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180156900:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.326us BEGIN do_lookup_x
    681400/681400 2065408.180156900:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180156912:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.339us END   do_lookup_x
    -> 61.339us BEGIN do_lookup_x
    681400/681400 2065408.180156915:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    -> 61.351us BEGIN check_match
    681400/681400 2065408.180156920:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.354us BEGIN strcmp
    681400/681400 2065408.180156921:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.359us END   strcmp
    681400/681400 2065408.180156922:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  61.36us END   check_match
    681400/681400 2065408.180156924:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.361us END   do_lookup_x
    681400/681400 2065408.180157033:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.363us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157041:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.472us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157061:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    ->  61.48us BEGIN do_lookup_x
    681400/681400 2065408.180157061:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157075:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    ->   61.5us BEGIN check_match
    -> 61.507us BEGIN strcmp
    681400/681400 2065408.180157075:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157080:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.514us END   strcmp
    -> 61.514us BEGIN strcmp
    681400/681400 2065408.180157081:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.519us END   strcmp
    681400/681400 2065408.180157083:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    ->  61.52us END   check_match
    681400/681400 2065408.180157084:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.522us END   do_lookup_x
    681400/681400 2065408.180157086:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.523us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157105:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.525us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157117:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.544us BEGIN do_lookup_x
    681400/681400 2065408.180157117:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    681400/681400 2065408.180157127:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.556us END   do_lookup_x
    -> 61.556us BEGIN do_lookup_x
    681400/681400 2065408.180157129:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.566us END   do_lookup_x
    681400/681400 2065408.180157131:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.568us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157140:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    ->  61.57us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157147:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.579us BEGIN do_lookup_x
    681400/681400 2065408.180157159:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.586us BEGIN check_match
    681400/681400 2065408.180157169:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.598us BEGIN strcmp
    681400/681400 2065408.180157170:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.608us END   strcmp
    681400/681400 2065408.180157170:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    681400/681400 2065408.180157173:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.609us END   check_match
    -> 61.609us BEGIN check_match
    681400/681400 2065408.180157176:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.612us BEGIN strcmp
    681400/681400 2065408.180157176:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157179:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.615us END   strcmp
    -> 61.615us BEGIN strcmp
    681400/681400 2065408.180157179:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180157181:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.618us END   strcmp
    -> 61.618us END   check_match
    681400/681400 2065408.180157182:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  61.62us END   do_lookup_x
    681400/681400 2065408.180157184:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.621us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157197:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.623us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157210:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.636us BEGIN do_lookup_x
    681400/681400 2065408.180157210:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157229:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.649us BEGIN check_match
    -> 61.658us BEGIN strcmp
    681400/681400 2065408.180157229:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157234:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.668us END   strcmp
    -> 61.668us BEGIN strcmp
    681400/681400 2065408.180157235:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.673us END   strcmp
    681400/681400 2065408.180157236:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.674us END   check_match
    681400/681400 2065408.180157237:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.675us END   do_lookup_x
    681400/681400 2065408.180157240:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.676us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157256:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.679us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157263:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.695us BEGIN do_lookup_x
    681400/681400 2065408.180157274:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 61.702us BEGIN check_match
    681400/681400 2065408.180157284:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.713us BEGIN strcmp
    681400/681400 2065408.180157284:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157289:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.723us END   strcmp
    -> 61.723us BEGIN strcmp
    681400/681400 2065408.180157289:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    681400/681400 2065408.180157291:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.728us END   strcmp
    -> 61.728us END   check_match
    681400/681400 2065408.180157292:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    ->  61.73us END   do_lookup_x
    681400/681400 2065408.180157294:   call                     7faea66c804b _dl_relocate_object+0x76b =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 61.731us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157300:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 61.733us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180157305:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 61.739us BEGIN do_lookup_x
    681400/681400 2065408.180157305:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157322:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 61.744us BEGIN check_match
    -> 61.752us BEGIN strcmp
    681400/681400 2065408.180157322:   call                     7faea66c2297 check_match+0x137 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180157327:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c229c check_match+0x13c
    -> 61.761us END   strcmp
    -> 61.761us BEGIN strcmp
    681400/681400 2065408.180157328:   return                   7faea66c222a check_match+0xca =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 61.766us END   strcmp
    681400/681400 2065408.180157329:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 61.767us END   check_match
    681400/681400 2065408.180157330:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea66c8050 _dl_relocate_object+0x770
    -> 61.768us END   do_lookup_x
    681400/681400 2065408.180157386:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63de530 sinf32x+0x0
    -> 61.769us END   _dl_lookup_symbol_x
    681400/681400 2065408.180157588:   hw int                   7faea63de530 sinf32x+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 61.825us BEGIN sinf32x
    681400/681400 2065408.180158863:   tr strt                             0 [unknown] =>     7faea63de530 sinf32x+0x0
    -> 62.027us BEGIN asm_exc_page_fault
    681400/681400 2065408.180158890:   return                   7faea63de57e sinf32x+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    -> 63.302us END   asm_exc_page_fault
    681400/681400 2065408.180158896:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d58b0 __atan2_finite+0x0
    -> 63.329us END   sinf32x
    681400/681400 2065408.180158915:   return                   7faea63d58fe __atan2_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    -> 63.335us BEGIN __atan2_finite
    681400/681400 2065408.180158920:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63f65b0 exp2f+0x0
    -> 63.354us END   __atan2_finite
    681400/681400 2065408.180159107:   hw int                   7faea63f65b0 exp2f+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 63.359us BEGIN exp2f
    681400/681400 2065408.180160328:   tr strt                             0 [unknown] =>     7faea63f65b0 exp2f+0x0
    -> 63.546us BEGIN asm_exc_page_fault
    681400/681400 2065408.180160354:   return                   7faea63f65dd exp2f+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 64.767us END   asm_exc_page_fault
    681400/681400 2065408.180160359:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d4d20 __asin_finite+0x0
    681400/681400 2065408.180160369:   return                   7faea63d4d5d __asin_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 64.798us BEGIN __asin_finite
    681400/681400 2065408.180160373:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63e0dd0 fmaf32x+0x0
    -> 64.808us END   __asin_finite
    681400/681400 2065408.180160555:   hw int                   7faea63e0dd0 fmaf32x+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 64.812us BEGIN fmaf32x
    681400/681400 2065408.180161770:   tr strt                             0 [unknown] =>     7faea63e0dd0 fmaf32x+0x0
    -> 64.994us BEGIN asm_exc_page_fault
    681400/681400 2065408.180161798:   return                   7faea63e0e04 fmaf32x+0x34 =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.209us END   asm_exc_page_fault
    681400/681400 2065408.180161801:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ef720 sinf+0x0
    -> 66.237us END   fmaf32x
    681400/681400 2065408.180161805:   return                   7faea63ef74d sinf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  66.24us BEGIN sinf
    681400/681400 2065408.180161809:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d4d60 __acos_finite+0x0
    -> 66.244us END   sinf
    681400/681400 2065408.180161809:   return                   7faea63d4d9d __acos_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    681400/681400 2065408.180161814:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d9340 __log_finite+0x0
    -> 66.248us BEGIN __acos_finite
    -> 66.253us END   __acos_finite
    681400/681400 2065408.180161825:   return                   7faea63d938e __log_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.253us BEGIN __log_finite
    681400/681400 2065408.180161830:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63efd90 __log2f_finite+0x0
    -> 66.264us END   __log_finite
    681400/681400 2065408.180161833:   return                   7faea63efdbd __log2f_finite+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.269us BEGIN __log2f_finite
    681400/681400 2065408.180161838:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d9c00 __pow_finite+0x0
    -> 66.272us END   __log2f_finite
    681400/681400 2065408.180161841:   return                   7faea63d9c3d __pow_finite+0x3d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.277us BEGIN __pow_finite
    681400/681400 2065408.180161844:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ece50 powf+0x0
    ->  66.28us END   __pow_finite
    681400/681400 2065408.180161851:   return                   7faea63ece7d powf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.283us BEGIN powf
    681400/681400 2065408.180161854:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63efe60 sincosf32+0x0
    ->  66.29us END   powf
    681400/681400 2065408.180161855:   return                   7faea63efe8d sincosf32+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.293us BEGIN sincosf32
    681400/681400 2065408.180161859:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ec960 logf+0x0
    -> 66.294us END   sincosf32
    681400/681400 2065408.180161862:   return                   7faea63ec98d logf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.298us BEGIN logf
    681400/681400 2065408.180161866:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63de580 cos+0x0
    -> 66.301us END   logf
    681400/681400 2065408.180161867:   return                   7faea63de5ce cos+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.305us BEGIN cos
    681400/681400 2065408.180161870:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63e8e10 expf+0x0
    -> 66.306us END   cos
    681400/681400 2065408.180161874:   return                   7faea63e8e3d expf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    -> 66.309us BEGIN expf
    681400/681400 2065408.180161878:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63d5dd0 __exp_finite+0x0
    -> 66.313us END   expf
    681400/681400 2065408.180161878:   return                   7faea63d5e1e __exp_finite+0x4e =>     7faea66c8243 _dl_relocate_object+0x963
    681400/681400 2065408.180161881:   call                     7faea66c8241 _dl_relocate_object+0x961 =>     7faea63ee210 cosf+0x0
    -> 66.317us BEGIN __exp_finite
    ->  66.32us END   __exp_finite
    681400/681400 2065408.180161887:   return                   7faea63ee23d cosf+0x2d =>     7faea66c8243 _dl_relocate_object+0x963
    ->  66.32us BEGIN cosf
    681400/681400 2065408.180161912:   call                     7faea66c8913 _dl_relocate_object+0x1033 =>     7faea66c77a0 _dl_protect_relro+0x0
    -> 66.326us END   cosf
    681400/681400 2065408.180161912:   call                     7faea66c77e0 _dl_protect_relro+0x40 =>     7faea66dbf40 mprotect+0x0
    681400/681400 2065408.180161924:   syscall                  7faea66dbf49 mprotect+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 66.351us BEGIN _dl_protect_relro
    -> 66.357us BEGIN mprotect
    681400/681400 2065408.180163225:   tr strt                             0 [unknown] =>     7faea66dbf4b mprotect+0xb
    -> 66.363us BEGIN __entry_text_start
    681400/681400 2065408.180163228:   return                   7faea66dbf53 mprotect+0x13 =>     7faea66c77e5 _dl_protect_relro+0x45
    -> 67.664us END   __entry_text_start
    681400/681400 2065408.180163239:   return                   7faea66c77d2 _dl_protect_relro+0x32 =>     7faea66c8918 _dl_relocate_object+0x1038
    681400/681400 2065408.180163242:   return                   7faea66c8926 _dl_relocate_object+0x1046 =>     7faea66c57de dl_open_worker_begin+0x2ce
    -> 67.678us END   _dl_protect_relro
    681400/681400 2065408.180163287:   call                     7faea66c58f3 dl_open_worker_begin+0x3e3 =>     7faea66bd430 _dl_find_object_update+0x0
    -> 67.681us END   _dl_relocate_object
    681400/681400 2065408.180163296:   call                     7faea66bd491 _dl_find_object_update+0x61 =>     7faea6536590 __libc_malloc+0x0
    -> 67.726us BEGIN _dl_find_object_update
    681400/681400 2065408.180163317:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66bd493 _dl_find_object_update+0x63
    -> 67.735us BEGIN __libc_malloc
    681400/681400 2065408.180163321:   call                     7faea66bd693 _dl_find_object_update+0x263 =>     7faea66bcc40 _dl_find_object_from_map+0x0
    -> 67.756us END   __libc_malloc
    -> 61.736us END   _dl_relocate_object
    -> 61.736us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180163337:   return                   7faea66bcc9c _dl_find_object_from_map+0x5c =>     7faea66bd698 _dl_find_object_update+0x268
    ->  67.76us BEGIN _dl_find_object_from_map
    681400/681400 2065408.180163347:   call                     7faea66bd7ad _dl_find_object_update+0x37d =>     7faea6536b70 __libc_free+0x0
    -> 67.776us END   _dl_find_object_from_map
    681400/681400 2065408.180163350:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    -> 67.786us BEGIN __libc_free
    681400/681400 2065408.180163378:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 67.789us BEGIN _int_free
    681400/681400 2065408.180163383:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bd7b3 _dl_find_object_update+0x383
    -> 67.817us END   _int_free
    681400/681400 2065408.180163384:   return                   7faea66bd6f4 _dl_find_object_update+0x2c4 =>     7faea66c58f8 dl_open_worker_begin+0x3e8
    -> 67.822us END   __libc_free
    681400/681400 2065408.180163392:   return                   7faea66c592b dl_open_worker_begin+0x41b =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 67.823us END   _dl_find_object_update
    681400/681400 2065408.180163407:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c4d7b dl_open_worker+0x3b
    -> 67.831us END   dl_open_worker_begin
    681400/681400 2065408.180163426:   call                     7faea66c4d80 dl_open_worker+0x40 =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 67.846us END   _dl_catch_exception
    681400/681400 2065408.180163426:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180163435:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c4d86 dl_open_worker+0x46
    -> 67.865us BEGIN __pthread_mutex_unlock
    -> 67.869us END   __pthread_mutex_unlock
    -> 67.869us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180163438:   call                     7faea66c4dd9 dl_open_worker+0x99 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 67.874us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180163441:   call                     7faea65f3e73 _dl_catch_exception+0xe3 =>     7faea66c4e40 call_dl_init+0x0
    -> 67.877us BEGIN _dl_catch_exception
    681400/681400 2065408.180163441:   jmp                      7faea66c4e52 call_dl_init+0x12 =>     7faea66bdf50 _dl_init+0x0
    681400/681400 2065408.180163450:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    ->  67.88us BEGIN call_dl_init
    -> 67.884us END   call_dl_init
    -> 67.884us BEGIN _dl_init
    681400/681400 2065408.180163458:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 67.889us BEGIN call_init
    681400/681400 2065408.180163459:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    -> 67.897us END   call_init
    681400/681400 2065408.180163465:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 67.898us BEGIN call_init
    681400/681400 2065408.180163465:   call                     7faea66bdfc7 _dl_init+0x77 =>     7faea66bde20 call_init+0x0
    681400/681400 2065408.180163485:   call                     7faea66bde97 call_init+0x77 =>     7faea63be000 _init+0x0
    -> 67.904us END   call_init
    -> 67.904us BEGIN call_init
    681400/681400 2065408.180163673:   hw int                   7faea63be000 _init+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 67.924us BEGIN _init
    681400/681400 2065408.180164986:   tr strt                             0 [unknown] =>     7faea63be000 _init+0x0
    -> 68.112us BEGIN asm_exc_page_fault
    681400/681400 2065408.180165015:   return                   7faea63be01a _init+0x1a =>     7faea66bde99 call_init+0x79
    -> 69.425us END   asm_exc_page_fault
    681400/681400 2065408.180165028:   call                     7faea66bdedc call_init+0xbc =>     7faea63be520 frame_dummy+0x0
    -> 69.454us END   _init
    681400/681400 2065408.180165028:   jmp                      7faea63be524 frame_dummy+0x4 =>     7faea63be490 register_tm_clones+0x0
    681400/681400 2065408.180165030:   return                   7faea63be4c8 register_tm_clones+0x38 =>     7faea66bdede call_init+0xbe
    -> 69.467us BEGIN frame_dummy
    -> 69.468us END   frame_dummy
    -> 69.468us BEGIN register_tm_clones
    681400/681400 2065408.180165031:   return                   7faea66bdeee call_init+0xce =>     7faea66bdfcc _dl_init+0x7c
    -> 69.469us END   register_tm_clones
    681400/681400 2065408.180165040:   return                   7faea66bdfe0 _dl_init+0x90 =>     7faea65f3e75 _dl_catch_exception+0xe5
    ->  69.47us END   call_init
    681400/681400 2065408.180165050:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c4ddf dl_open_worker+0x9f
    -> 69.479us END   _dl_init
    681400/681400 2065408.180165054:   return                   7faea66c4da2 dl_open_worker+0x62 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 69.489us END   _dl_catch_exception
    681400/681400 2065408.180165068:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66c515d _dl_open+0xad
    -> 69.493us END   dl_open_worker
    681400/681400 2065408.180165068:   call                     7faea66c5160 _dl_open+0xb0 =>     7faea66cda00 _dl_unload_cache+0x0
    681400/681400 2065408.180165082:   call                     7faea66cda2b _dl_unload_cache+0x2b =>     7faea66dbf10 __munmap+0x0
    -> 69.507us END   _dl_catch_exception
    -> 69.507us BEGIN _dl_unload_cache
    681400/681400 2065408.180165094:   syscall                  7faea66dbf19 __munmap+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 69.521us BEGIN __munmap
    681400/681400 2065408.180168521:   tr strt                             0 [unknown] =>     7faea66dbf1b __munmap+0xb
    -> 69.533us BEGIN __entry_text_start
    681400/681400 2065408.180168531:   return                   7faea66dbf23 __munmap+0x13 =>     7faea66cda30 _dl_unload_cache+0x30
    ->  72.96us END   __entry_text_start
    681400/681400 2065408.180168552:   return                   7faea66cda49 _dl_unload_cache+0x49 =>     7faea66c5165 _dl_open+0xb5
    681400/681400 2065408.180168572:   call                     7faea66c5192 _dl_open+0xe2 =>     7faea66bb0a0 _dl_debug_update+0x0
    -> 72.991us END   _dl_unload_cache
    681400/681400 2065408.180168581:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66c5197 _dl_open+0xe7
    -> 73.011us BEGIN _dl_debug_update
    681400/681400 2065408.180168581:   call                     7faea66c51a5 _dl_open+0xf5 =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180168581:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180168595:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66c51ab _dl_open+0xfb
    ->  73.02us END   _dl_debug_update
    ->  73.02us BEGIN __pthread_mutex_unlock
    -> 73.027us END   __pthread_mutex_unlock
    -> 73.027us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180168597:   return                   7faea66c51c1 _dl_open+0x111 =>     7faea652274c dlopen_doit+0x5c
    -> 73.034us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180168617:   return                   7faea6522753 dlopen_doit+0x63 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 73.036us END   _dl_open
    681400/681400 2065408.180168642:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    -> 73.056us END   dlopen_doit
    681400/681400 2065408.180168650:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 73.081us END   _dl_catch_exception
    681400/681400 2065408.180168663:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea65227d8 dlopen+0x48
    -> 73.089us END   _dl_catch_error
    681400/681400 2065408.180168675:   return                   7faea65227f9 dlopen+0x69 =>     55cf38e4f1d2 main+0x39
    -> 73.102us END   _dlerror_run
    681400/681400 2065408.180168696:   call                     55cf38e4f20d main+0x74 =>     55cf38e4f030 _init+0x30
    -> 73.114us END   dlopen
    681400/681400 2065408.180168702:   jmp                      55cf38e4f030 _init+0x30 =>     7faea6521f90 dlerror+0x0
    -> 73.135us BEGIN _init
    681400/681400 2065408.180168712:   return                   7faea652207a dlerror+0xea =>     55cf38e4f212 main+0x79
    -> 73.141us END   _init
    -> 73.141us BEGIN dlerror
    681400/681400 2065408.180168712:   call                     55cf38e4f223 main+0x8a =>     55cf38e4f070 dlsym@plt+0x0
    681400/681400 2065408.180168716:   jmp                      55cf38e4f070 dlsym@plt+0x0 =>     7faea6522850 dlsym+0x0
    -> 73.151us END   dlerror
    -> 73.151us BEGIN dlsym@plt
    681400/681400 2065408.180168719:   call                     7faea65228a1 dlsym+0x51 =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 73.155us END   dlsym@plt
    -> 73.155us BEGIN dlsym
    681400/681400 2065408.180168728:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea65228a6 dlsym+0x56
    -> 73.158us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180168728:   call                     7faea65228b0 dlsym+0x60 =>     7faea65221c0 _dlerror_run+0x0
    681400/681400 2065408.180168734:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    -> 73.167us END   __pthread_mutex_lock
    -> 73.167us BEGIN _dlerror_run
    681400/681400 2065408.180168739:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 73.173us BEGIN _rtld_catch_error
    681400/681400 2065408.180168739:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180168743:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 73.178us END   _rtld_catch_error
    -> 73.178us BEGIN _dl_catch_error
    ->  73.18us BEGIN _dl_catch_exception
    681400/681400 2065408.180168743:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180168750:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 73.182us BEGIN __sigsetjmp
    -> 73.185us END   __sigsetjmp
    -> 73.185us BEGIN __sigjmp_save
    681400/681400 2065408.180168750:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea6522830 dlsym_doit+0x0
    681400/681400 2065408.180168750:   call                     7faea6522843 dlsym_doit+0x13 =>     7faea65f4ac0 _dl_sym+0x0
    681400/681400 2065408.180168750:   jmp                      7faea65f4acc _dl_sym+0xc =>     7faea65f4670 do_sym+0x0
    681400/681400 2065408.180168768:   call                     7faea65f46d7 do_sym+0x67 =>     7faea66c2fc0 _dl_lookup_symbol_x+0x0
    -> 73.189us END   __sigjmp_save
    -> 73.189us BEGIN dlsym_doit
    -> 73.195us BEGIN _dl_sym
    -> 73.201us END   _dl_sym
    -> 73.201us BEGIN do_sym
    681400/681400 2065408.180168786:   call                     7faea66c30dc _dl_lookup_symbol_x+0x11c =>     7faea66c2310 do_lookup_x+0x0
    -> 73.207us BEGIN _dl_lookup_symbol_x
    681400/681400 2065408.180168795:   call                     7faea66c26c3 do_lookup_x+0x3b3 =>     7faea66c2160 check_match+0x0
    -> 73.225us BEGIN do_lookup_x
    681400/681400 2065408.180168814:   call                     7faea66c21c2 check_match+0x62 =>     7faea66dc440 strcmp+0x0
    -> 73.234us BEGIN check_match
    681400/681400 2065408.180168824:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c21c7 check_match+0x67
    -> 73.253us BEGIN strcmp
    681400/681400 2065408.180168825:   return                   7faea66c228a check_match+0x12a =>     7faea66c26c8 do_lookup_x+0x3b8
    -> 73.263us END   strcmp
    681400/681400 2065408.180168829:   return                   7faea66c26f3 do_lookup_x+0x3e3 =>     7faea66c30e1 _dl_lookup_symbol_x+0x121
    -> 73.264us END   check_match
    681400/681400 2065408.180168831:   return                   7faea66c3168 _dl_lookup_symbol_x+0x1a8 =>     7faea65f46dd do_sym+0x6d
    -> 73.268us END   do_lookup_x
    681400/681400 2065408.180168832:   call                     7faea65f4890 do_sym+0x220 =>     7faea63de580 cos+0x0
    ->  73.27us END   _dl_lookup_symbol_x
    681400/681400 2065408.180168842:   return                   7faea63de5ce cos+0x4e =>     7faea65f4892 do_sym+0x222
    -> 73.271us BEGIN cos
    681400/681400 2065408.180168845:   return                   7faea65f4762 do_sym+0xf2 =>     7faea6522848 dlsym_doit+0x18
    -> 73.281us END   cos
    681400/681400 2065408.180168845:   return                   7faea652284d dlsym_doit+0x1d =>     7faea65f3e18 _dl_catch_exception+0x88
    681400/681400 2065408.180168846:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    -> 73.284us END   do_sym
    -> 73.284us END   dlsym_doit
    681400/681400 2065408.180168848:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 73.285us END   _dl_catch_exception
    681400/681400 2065408.180168850:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea65228b5 dlsym+0x65
    -> 73.287us END   _dl_catch_error
    681400/681400 2065408.180168850:   call                     7faea65228c0 dlsym+0x70 =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180168850:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180168855:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea65228c5 dlsym+0x75
    -> 73.289us END   _dlerror_run
    -> 73.289us BEGIN __pthread_mutex_unlock
    -> 73.291us END   __pthread_mutex_unlock
    -> 73.291us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180168856:   return                   7faea65228df dlsym+0x8f =>     55cf38e4f228 main+0x8f
    -> 73.294us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180168856:   call                     55cf38e4f22c main+0x93 =>     55cf38e4f030 _init+0x30
    681400/681400 2065408.180168858:   jmp                      55cf38e4f030 _init+0x30 =>     7faea6521f90 dlerror+0x0
    -> 73.295us END   dlsym
    -> 73.295us BEGIN _init
    681400/681400 2065408.180168862:   return                   7faea652207a dlerror+0xea =>     55cf38e4f231 main+0x98
    -> 73.297us END   _init
    -> 73.297us BEGIN dlerror
    681400/681400 2065408.180168865:   call                     55cf38e4f278 main+0xdf =>     7faea6422040 __cos_fma+0x0
    -> 73.301us END   dlerror
    681400/681400 2065408.180169064:   hw int                   7faea6422040 __cos_fma+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 73.304us BEGIN __cos_fma
    681400/681400 2065408.180170411:   tr strt                             0 [unknown] =>     7faea6422040 __cos_fma+0x0
    -> 73.503us BEGIN asm_exc_page_fault
    681400/681400 2065408.180170575:   hw int                   7faea6422193 __cos_fma+0x153 => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->  74.85us END   asm_exc_page_fault
    681400/681400 2065408.180171750:   tr strt                             0 [unknown] =>     7faea6422193 __cos_fma+0x153
    -> 75.014us BEGIN asm_exc_page_fault
    681400/681400 2065408.180171912:   hw int                   7faea64221a3 __cos_fma+0x163 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 76.189us END   asm_exc_page_fault
    681400/681400 2065408.180172991:   tr strt                             0 [unknown] =>     7faea64221a3 __cos_fma+0x163
    -> 76.351us BEGIN asm_exc_page_fault
    681400/681400 2065408.180173156:   hw int                   7faea642222f __cos_fma+0x1ef => ffffffffae200ab0 asm_exc_page_fault+0x0
    ->  77.43us END   asm_exc_page_fault
    681400/681400 2065408.180174184:   tr strt                             0 [unknown] =>     7faea642222f __cos_fma+0x1ef
    -> 77.595us BEGIN asm_exc_page_fault
    681400/681400 2065408.180174447:   hw int                   7faea6422238 __cos_fma+0x1f8 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 78.623us END   asm_exc_page_fault
    681400/681400 2065408.180174846:   tr strt                             0 [unknown] =>     7faea6422238 __cos_fma+0x1f8
    -> 78.886us BEGIN asm_exc_page_fault
    681400/681400 2065408.180174876:   return                   7faea6422173 __cos_fma+0x133 =>     55cf38e4f27a main+0xe1
    -> 79.285us END   asm_exc_page_fault
    681400/681400 2065408.180174876:   call                     55cf38e4f29a main+0x101 =>     55cf38e4f050 fprintf@plt+0x0
    681400/681400 2065408.180174877:   jmp                      55cf38e4f050 fprintf@plt+0x0 =>     7faea64f6700 fprintf+0x0
    -> 79.315us END   __cos_fma
    -> 79.315us BEGIN fprintf@plt
    681400/681400 2065408.180174877:   call                     7faea64f6795 fprintf+0x95 =>     7faea6509480 __vfprintf_internal+0x0
    681400/681400 2065408.180174886:   call                     7faea650951c __vfprintf_internal+0x9c =>     7faea6630240 __strchrnul_evex+0x0
    -> 79.316us END   fprintf@plt
    -> 79.316us BEGIN fprintf
    ->  79.32us BEGIN __vfprintf_internal
    681400/681400 2065408.180174895:   return                   7faea663028a __strchrnul_evex+0x4a =>     7faea6509522 __vfprintf_internal+0xa2
    -> 79.325us BEGIN __strchrnul_evex
    681400/681400 2065408.180174895:   call                     7faea6509917 __vfprintf_internal+0x497 =>     7faea6523230 __GI___libc_cleanup_push_defer+0x0
    681400/681400 2065408.180174920:   return                   7faea6523263 __GI___libc_cleanup_push_defer+0x33 =>     7faea650991c __vfprintf_internal+0x49c
    -> 79.334us END   __strchrnul_evex
    -> 79.334us BEGIN __GI___libc_cleanup_push_defer
    681400/681400 2065408.180174929:   call                     7faea650958b __vfprintf_internal+0x10b =>     7faea651e5d0 _IO_file_xsputn+0x0
    -> 79.359us END   __GI___libc_cleanup_push_defer
    681400/681400 2065408.180174930:   return                   7faea651e656 _IO_file_xsputn+0x86 =>     7faea650958e __vfprintf_internal+0x10e
    -> 79.368us BEGIN _IO_file_xsputn
    681400/681400 2065408.180174951:   call                     7faea650ad50 __vfprintf_internal+0x18d0 =>     7faea64f38f0 __printf_fp+0x0
    -> 79.369us END   _IO_file_xsputn
    681400/681400 2065408.180174951:   jmp                      7faea64f3908 __printf_fp+0x18 =>     7faea64f0db0 __GI___printf_fp_l+0x0
    681400/681400 2065408.180174985:   call                     7faea64f140a __GI___printf_fp_l+0x65a =>     7faea64ed020 __mpn_extract_double+0x0
    ->  79.39us BEGIN __printf_fp
    -> 79.407us END   __printf_fp
    -> 79.407us BEGIN __GI___printf_fp_l
    681400/681400 2065408.180175008:   return                   7faea64ed08d __mpn_extract_double+0x6d =>     7faea64f140f __GI___printf_fp_l+0x65f
    -> 79.424us BEGIN __mpn_extract_double
    681400/681400 2065408.180175022:   call                     7faea64f28a4 __GI___printf_fp_l+0x1af4 =>     7faea64ebb00 __mpn_lshift+0x0
    -> 79.447us END   __mpn_extract_double
    681400/681400 2065408.180175043:   return                   7faea64ebb5f __mpn_lshift+0x5f =>     7faea64f28a9 __GI___printf_fp_l+0x1af9
    -> 79.461us BEGIN __mpn_lshift
    681400/681400 2065408.180175059:   call                     7faea64f2f28 __GI___printf_fp_l+0x2178 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 79.482us END   __mpn_lshift
    681400/681400 2065408.180175075:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f2f2d __GI___printf_fp_l+0x217d
    -> 79.498us BEGIN __mpn_mul_1
    681400/681400 2065408.180175081:   call                     7faea64f34a1 __GI___printf_fp_l+0x26f1 =>     7faea64ebc20 __mpn_rshift+0x0
    -> 79.514us END   __mpn_mul_1
    681400/681400 2065408.180175087:   return                   7faea64ebcab __mpn_rshift+0x8b =>     7faea64f34a6 __GI___printf_fp_l+0x26f6
    ->  79.52us BEGIN __mpn_rshift
    681400/681400 2065408.180175108:   call                     7faea64f191e __GI___printf_fp_l+0xb6e =>     7faea6522a90 __libc_alloca_cutoff+0x0
    -> 79.526us END   __mpn_rshift
    681400/681400 2065408.180175111:   return                   7faea6522ad7 __libc_alloca_cutoff+0x47 =>     7faea64f1923 __GI___printf_fp_l+0xb73
    -> 79.547us BEGIN __libc_alloca_cutoff
    681400/681400 2065408.180175117:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    ->  79.55us END   __libc_alloca_cutoff
    681400/681400 2065408.180175117:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175122:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.556us BEGIN hack_digit
    -> 79.558us BEGIN __mpn_mul_1
    681400/681400 2065408.180175124:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.561us END   __mpn_mul_1
    681400/681400 2065408.180175124:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175124:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175130:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.563us END   hack_digit
    -> 79.563us BEGIN hack_digit
    -> 79.566us BEGIN __mpn_mul_1
    681400/681400 2065408.180175131:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.569us END   __mpn_mul_1
    681400/681400 2065408.180175131:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175131:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175136:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    ->  79.57us END   hack_digit
    ->  79.57us BEGIN hack_digit
    -> 79.572us BEGIN __mpn_mul_1
    681400/681400 2065408.180175137:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.575us END   __mpn_mul_1
    681400/681400 2065408.180175137:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175137:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175142:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.576us END   hack_digit
    -> 79.576us BEGIN hack_digit
    -> 79.578us BEGIN __mpn_mul_1
    681400/681400 2065408.180175143:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.581us END   __mpn_mul_1
    681400/681400 2065408.180175143:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175143:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175149:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.582us END   hack_digit
    -> 79.582us BEGIN hack_digit
    -> 79.585us BEGIN __mpn_mul_1
    681400/681400 2065408.180175150:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.588us END   __mpn_mul_1
    681400/681400 2065408.180175150:   call                     7faea64f1aa2 __GI___printf_fp_l+0xcf2 =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175150:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    681400/681400 2065408.180175154:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.589us END   hack_digit
    -> 79.589us BEGIN hack_digit
    -> 79.591us BEGIN __mpn_mul_1
    681400/681400 2065408.180175155:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1aa7 __GI___printf_fp_l+0xcf7
    -> 79.593us END   __mpn_mul_1
    681400/681400 2065408.180175155:   call                     7faea64f1dcc __GI___printf_fp_l+0x101c =>     7faea64f0950 hack_digit+0x0
    681400/681400 2065408.180175159:   call                     7faea64f0a44 hack_digit+0xf4 =>     7faea64ec1a0 __mpn_mul_1+0x0
    -> 79.594us END   hack_digit
    -> 79.594us BEGIN hack_digit
    681400/681400 2065408.180175162:   return                   7faea64ec2b8 __mpn_mul_1+0x118 =>     7faea64f0a49 hack_digit+0xf9
    -> 79.598us BEGIN __mpn_mul_1
    681400/681400 2065408.180175163:   return                   7faea64f0a5a hack_digit+0x10a =>     7faea64f1dd1 __GI___printf_fp_l+0x1021
    -> 79.601us END   __mpn_mul_1
    681400/681400 2065408.180175298:   call                     7faea64f21fb __GI___printf_fp_l+0x144b =>     7faea64c52c0 [unknown]
    -> 79.602us END   hack_digit
    681400/681400 2065408.180175396:   jmp                      7faea64c52c4 [unknown] =>     7faea6630d60 __strlen_evex+0x0
    -> 79.737us BEGIN [unknown]
    681400/681400 2065408.180175513:   return                   7faea6630d8f __strlen_evex+0x2f =>     7faea64f2200 __GI___printf_fp_l+0x1450
    -> 79.835us END   [unknown]
    -> 79.835us BEGIN __strlen_evex
    681400/681400 2065408.180175529:   call                     7faea64f2325 __GI___printf_fp_l+0x1575 =>     7faea662da40 __mempcpy_evex_unaligned_erms+0x0
    -> 79.952us END   __strlen_evex
    681400/681400 2065408.180175529:   jmp                      7faea662da4a __mempcpy_evex_unaligned_erms+0xa =>     7faea662da87 __memmove_evex_unaligned_erms+0x7
    681400/681400 2065408.180175532:   return                   7faea662dae5 __memmove_evex_unaligned_erms+0x65 =>     7faea64f232b __GI___printf_fp_l+0x157b
    -> 79.968us BEGIN __mempcpy_evex_unaligned_erms
    -> 79.969us END   __mempcpy_evex_unaligned_erms
    -> 79.969us BEGIN __memmove_evex_unaligned_erms
    681400/681400 2065408.180175567:   return                   7faea64f1349 __GI___printf_fp_l+0x599 =>     7faea650ad55 __vfprintf_internal+0x18d5
    -> 79.971us END   __memmove_evex_unaligned_erms
    681400/681400 2065408.180175571:   call                     7faea6509af9 __vfprintf_internal+0x679 =>     7faea6630240 __strchrnul_evex+0x0
    -> 80.006us END   __GI___printf_fp_l
    681400/681400 2065408.180175578:   return                   7faea663028a __strchrnul_evex+0x4a =>     7faea6509aff __vfprintf_internal+0x67f
    ->  80.01us BEGIN __strchrnul_evex
    681400/681400 2065408.180175579:   call                     7faea6509b35 __vfprintf_internal+0x6b5 =>     7faea651e5d0 _IO_file_xsputn+0x0
    -> 80.017us END   __strchrnul_evex
    681400/681400 2065408.180175580:   call                     7faea651e62a _IO_file_xsputn+0x5a =>     7faea662da40 __mempcpy_evex_unaligned_erms+0x0
    -> 80.018us BEGIN _IO_file_xsputn
    681400/681400 2065408.180175580:   jmp                      7faea662da4a __mempcpy_evex_unaligned_erms+0xa =>     7faea662da87 __memmove_evex_unaligned_erms+0x7
    681400/681400 2065408.180175581:   return                   7faea662dae5 __memmove_evex_unaligned_erms+0x65 =>     7faea651e630 _IO_file_xsputn+0x60
    -> 80.019us BEGIN __mempcpy_evex_unaligned_erms
    -> 80.019us END   __mempcpy_evex_unaligned_erms
    -> 80.019us BEGIN __memmove_evex_unaligned_erms
    681400/681400 2065408.180175582:   return                   7faea651e656 _IO_file_xsputn+0x86 =>     7faea6509b39 __vfprintf_internal+0x6b9
    ->  80.02us END   __memmove_evex_unaligned_erms
    681400/681400 2065408.180175589:   call                     7faea6509978 __vfprintf_internal+0x4f8 =>     7faea6523270 __GI___libc_cleanup_pop_restore+0x0
    -> 80.021us END   _IO_file_xsputn
    681400/681400 2065408.180175591:   return                   7faea6523291 __GI___libc_cleanup_pop_restore+0x21 =>     7faea650997d __vfprintf_internal+0x4fd
    -> 80.028us BEGIN __GI___libc_cleanup_pop_restore
    681400/681400 2065408.180175592:   return                   7faea65096dd __vfprintf_internal+0x25d =>     7faea64f679a fprintf+0x9a
    ->  80.03us END   __GI___libc_cleanup_pop_restore
    681400/681400 2065408.180175594:   return                   7faea64f67b1 fprintf+0xb1 =>     55cf38e4f29f main+0x106
    -> 80.031us END   __vfprintf_internal
    681400/681400 2065408.180175594:   call                     55cf38e4f2a6 main+0x10d =>     55cf38e4f090 dlclose@plt+0x0
    681400/681400 2065408.180175598:   jmp                      55cf38e4f090 dlclose@plt+0x0 =>     7faea6521f40 dlclose+0x0
    -> 80.033us END   fprintf
    -> 80.033us BEGIN dlclose@plt
    681400/681400 2065408.180175600:   call                     7faea6521f63 dlclose+0x23 =>     7faea65221c0 _dlerror_run+0x0
    -> 80.037us END   dlclose@plt
    -> 80.037us BEGIN dlclose
    681400/681400 2065408.180175605:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    -> 80.039us BEGIN _dlerror_run
    681400/681400 2065408.180175606:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 80.044us BEGIN _rtld_catch_error
    681400/681400 2065408.180175606:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180175609:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 80.045us END   _rtld_catch_error
    -> 80.045us BEGIN _dl_catch_error
    -> 80.046us BEGIN _dl_catch_exception
    681400/681400 2065408.180175613:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    -> 80.048us BEGIN __sigsetjmp
    681400/681400 2065408.180175614:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 80.052us END   __sigsetjmp
    -> 80.052us BEGIN __sigjmp_save
    681400/681400 2065408.180175615:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66bb020 _dl_close+0x0
    -> 80.053us END   __sigjmp_save
    681400/681400 2065408.180175615:   call                     7faea66bb038 _dl_close+0x18 =>     7faea65298a0 __pthread_mutex_lock+0x0
    681400/681400 2065408.180175620:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66bb03e _dl_close+0x1e
    -> 80.054us BEGIN _dl_close
    -> 80.056us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180175620:   call                     7faea66bb056 _dl_close+0x36 =>     7faea66ba240 _dl_close_worker+0x0
    681400/681400 2065408.180175686:   call                     7faea66ba567 _dl_close_worker+0x327 =>     7faea66ca220 _dl_sort_maps+0x0
    -> 80.059us END   __pthread_mutex_lock
    -> 80.059us BEGIN _dl_close_worker
    681400/681400 2065408.180175690:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    -> 80.125us BEGIN _dl_sort_maps
    -> 80.129us BEGIN dfs_traversal.part.0
    -> 80.137us BEGIN dfs_traversal.part.0
    -> 80.143us BEGIN dfs_traversal.part.0
    -> 80.145us END   dfs_traversal.part.0
    681400/681400 2065408.180175711:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 80.146us END   dfs_traversal.part.0
    681400/681400 2065408.180175712:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    ->  80.15us END   dfs_traversal.part.0
    681400/681400 2065408.180175715:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 80.151us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180175715:   call                     7faea66ca588 _dl_sort_maps+0x368 =>     7faea66ca110 dfs_traversal.part.0+0x0
    681400/681400 2065408.180175723:   return                   7faea66ca17a dfs_traversal.part.0+0x6a =>     7faea66ca58d _dl_sort_maps+0x36d
    -> 80.154us END   dfs_traversal.part.0
    -> 80.154us BEGIN dfs_traversal.part.0
    681400/681400 2065408.180175723:   call                     7faea66ca674 _dl_sort_maps+0x454 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180175728:   return                   7faea66e025c memcpy+0x8c =>     7faea66ca67a _dl_sort_maps+0x45a
    -> 80.162us END   dfs_traversal.part.0
    -> 80.162us BEGIN memcpy
    681400/681400 2065408.180175729:   return                   7faea66ca36e _dl_sort_maps+0x14e =>     7faea66ba56c _dl_close_worker+0x32c
    -> 80.167us END   memcpy
    681400/681400 2065408.180175735:   call                     7faea66ba5e1 _dl_close_worker+0x3a1 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 80.168us END   _dl_sort_maps
    681400/681400 2065408.180175736:   call                     7faea65f3e73 _dl_catch_exception+0xe3 =>     7faea66ba090 call_destructors+0x0
    -> 80.174us BEGIN _dl_catch_exception
    681400/681400 2065408.180175748:   call                     7faea66ba0d0 call_destructors+0x40 =>     7faea63be4d0 __do_global_dtors_aux+0x0
    -> 80.175us BEGIN call_destructors
    681400/681400 2065408.180175749:   call                     7faea63be4f2 __do_global_dtors_aux+0x22 =>     7faea64de040 __cxa_finalize+0x0
    -> 80.187us BEGIN __do_global_dtors_aux
    681400/681400 2065408.180175767:   call                     7faea64de194 __cxa_finalize+0x154 =>     7faea6576e60 __unregister_atfork+0x0
    -> 80.188us BEGIN __cxa_finalize
    681400/681400 2065408.180175789:   return                   7faea6576f59 __unregister_atfork+0xf9 =>     7faea64de199 __cxa_finalize+0x159
    -> 80.206us BEGIN __unregister_atfork
    681400/681400 2065408.180175794:   return                   7faea64de1b1 __cxa_finalize+0x171 =>     7faea63be4f8 __do_global_dtors_aux+0x28
    -> 80.228us END   __unregister_atfork
    681400/681400 2065408.180175794:   call                     7faea63be4f8 __do_global_dtors_aux+0x28 =>     7faea63be460 deregister_tm_clones+0x0
    681400/681400 2065408.180175795:   return                   7faea63be488 deregister_tm_clones+0x28 =>     7faea63be4fd __do_global_dtors_aux+0x2d
    -> 80.233us END   __cxa_finalize
    -> 80.233us BEGIN deregister_tm_clones
    681400/681400 2065408.180175795:   return                   7faea63be505 __do_global_dtors_aux+0x35 =>     7faea66ba0d2 call_destructors+0x42
    681400/681400 2065408.180175796:   jmp                      7faea66ba0f7 call_destructors+0x67 =>     7faea6437e18 _fini+0x0
    -> 80.234us END   deregister_tm_clones
    -> 80.234us END   __do_global_dtors_aux
    681400/681400 2065408.180175982:   hw int                   7faea6437e18 _fini+0x0 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 80.235us END   call_destructors
    -> 80.235us BEGIN _fini
    681400/681400 2065408.180176915:   tr strt                             0 [unknown] =>     7faea6437e18 _fini+0x0
    -> 80.421us BEGIN asm_exc_page_fault
    681400/681400 2065408.180176940:   return                   7faea6437e24 _fini+0xc =>     7faea65f3e75 _dl_catch_exception+0xe5
    -> 81.354us END   asm_exc_page_fault
    681400/681400 2065408.180176941:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea66ba5e7 _dl_close_worker+0x3a7
    681400/681400 2065408.180176941:   call                     7faea66ba5ea _dl_close_worker+0x3aa =>     7faea66d0fa0 _dl_audit_objclose+0x0
    681400/681400 2065408.180177055:   return                   7faea66d0fae _dl_audit_objclose+0xe =>     7faea66ba5ef _dl_close_worker+0x3af
    ->  81.38us END   _dl_catch_exception
    ->  81.38us BEGIN _dl_audit_objclose
    681400/681400 2065408.180177059:   call                     7faea66ba956 _dl_close_worker+0x716 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    -> 81.494us END   _dl_audit_objclose
    681400/681400 2065408.180177061:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66ba95b _dl_close_worker+0x71b
    -> 81.498us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180177061:   call                     7faea66ba95e _dl_close_worker+0x71e =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180177065:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66ba963 _dl_close_worker+0x723
    ->   81.5us END   _dl_audit_activity_nsid
    ->   81.5us BEGIN _dl_debug_update
    681400/681400 2065408.180177065:   call                     7faea66ba971 _dl_close_worker+0x731 =>     7faea66bb090 _dl_debug_state+0x0
    681400/681400 2065408.180177066:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66ba976 _dl_close_worker+0x736
    -> 81.504us END   _dl_debug_update
    -> 81.504us BEGIN _dl_debug_state
    681400/681400 2065408.180177066:   call                     7faea66ba9c0 _dl_close_worker+0x780 =>     7faea65298a0 __pthread_mutex_lock+0x0
    681400/681400 2065408.180177073:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66ba9c6 _dl_close_worker+0x786
    -> 81.505us END   _dl_debug_state
    -> 81.505us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180177076:   call                     7faea66ba9cd _dl_close_worker+0x78d =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 81.512us END   __pthread_mutex_lock
    681400/681400 2065408.180177078:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66ba9d3 _dl_close_worker+0x793
    -> 81.515us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180177078:   call                     7faea66baa6f _dl_close_worker+0x82f =>     7faea66ce550 _dl_unmap+0x0
    681400/681400 2065408.180177078:   call                     7faea66ce56c _dl_unmap+0x1c =>     7faea66dbf10 __munmap+0x0
    681400/681400 2065408.180177097:   syscall                  7faea66dbf19 __munmap+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 81.517us END   __pthread_mutex_lock
    -> 81.517us BEGIN _dl_unmap
    -> 81.526us BEGIN __munmap
    681400/681400 2065408.180179031:   tr strt                             0 [unknown] => ffffffffad87b5c3 unmap_page_range+0x663
    -> 81.536us BEGIN __entry_text_start
    681400/681400 2065408.180183989:   tr strt                             0 [unknown] => ffffffffad67b158 flush_tlb_func+0xc8
    ->  83.47us END   __entry_text_start
    681400/681400 2065408.180186683:   tr strt                             0 [unknown] =>     7faea66dbf1b __munmap+0xb
    -> 88.428us BEGIN flush_tlb_func
    681400/681400 2065408.180186714:   return                   7faea66dbf23 __munmap+0x13 =>     7faea66ce571 _dl_unmap+0x21
    -> 91.122us END   flush_tlb_func
    681400/681400 2065408.180186728:   return                   7faea66ce5c4 _dl_unmap+0x74 =>     7faea66baa74 _dl_close_worker+0x834
    681400/681400 2065408.180186756:   call                     7faea66baa9a _dl_close_worker+0x85a =>     7faea66bd940 _dl_find_object_dlclose+0x0
    -> 91.167us END   _dl_unmap
    681400/681400 2065408.180186777:   return                   7faea66bd9bf _dl_find_object_dlclose+0x7f =>     7faea66baa9f _dl_close_worker+0x85f
    -> 91.195us BEGIN _dl_find_object_dlclose
    681400/681400 2065408.180186784:   call                     7faea66baaa6 _dl_close_worker+0x866 =>     7faea6536b70 __libc_free+0x0
    -> 91.216us END   _dl_find_object_dlclose
    681400/681400 2065408.180186819:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    -> 91.223us BEGIN __libc_free
    681400/681400 2065408.180186952:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 91.258us BEGIN _int_free
    681400/681400 2065408.180186953:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baaac _dl_close_worker+0x86c
    -> 91.391us END   _int_free
    681400/681400 2065408.180186953:   call                     7faea66baab9 _dl_close_worker+0x879 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180186968:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    -> 91.392us END   __libc_free
    -> 91.392us BEGIN __libc_free
    681400/681400 2065408.180186978:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 91.407us BEGIN _int_free
    681400/681400 2065408.180186979:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baabf _dl_close_worker+0x87f
    -> 91.417us END   _int_free
    681400/681400 2065408.180186979:   call                     7faea66baac6 _dl_close_worker+0x886 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180186980:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66baacc _dl_close_worker+0x88c
    -> 91.418us END   __libc_free
    -> 91.418us BEGIN __libc_free
    681400/681400 2065408.180186980:   call                     7faea66baadd _dl_close_worker+0x89d =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180186980:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180186985:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 91.419us END   __libc_free
    -> 91.419us BEGIN __libc_free
    -> 91.421us BEGIN _int_free
    681400/681400 2065408.180186985:   return                   7faea6536bec __libc_free+0x7c =>     7faea66baae3 _dl_close_worker+0x8a3
    681400/681400 2065408.180186987:   call                     7faea66bab10 _dl_close_worker+0x8d0 =>     7faea6536b70 __libc_free+0x0
    -> 91.424us END   _int_free
    -> 91.424us END   __libc_free
    681400/681400 2065408.180186987:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180186993:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 91.426us BEGIN __libc_free
    -> 91.429us BEGIN _int_free
    681400/681400 2065408.180186993:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bab16 _dl_close_worker+0x8d6
    681400/681400 2065408.180186996:   call                     7faea66bab53 _dl_close_worker+0x913 =>     7faea6536b70 __libc_free+0x0
    -> 91.432us END   _int_free
    -> 91.432us END   __libc_free
    681400/681400 2065408.180186996:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66bab59 _dl_close_worker+0x919
    681400/681400 2065408.180186998:   call                     7faea66bab66 _dl_close_worker+0x926 =>     7faea6536b70 __libc_free+0x0
    -> 91.435us BEGIN __libc_free
    -> 91.437us END   __libc_free
    681400/681400 2065408.180186999:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66bab6c _dl_close_worker+0x92c
    -> 91.437us BEGIN __libc_free
    681400/681400 2065408.180186999:   call                     7faea66bab7c _dl_close_worker+0x93c =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180186999:   call                     7faea6536bde __libc_free+0x6e =>     7faea6533c60 _int_free+0x0
    681400/681400 2065408.180187011:   return                   7faea6533dca _int_free+0x16a =>     7faea6536be3 __libc_free+0x73
    -> 91.438us END   __libc_free
    -> 91.438us BEGIN __libc_free
    -> 91.444us BEGIN _int_free
    681400/681400 2065408.180187012:   return                   7faea6536bec __libc_free+0x7c =>     7faea66bab82 _dl_close_worker+0x942
    ->  91.45us END   _int_free
    681400/681400 2065408.180187024:   call                     7faea66bab9a _dl_close_worker+0x95a =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 91.451us END   __libc_free
    681400/681400 2065408.180187024:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180187037:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66baba0 _dl_close_worker+0x960
    -> 91.463us BEGIN __pthread_mutex_unlock
    -> 91.469us END   __pthread_mutex_unlock
    -> 91.469us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180187037:   call                     7faea66babdd _dl_close_worker+0x99d =>     7faea652b430 __pthread_mutex_unlock+0x0
    681400/681400 2065408.180187037:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180187048:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea66babe3 _dl_close_worker+0x9a3
    -> 91.476us END   __pthread_mutex_unlock_usercnt
    -> 91.476us BEGIN __pthread_mutex_unlock
    -> 91.481us END   __pthread_mutex_unlock
    -> 91.481us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180187048:   call                     7faea66babe8 _dl_close_worker+0x9a8 =>     7faea66d0de0 _dl_audit_activity_nsid+0x0
    681400/681400 2065408.180187060:   return                   7faea66d0e06 _dl_audit_activity_nsid+0x26 =>     7faea66babed _dl_close_worker+0x9ad
    -> 91.487us END   __pthread_mutex_unlock_usercnt
    -> 91.487us BEGIN _dl_audit_activity_nsid
    681400/681400 2065408.180187061:   call                     7faea66bac06 _dl_close_worker+0x9c6 =>     7faea66bb090 _dl_debug_state+0x0
    -> 91.499us END   _dl_audit_activity_nsid
    681400/681400 2065408.180187066:   return                   7faea66bb094 _dl_debug_state+0x4 =>     7faea66bac0b _dl_close_worker+0x9cb
    ->   91.5us BEGIN _dl_debug_state
    681400/681400 2065408.180187187:   return                   7faea66ba486 _dl_close_worker+0x246 =>     7faea66bb05b _dl_close+0x3b
    -> 91.505us END   _dl_debug_state
    681400/681400 2065408.180187195:   jmp                      7faea66bb065 _dl_close+0x45 =>     7faea652b430 __pthread_mutex_unlock+0x0
    -> 91.626us END   _dl_close_worker
    681400/681400 2065408.180187195:   jmp                      7faea652b439 __pthread_mutex_unlock+0x9 =>     7faea652b310 __pthread_mutex_unlock_usercnt+0x0
    681400/681400 2065408.180187201:   return                   7faea652b354 __pthread_mutex_unlock_usercnt+0x44 =>     7faea65f3e18 _dl_catch_exception+0x88
    -> 91.634us END   _dl_close
    -> 91.634us BEGIN __pthread_mutex_unlock
    -> 91.637us END   __pthread_mutex_unlock
    -> 91.637us BEGIN __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180187372:   return                   7faea65f3e5a _dl_catch_exception+0xca =>     7faea65f3ee3 _dl_catch_error+0x33
    ->  91.64us END   __pthread_mutex_unlock_usercnt
    681400/681400 2065408.180187389:   return                   7faea65f3f14 _dl_catch_error+0x64 =>     7faea652224e _dlerror_run+0x8e
    -> 91.811us END   _dl_catch_exception
    681400/681400 2065408.180187420:   return                   7faea65222d2 _dlerror_run+0x112 =>     7faea6521f68 dlclose+0x28
    -> 91.828us END   _dl_catch_error
    681400/681400 2065408.180187441:   return                   7faea6521f70 dlclose+0x30 =>     55cf38e4f2ab main+0x112
    -> 91.859us END   _dlerror_run
    681400/681400 2065408.180187441:   call                     55cf38e4f1cd main+0x34 =>     55cf38e4f040 dlopen@plt+0x0
    681400/681400 2065408.180187494:   jmp                      55cf38e4f040 dlopen@plt+0x0 =>     7faea6522790 dlopen+0x0
    ->  91.88us END   dlclose
    ->  91.88us BEGIN dlopen@plt
    681400/681400 2065408.180187494:   call                     7faea65227d3 dlopen+0x43 =>     7faea65221c0 _dlerror_run+0x0
    681400/681400 2065408.180187500:   call                     7faea6522246 _dlerror_run+0x86 =>     7faea66d2d10 _rtld_catch_error+0x0
    -> 91.933us END   dlopen@plt
    -> 91.933us BEGIN dlopen
    -> 91.936us BEGIN _dlerror_run
    681400/681400 2065408.180187615:   jmp                      7faea66d2d14 _rtld_catch_error+0x4 =>     7faea65f3eb0 _dl_catch_error+0x0
    -> 91.939us BEGIN _rtld_catch_error
    681400/681400 2065408.180187615:   call                     7faea65f3ede _dl_catch_error+0x2e =>     7faea65f3d90 _dl_catch_exception+0x0
    681400/681400 2065408.180187617:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 92.054us END   _rtld_catch_error
    -> 92.054us BEGIN _dl_catch_error
    -> 92.055us BEGIN _dl_catch_exception
    681400/681400 2065408.180187617:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180187632:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 92.056us BEGIN __sigsetjmp
    -> 92.063us END   __sigsetjmp
    -> 92.063us BEGIN __sigjmp_save
    681400/681400 2065408.180187632:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea65226f0 dlopen_doit+0x0
    681400/681400 2065408.180187748:   call                     7faea652274a dlopen_doit+0x5a =>     7faea66c50b0 _dl_open+0x0
    -> 92.071us END   __sigjmp_save
    -> 92.071us BEGIN dlopen_doit
    681400/681400 2065408.180187750:   call                     7faea66c50ec _dl_open+0x3c =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 92.187us BEGIN _dl_open
    681400/681400 2065408.180187753:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c50f2 _dl_open+0x42
    -> 92.189us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180187754:   call                     7faea66c5157 _dl_open+0xa7 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 92.192us END   __pthread_mutex_lock
    681400/681400 2065408.180187754:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    681400/681400 2065408.180187754:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    681400/681400 2065408.180187758:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 92.193us BEGIN _dl_catch_exception
    -> 92.194us BEGIN __sigsetjmp
    -> 92.195us END   __sigsetjmp
    -> 92.195us BEGIN __sigjmp_save
    681400/681400 2065408.180187758:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66c4d40 dl_open_worker+0x0
    681400/681400 2065408.180187759:   call                     7faea66c4d5f dl_open_worker+0x1f =>     7faea65298a0 __pthread_mutex_lock+0x0
    -> 92.197us END   __sigjmp_save
    -> 92.197us BEGIN dl_open_worker
    681400/681400 2065408.180187762:   return                   7faea652991c __pthread_mutex_lock+0x7c =>     7faea66c4d65 dl_open_worker+0x25
    -> 92.198us BEGIN __pthread_mutex_lock
    681400/681400 2065408.180187763:   call                     7faea66c4d75 dl_open_worker+0x35 =>     7faea65f3d90 _dl_catch_exception+0x0
    -> 92.201us END   __pthread_mutex_lock
    681400/681400 2065408.180187764:   call                     7faea65f3dfc _dl_catch_exception+0x6c =>     7faea64db150 __sigsetjmp+0x0
    -> 92.202us BEGIN _dl_catch_exception
    681400/681400 2065408.180187774:   jmp                      7faea64db1be __sigsetjmp+0x6e =>     7faea64db1d0 __sigjmp_save+0x0
    -> 92.203us BEGIN __sigsetjmp
    681400/681400 2065408.180187775:   return                   7faea64db1e2 __sigjmp_save+0x12 =>     7faea65f3e01 _dl_catch_exception+0x71
    -> 92.213us END   __sigsetjmp
    -> 92.213us BEGIN __sigjmp_save
    681400/681400 2065408.180187776:   call                     7faea65f3e16 _dl_catch_exception+0x86 =>     7faea66c5510 dl_open_worker_begin+0x0
    -> 92.214us END   __sigjmp_save
    681400/681400 2065408.180187776:   call                     7faea66c5534 dl_open_worker_begin+0x24 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180187788:   return                   7faea66dfa8a strchr+0x5a =>     7faea66c5539 dl_open_worker_begin+0x29
    -> 92.215us BEGIN dl_open_worker_begin
    -> 92.221us BEGIN strchr
    681400/681400 2065408.180187788:   call                     7faea66c554d dl_open_worker_begin+0x3d =>     7faea66c4fe0 _dl_find_dso_for_object+0x0
    681400/681400 2065408.180187793:   return                   7faea66c5084 _dl_find_dso_for_object+0xa4 =>     7faea66c5552 dl_open_worker_begin+0x42
    -> 92.227us END   strchr
    -> 92.227us BEGIN _dl_find_dso_for_object
    681400/681400 2065408.180187793:   call                     7faea66c5594 dl_open_worker_begin+0x84 =>     7faea66bb0f0 _dl_debug_initialize+0x0
    681400/681400 2065408.180187800:   return                   7faea66bb159 _dl_debug_initialize+0x69 =>     7faea66c5599 dl_open_worker_begin+0x89
    -> 92.232us END   _dl_find_dso_for_object
    -> 92.232us BEGIN _dl_debug_initialize
    681400/681400 2065408.180187800:   call                     7faea66c55b4 dl_open_worker_begin+0xa4 =>     7faea66c15b0 _dl_map_object+0x0
    681400/681400 2065408.180187809:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 92.239us END   _dl_debug_initialize
    -> 92.239us BEGIN _dl_map_object
    681400/681400 2065408.180187809:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187825:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 92.248us BEGIN _dl_name_match_p
    -> 92.256us BEGIN strcmp
    681400/681400 2065408.180187825:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187834:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 92.264us END   strcmp
    -> 92.264us BEGIN strcmp
    681400/681400 2065408.180187835:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 92.273us END   strcmp
    681400/681400 2065408.180187835:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180187835:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187860:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 92.274us END   _dl_name_match_p
    -> 92.274us BEGIN _dl_name_match_p
    -> 92.286us BEGIN strcmp
    681400/681400 2065408.180187860:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187866:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 92.299us END   strcmp
    -> 92.299us BEGIN strcmp
    681400/681400 2065408.180187868:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 92.305us END   strcmp
    681400/681400 2065408.180187868:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187875:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 92.307us END   _dl_name_match_p
    -> 92.307us BEGIN strcmp
    681400/681400 2065408.180187876:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    -> 92.314us END   strcmp
    681400/681400 2065408.180187876:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187879:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 92.315us BEGIN _dl_name_match_p
    -> 92.316us BEGIN strcmp
    681400/681400 2065408.180187879:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187886:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 92.318us END   strcmp
    -> 92.318us BEGIN strcmp
    681400/681400 2065408.180187888:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 92.325us END   strcmp
    681400/681400 2065408.180187888:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187903:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 92.327us END   _dl_name_match_p
    -> 92.327us BEGIN strcmp
    681400/681400 2065408.180187903:   call                     7faea66c1646 _dl_map_object+0x96 =>     7faea66c44e0 _dl_name_match_p+0x0
    681400/681400 2065408.180187903:   call                     7faea66c44f4 _dl_name_match_p+0x14 =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187906:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c44f9 _dl_name_match_p+0x19
    -> 92.342us END   strcmp
    -> 92.342us BEGIN _dl_name_match_p
    -> 92.343us BEGIN strcmp
    681400/681400 2065408.180187906:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187907:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 92.345us END   strcmp
    -> 92.345us BEGIN strcmp
    681400/681400 2065408.180187907:   call                     7faea66c451f _dl_name_match_p+0x3f =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187914:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c4524 _dl_name_match_p+0x44
    -> 92.346us END   strcmp
    -> 92.346us BEGIN strcmp
    681400/681400 2065408.180187916:   return                   7faea66c4540 _dl_name_match_p+0x60 =>     7faea66c164b _dl_map_object+0x9b
    -> 92.353us END   strcmp
    681400/681400 2065408.180187916:   call                     7faea66c168d _dl_map_object+0xdd =>     7faea66dc440 strcmp+0x0
    681400/681400 2065408.180187918:   return                   7faea66dd86e strcmp+0x142e =>     7faea66c1692 _dl_map_object+0xe2
    -> 92.355us END   _dl_name_match_p
    -> 92.355us BEGIN strcmp
    681400/681400 2065408.180187918:   call                     7faea66c1713 _dl_map_object+0x163 =>     7faea66dfa30 strchr+0x0
    681400/681400 2065408.180187922:   return                   7faea66dfa8a strchr+0x5a =>     7faea66c1718 _dl_map_object+0x168
    -> 92.357us END   strcmp
    -> 92.357us BEGIN strchr
    681400/681400 2065408.180187924:   call                     7faea66c17eb _dl_map_object+0x23b =>     7faea66dfc60 strlen+0x0
    -> 92.361us END   strchr
    681400/681400 2065408.180187925:   return                   7faea66dfc9d strlen+0x3d =>     7faea66c17f0 _dl_map_object+0x240
    -> 92.363us BEGIN strlen
    681400/681400 2065408.180187925:   call                     7faea66c1a3b _dl_map_object+0x48b =>     7faea66bf9c0 cache_rpath+0x0
    681400/681400 2065408.180187939:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1a40 _dl_map_object+0x490
    -> 92.364us END   strlen
    -> 92.364us BEGIN cache_rpath
    681400/681400 2065408.180187939:   call                     7faea66c1b44 _dl_map_object+0x594 =>     7faea66bf9c0 cache_rpath+0x0
    681400/681400 2065408.180187948:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1b49 _dl_map_object+0x599
    -> 92.378us END   cache_rpath
    -> 92.378us BEGIN cache_rpath
    681400/681400 2065408.180187956:   call                     7faea66c188b _dl_map_object+0x2db =>     7faea66bf9c0 cache_rpath+0x0
    -> 92.387us END   cache_rpath
    681400/681400 2065408.180187957:   return                   7faea66bfa1e cache_rpath+0x5e =>     7faea66c1890 _dl_map_object+0x2e0
    -> 92.395us BEGIN cache_rpath
    681400/681400 2065408.180187957:   call                     7faea66c18c0 _dl_map_object+0x310 =>     7faea66cd670 _dl_load_cache_lookup+0x0
    681400/681400 2065408.180187957:   call                     7faea66cd7df _dl_load_cache_lookup+0x16f =>     7faea66c4450 _dl_sysdep_read_whole_file+0x0
    681400/681400 2065408.180187957:   call                     7faea66c4475 _dl_sysdep_read_whole_file+0x25 =>     7faea66dbd00 __open64_nocancel+0x0
    681400/681400 2065408.180187986:   syscall                  7faea66dbd36 __open64_nocancel+0x36 => ffffffffae200000 __entry_text_start+0x0
    -> 92.396us END   cache_rpath
    -> 92.396us BEGIN _dl_load_cache_lookup
    -> 92.405us BEGIN _dl_sysdep_read_whole_file
    -> 92.415us BEGIN __open64_nocancel
    681400/681400 2065408.180189084:   tr strt                             0 [unknown] =>     7faea66dbd38 __open64_nocancel+0x38
    -> 92.425us BEGIN __entry_text_start
    681400/681400 2065408.180189089:   return                   7faea66dbd40 __open64_nocancel+0x40 =>     7faea66c447a _dl_sysdep_read_whole_file+0x2a
    -> 93.523us END   __entry_text_start
    681400/681400 2065408.180189093:   call                     7faea66c4497 _dl_sysdep_read_whole_file+0x47 =>     7faea66dbaa0 __fstat+0x0
    681400/681400 2065408.180189093:   jmp                      7faea66dbab7 __fstat+0x17 =>     7faea66dbaf0 __GI___fstatat64+0x0
    681400/681400 2065408.180189111:   syscall                  7faea66dbafc __GI___fstatat64+0xc => ffffffffae200000 __entry_text_start+0x0
    -> 93.532us BEGIN __fstat
    -> 93.541us END   __fstat
    -> 93.541us BEGIN __GI___fstatat64
    681400/681400 2065408.180189702:   tr strt                             0 [unknown] =>     7faea66dbafe __GI___fstatat64+0xe
    ->  93.55us BEGIN __entry_text_start
    681400/681400 2065408.180189706:   return                   7faea66dbb07 __GI___fstatat64+0x17 =>     7faea66c449c _dl_sysdep_read_whole_file+0x4c
    -> 94.141us END   __entry_text_start
    681400/681400 2065408.180189711:   call                     7faea66c44d0 _dl_sysdep_read_whole_file+0x80 =>     7faea66dbec0 mmap64+0x0
    681400/681400 2065408.180189729:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    ->  94.15us BEGIN mmap64
    681400/681400 2065408.180190829:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 94.168us BEGIN __entry_text_start
    681400/681400 2065408.180190833:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c44d5 _dl_sysdep_read_whole_file+0x85
    -> 95.268us END   __entry_text_start
    681400/681400 2065408.180190833:   call                     7faea66c44b6 _dl_sysdep_read_whole_file+0x66 =>     7faea66dbbf0 __GI___close_nocancel+0x0
    681400/681400 2065408.180190848:   syscall                  7faea66dbbf9 __GI___close_nocancel+0x9 => ffffffffae200000 __entry_text_start+0x0
    -> 95.272us BEGIN __GI___close_nocancel
    681400/681400 2065408.180191103:   tr strt                             0 [unknown] =>     7faea66dbbfb __GI___close_nocancel+0xb
    -> 95.287us BEGIN __entry_text_start
    681400/681400 2065408.180191104:   return                   7faea66dbc03 __GI___close_nocancel+0x13 =>     7faea66c44bb _dl_sysdep_read_whole_file+0x6b
    -> 95.542us END   __entry_text_start
    681400/681400 2065408.180191109:   return                   7faea66c448e _dl_sysdep_read_whole_file+0x3e =>     7faea66cd7e4 _dl_load_cache_lookup+0x174
    681400/681400 2065408.180191279:   hw int                   7faea66cd808 _dl_load_cache_lookup+0x198 => ffffffffae200ab0 asm_exc_page_fault+0x0
    -> 95.548us END   _dl_sysdep_read_whole_file
    681400/681400 2065408.180192556:   tr strt                             0 [unknown] => ffffffffad892313 page_add_file_rmap+0x13
    -> 95.718us BEGIN asm_exc_page_fault
    681400/681400 2065408.180192932:   tr strt                             0 [unknown] =>     7faea66cd808 _dl_load_cache_lookup+0x198
    -> 96.995us END   asm_exc_page_fault
    681400/681400 2065408.180192956:   call                     7faea66cd6d1 _dl_load_cache_lookup+0x61 =>     7faea66ccf90 search_cache+0x0
    -> 97.371us BEGIN _dl_load_cache_lookup
    681400/681400 2065408.180192972:   call                     7faea66ccfd2 search_cache+0x42 =>     7faea66dc440 strcmp+0x0
    -> 97.395us BEGIN search_cache
    681400/681400 2065408.180192983:   return                   7faea66dd86e strcmp+0x142e =>     7faea66ccfd7 search_cache+0x47
    -> 97.411us BEGIN strcmp
    681400/681400 2065408.180192984:   call                     7faea66cd029 search_cache+0x99 =>     7faea66ce230 __tunable_get_val+0x0
    -> 97.422us END   strcmp
    681400/681400 2065408.180192989:   return                   7faea66ce290 __tunable_get_val+0x60 =>     7faea66cd02e search_cache+0x9e
    -> 97.423us BEGIN __tunable_get_val
    681400/681400 2065408.180192991:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    -> 97.428us END   __tunable_get_val
    681400/681400 2065408.180193010:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    ->  97.43us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193010:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193023:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.449us END   _dl_cache_libcmp
    -> 97.449us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193023:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193034:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.462us END   _dl_cache_libcmp
    -> 97.462us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193034:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193042:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.473us END   _dl_cache_libcmp
    -> 97.473us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193042:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193045:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.481us END   _dl_cache_libcmp
    -> 97.481us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193045:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193061:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.484us END   _dl_cache_libcmp
    -> 97.484us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193061:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193067:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    ->   97.5us END   _dl_cache_libcmp
    ->   97.5us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193067:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193079:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.506us END   _dl_cache_libcmp
    -> 97.506us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193079:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193200:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd090 search_cache+0x100
    -> 97.518us END   _dl_cache_libcmp
    -> 97.518us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193200:   call                     7faea66cd08b search_cache+0xfb =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193221:   return                   7faea66ccef5 _dl_cache_libcmp+0x45 =>     7faea66cd090 search_cache+0x100
    -> 97.639us END   _dl_cache_libcmp
    -> 97.639us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193221:   call                     7faea66cd106 search_cache+0x176 =>     7faea66cceb0 _dl_cache_libcmp+0x0
    681400/681400 2065408.180193235:   return                   7faea66ccf7f _dl_cache_libcmp+0xcf =>     7faea66cd10b search_cache+0x17b
    ->  97.66us END   _dl_cache_libcmp
    ->  97.66us BEGIN _dl_cache_libcmp
    681400/681400 2065408.180193244:   return                   7faea66cd0bf search_cache+0x12f =>     7faea66cd6d6 _dl_load_cache_lookup+0x66
    -> 97.674us END   _dl_cache_libcmp
    681400/681400 2065408.180193244:   call                     7faea66cd6f2 _dl_load_cache_lookup+0x82 =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180193250:   return                   7faea66dfce6 strlen+0x86 =>     7faea66cd6f7 _dl_load_cache_lookup+0x87
    -> 97.683us END   search_cache
    -> 97.683us BEGIN strlen
    681400/681400 2065408.180193251:   call                     7faea66cd74b _dl_load_cache_lookup+0xdb =>     7faea66e01d0 memcpy+0x0
    -> 97.689us END   strlen
    681400/681400 2065408.180193264:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66cd751 _dl_load_cache_lookup+0xe1
    ->  97.69us BEGIN memcpy
    681400/681400 2065408.180193264:   call                     7faea66cd754 _dl_load_cache_lookup+0xe4 =>     7faea66dc3e0 strdup+0x0
    681400/681400 2065408.180193264:   call                     7faea66dc3ee strdup+0xe =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180193273:   return                   7faea66dfce6 strlen+0x86 =>     7faea66dc3f3 strdup+0x13
    -> 97.703us END   memcpy
    -> 97.703us BEGIN strdup
    -> 97.707us BEGIN strlen
    681400/681400 2065408.180193274:   call                     7faea66dc3fa strdup+0x1a =>     7faea6536590 __libc_malloc+0x0
    -> 97.712us END   strlen
    681400/681400 2065408.180193295:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66dc400 strdup+0x20
    -> 97.713us BEGIN __libc_malloc
    681400/681400 2065408.180193295:   jmp                      7faea66dc415 strdup+0x35 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180193296:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66cd759 _dl_load_cache_lookup+0xe9
    -> 97.734us END   __libc_malloc
    -> 97.734us END   strdup
    -> 97.734us BEGIN memcpy
    681400/681400 2065408.180193297:   return                   7faea66cd75e _dl_load_cache_lookup+0xee =>     7faea66c18c5 _dl_map_object+0x315
    -> 97.735us END   memcpy
    681400/681400 2065408.180193303:   call                     7faea66c1905 _dl_map_object+0x355 =>     7faea66be290 open_verify.constprop.0+0x0
    -> 97.736us END   _dl_load_cache_lookup
    681400/681400 2065408.180193320:   call                     7faea66be2c8 open_verify.constprop.0+0x38 =>     7faea66dbd00 __open64_nocancel+0x0
    -> 97.742us BEGIN open_verify.constprop.0
    681400/681400 2065408.180193333:   syscall                  7faea66dbd36 __open64_nocancel+0x36 => ffffffffae200000 __entry_text_start+0x0
    -> 97.759us BEGIN __open64_nocancel
    681400/681400 2065408.180194277:   tr strt                             0 [unknown] =>     7faea66dbd38 __open64_nocancel+0x38
    -> 97.772us BEGIN __entry_text_start
    681400/681400 2065408.180194280:   return                   7faea66dbd40 __open64_nocancel+0x40 =>     7faea66be2cd open_verify.constprop.0+0x3d
    -> 98.716us END   __entry_text_start
    681400/681400 2065408.180194282:   call                     7faea66be30c open_verify.constprop.0+0x7c =>     7faea66dbd80 __GI___read_nocancel+0x0
    681400/681400 2065408.180194297:   syscall                  7faea66dbd86 __GI___read_nocancel+0x6 => ffffffffae200000 __entry_text_start+0x0
    -> 98.721us BEGIN __GI___read_nocancel
    681400/681400 2065408.180194800:   tr strt                             0 [unknown] =>     7faea66dbd88 __GI___read_nocancel+0x8
    -> 98.736us BEGIN __entry_text_start
    681400/681400 2065408.180194802:   return                   7faea66dbd90 __GI___read_nocancel+0x10 =>     7faea66be311 open_verify.constprop.0+0x81
    -> 99.239us END   __entry_text_start
    681400/681400 2065408.180194848:   call                     7faea66be3a5 open_verify.constprop.0+0x115 =>     7faea6536b70 __libc_free+0x0
    681400/681400 2065408.180194858:   return                   7faea6536c38 __libc_free+0xc8 =>     7faea66be3ab open_verify.constprop.0+0x11b
    -> 99.287us BEGIN __libc_free
    681400/681400 2065408.180194859:   return                   7faea66be3bc open_verify.constprop.0+0x12c =>     7faea66c190a _dl_map_object+0x35a
    -> 99.297us END   __libc_free
    681400/681400 2065408.180194859:   call                     7faea66c17a7 _dl_map_object+0x1f7 =>     7faea66bfe20 _dl_map_object_from_fd+0x0
    681400/681400 2065408.180194859:   call                     7faea66bfe5d _dl_map_object_from_fd+0x3d =>     7faea66bb0a0 _dl_debug_update+0x0
    681400/681400 2065408.180194872:   return                   7faea66bb0cb _dl_debug_update+0x2b =>     7faea66bfe62 _dl_map_object_from_fd+0x42
    -> 99.298us END   open_verify.constprop.0
    -> 99.298us BEGIN _dl_map_object_from_fd
    -> 99.304us BEGIN _dl_debug_update
    681400/681400 2065408.180194872:   call                     7faea66c0335 _dl_map_object_from_fd+0x515 =>     7faea66dbaa0 __fstat+0x0
    681400/681400 2065408.180194888:   jmp                      7faea66dbab7 __fstat+0x17 =>     7faea66dbaf0 __GI___fstatat64+0x0
    -> 99.311us END   _dl_debug_update
    -> 99.311us BEGIN __fstat
    681400/681400 2065408.180194902:   syscall                  7faea66dbafc __GI___fstatat64+0xc => ffffffffae200000 __entry_text_start+0x0
    -> 99.327us END   __fstat
    -> 99.327us BEGIN __GI___fstatat64
    681400/681400 2065408.180195387:   tr strt                             0 [unknown] =>     7faea66dbafe __GI___fstatat64+0xe
    -> 99.341us BEGIN __entry_text_start
    681400/681400 2065408.180195388:   return                   7faea66dbb07 __GI___fstatat64+0x17 =>     7faea66c033a _dl_map_object_from_fd+0x51a
    -> 99.826us END   __entry_text_start
    681400/681400 2065408.180195411:   call                     7faea66bfece _dl_map_object_from_fd+0xae =>     7faea66c47b0 _dl_new_object+0x0
    681400/681400 2065408.180195411:   call                     7faea66c47f3 _dl_new_object+0x43 =>     7faea66dfc60 strlen+0x0
    681400/681400 2065408.180195415:   return                   7faea66dfc9d strlen+0x3d =>     7faea66c47f8 _dl_new_object+0x48
    ->  99.85us BEGIN _dl_new_object
    -> 99.852us BEGIN strlen
    681400/681400 2065408.180195416:   call                     7faea66c481d _dl_new_object+0x6d =>     7faea65373b0 calloc+0x0
    -> 99.854us END   strlen
    681400/681400 2065408.180195430:   call                     7faea6537484 calloc+0xd4 =>     7faea6534f00 _int_malloc+0x0
    -> 99.855us BEGIN calloc
    681400/681400 2065408.180195456:   return                   7faea6535016 _int_malloc+0x116 =>     7faea6537489 calloc+0xd9
    -> 99.869us BEGIN _int_malloc
    681400/681400 2065408.180195460:   jmp                      7faea653768f calloc+0x2df =>     7faea662e680 __memset_evex_unaligned_erms+0x0
    -> 99.895us END   _int_malloc
    681400/681400 2065408.180195480:   return                   7faea662e77f __memset_evex_unaligned_erms+0xff =>     7faea66c4823 _dl_new_object+0x73
    -> 99.899us END   calloc
    -> 99.899us BEGIN __memset_evex_unaligned_erms
    681400/681400 2065408.180195480:   call                     7faea66c4860 _dl_new_object+0xb0 =>     7faea66e01d0 memcpy+0x0
    681400/681400 2065408.180195489:   return                   7faea66e0240 memcpy+0x70 =>     7faea66c4866 _dl_new_object+0xb6
    -> 99.919us END   __memset_evex_unaligned_erms
    -> 99.919us BEGIN memcpy
    681400/681400 2065408.180195499:   call                     7faea66c49a1 _dl_new_object+0x1f1 =>     7faea66dfc60 strlen+0x0
    -> 99.928us END   memcpy
    681400/681400 2065408.180195509:   return                   7faea66dfce6 strlen+0x86 =>     7faea66c49a6 _dl_new_object+0x1f6
    -> 99.938us BEGIN strlen
    681400/681400 2065408.180195510:   call                     7faea66c4b13 _dl_new_object+0x363 =>     7faea6536590 __libc_malloc+0x0
    -> 99.948us END   strlen
    681400/681400 2065408.180195638:   return                   7faea6536735 __libc_malloc+0x1a5 =>     7faea66c4b19 _dl_new_object+0x369
    -> 99.949us BEGIN __libc_malloc
    681400/681400 2065408.180195643:   call                     7faea66c4a42 _dl_new_object+0x292 =>     7faea66e01c0 __mempcpy+0x0
    -> 100.077us END   __libc_malloc
    681400/681400 2065408.180195643:   jmp                      7faea66e01ca __mempcpy+0xa =>     7faea66e01d7 memcpy+0x7
    681400/681400 2065408.180195648:   return                   7faea66e01f3 memcpy+0x23 =>     7faea66c4a48 _dl_new_object+0x298
    -> 100.082us BEGIN __mempcpy
    -> 100.084us END   __mempcpy
    -> 100.084us BEGIN memcpy
    -> 67.775us END   _dl_lookup_symbol_x
    -> 67.775us BEGIN _dl_find_object_from_map
    681400/681400 2065408.180195655:   return                   7faea66c4a7e _dl_new_object+0x2ce =>     7faea66bfed3 _dl_map_object_from_fd+0xb3
    -> 100.087us END   memcpy
    681400/681400 2065408.180195711:   call                     7faea66c016a _dl_map_object_from_fd+0x34a =>     7faea66dbec0 mmap64+0x0
    -> 100.094us END   _dl_new_object
    681400/681400 2065408.180195727:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    -> 100.15us BEGIN mmap64
    681400/681400 2065408.180196655:   tr strt                             0 [unknown] =>     7faea66dbed7 mmap64+0x17
    -> 100.166us BEGIN __entry_text_start
    681400/681400 2065408.180196657:   return                   7faea66dbedf mmap64+0x1f =>     7faea66c016f _dl_map_object_from_fd+0x34f
    -> 101.094us END   __entry_text_start
    681400/681400 2065408.180196671:   call                     7faea66c02f2 _dl_map_object_from_fd+0x4d2 =>     7faea66dbec0 mmap64+0x0
    681400/681400 2065408.180196695:   syscall                  7faea66dbed5 mmap64+0x15 => ffffffffae200000 __entry_text_start+0x0
    -> 101.11us BEGIN mmap64
    681400/681400 2065408.180197667:   tr strt                             0 [unknown] => ffffffffad88b009 tlb_gather_mmu+0x79
    -> 101.134us BEGIN __entry_text_start
    681400/681400 2065408.180199074:   tr strt                             0 [unknown] => ffffffffad670a14 native_write_msr+0x4
    -> 102.106us END   __entry_text_start
    END
    -> 61.733us BEGIN _dl_relocate_object [inferred start time]
    -> 100.091us END   _dl_find_object_from_map
    -> 100.091us BEGIN _dl_new_object
    -> 100.091us END   _dl_new_object
    -> 100.166us BEGIN [unknown]
    -> 101.096us END   [unknown]
    -> 100.166us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 99.341us BEGIN [unknown]
    -> 99.827us END   [unknown]
    -> 99.341us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 98.736us BEGIN _dl_map_object [inferred start time]
    -> 98.736us BEGIN [unknown]
    -> 99.241us END   [unknown]
    -> 98.736us BEGIN open_verify.constprop.0 [inferred start time]
    -> 97.772us BEGIN [unknown]
    -> 98.719us END   [unknown]
    -> 97.772us BEGIN open_verify.constprop.0 [inferred start time]
    -> 95.718us BEGIN _dl_map_object [inferred start time]
    -> 95.287us BEGIN _dl_load_cache_lookup [inferred start time]
    -> 95.287us BEGIN [unknown]
    -> 95.543us END   [unknown]
    -> 95.287us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 94.168us BEGIN [unknown]
    -> 95.272us END   [unknown]
    -> 94.168us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    ->  93.55us BEGIN [unknown]
    -> 94.145us END   [unknown]
    ->  93.55us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 92.425us BEGIN [unknown]
    -> 93.528us END   [unknown]
    -> 92.425us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 81.536us BEGIN main [inferred start time]
    -> 81.536us BEGIN dlclose [inferred start time]
    -> 81.536us BEGIN _dlerror_run [inferred start time]
    -> 81.536us BEGIN _dl_catch_error [inferred start time]
    -> 81.536us BEGIN _dl_catch_exception [inferred start time]
    -> 81.536us BEGIN _dl_close [inferred start time]
    -> 81.536us BEGIN _dl_close_worker [inferred start time]
    -> 81.536us BEGIN [unknown]
    -> 91.153us END   [unknown]
    -> 81.536us BEGIN _dl_unmap [inferred start time]
    -> 80.421us BEGIN _dl_close_worker [inferred start time]
    -> 80.421us BEGIN [unknown]
    -> 81.379us END   [unknown]
    -> 80.421us BEGIN _dl_catch_exception [inferred start time]
    -> 78.886us BEGIN main [inferred start time]
    -> 78.886us BEGIN __cos_fma [inferred start time]
    -> 76.351us BEGIN __cos_fma [inferred start time]
    -> 73.503us BEGIN __cos_fma [inferred start time]
    -> 69.533us BEGIN main [inferred start time]
    -> 69.533us BEGIN dlopen [inferred start time]
    -> 69.533us BEGIN _dlerror_run [inferred start time]
    -> 69.533us BEGIN _dl_catch_error [inferred start time]
    -> 69.533us BEGIN _dl_catch_exception [inferred start time]
    -> 69.533us BEGIN dlopen_doit [inferred start time]
    -> 69.533us BEGIN _dl_open [inferred start time]
    -> 69.533us BEGIN [unknown]
    ->  72.97us END   [unknown]
    -> 69.533us BEGIN _dl_unload_cache [inferred start time]
    -> 68.112us BEGIN _dl_open [inferred start time]
    -> 68.112us BEGIN _dl_catch_exception [inferred start time]
    -> 68.112us BEGIN dl_open_worker [inferred start time]
    -> 68.112us BEGIN _dl_catch_exception [inferred start time]
    -> 68.112us BEGIN _dl_init [inferred start time]
    -> 68.112us BEGIN call_init [inferred start time]
    -> 68.112us BEGIN _init [inferred start time]
    -> 66.363us BEGIN dl_open_worker [inferred start time]
    -> 66.363us BEGIN _dl_catch_exception [inferred start time]
    -> 66.363us BEGIN dl_open_worker_begin [inferred start time]
    -> 66.363us BEGIN _dl_relocate_object [inferred start time]
    -> 66.363us BEGIN [unknown]
    -> 67.667us END   [unknown]
    -> 66.363us BEGIN _dl_protect_relro [inferred start time]
    -> 64.994us BEGIN _dl_relocate_object [inferred start time]
    -> 64.994us BEGIN fmaf32x [inferred start time]
    -> 63.546us BEGIN [unknown]
    -> 64.793us END   [unknown]
    -> 63.546us BEGIN _dl_relocate_object [inferred start time]
    -> 62.027us BEGIN _dl_relocate_object [inferred start time]
    -> 62.027us BEGIN sinf32x [inferred start time]
    -> 58.282us BEGIN dl_open_worker_begin [inferred start time]
    -> 58.282us BEGIN _dl_map_object [inferred start time]
    -> 58.282us BEGIN [unknown]
    -> 58.414us END   [unknown]
    -> 58.282us BEGIN _dl_map_object_from_fd [inferred start time]
    ->  55.72us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 55.143us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 53.886us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 53.886us BEGIN memset [inferred start time]
    -> 52.502us BEGIN [unknown]
    -> 53.725us END   [unknown]
    -> 52.502us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 51.349us BEGIN [unknown]
    -> 52.483us END   [unknown]
    -> 51.349us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 49.298us BEGIN [unknown]
    -> 51.328us END   [unknown]
    -> 49.298us BEGIN _dl_map_object_from_fd [inferred start time]
    -> 48.451us BEGIN [unknown]
    -> 49.267us END   [unknown]
    -> 48.451us BEGIN _dl_map_object_from_fd [inferred start time]
    ->  47.43us BEGIN [unknown]
    -> 47.884us END   [unknown]
    ->  47.43us BEGIN _dl_map_object_from_fd [inferred start time]
    ->  46.32us BEGIN _dl_map_object [inferred start time]
    ->  46.32us BEGIN [unknown]
    -> 47.318us END   [unknown]
    ->  46.32us BEGIN open_verify.constprop.0 [inferred start time]
    -> 45.269us BEGIN [unknown]
    -> 46.305us END   [unknown]
    -> 45.269us BEGIN open_verify.constprop.0 [inferred start time]
    -> 43.201us BEGIN _dl_map_object [inferred start time]
    -> 43.201us BEGIN _dl_load_cache_lookup [inferred start time]
    ->  42.74us BEGIN _dl_load_cache_lookup [inferred start time]
    ->  42.74us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 41.411us BEGIN [unknown]
    -> 42.725us END   [unknown]
    -> 41.411us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 40.505us BEGIN [unknown]
    -> 41.394us END   [unknown]
    -> 40.505us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    ->  38.92us BEGIN [unknown]
    -> 40.492us END   [unknown]
    ->  38.92us BEGIN _dl_sysdep_read_whole_file [inferred start time]
    -> 26.284us BEGIN main [inferred start time]
    -> 26.284us BEGIN dlclose [inferred start time]
    -> 26.284us BEGIN _dlerror_run [inferred start time]
    -> 26.284us BEGIN _dl_catch_error [inferred start time]
    -> 26.284us BEGIN _dl_catch_exception [inferred start time]
    -> 26.284us BEGIN _dl_close [inferred start time]
    -> 26.284us BEGIN _dl_close_worker [inferred start time]
    -> 26.284us BEGIN [unknown]
    -> 37.972us END   [unknown]
    -> 26.284us BEGIN _dl_unmap [inferred start time]
    -> 24.874us BEGIN _dl_close_worker [inferred start time]
    -> 24.874us BEGIN [unknown]
    -> 26.226us END   [unknown]
    -> 24.874us BEGIN _dl_catch_exception [inferred start time]
    -> 23.215us BEGIN main [inferred start time]
    -> 23.215us BEGIN __cos_fma [inferred start time]
    -> 19.615us BEGIN __cos_fma [inferred start time]
    -> 16.618us BEGIN __cos_fma [inferred start time]
    -> 12.571us BEGIN main [inferred start time]
    -> 12.571us BEGIN dlopen [inferred start time]
    -> 12.571us BEGIN _dlerror_run [inferred start time]
    -> 12.571us BEGIN _dl_catch_error [inferred start time]
    -> 12.571us BEGIN _dl_catch_exception [inferred start time]
    -> 12.571us BEGIN dlopen_doit [inferred start time]
    -> 12.571us BEGIN _dl_open [inferred start time]
    -> 12.571us BEGIN [unknown]
    -> 16.097us END   [unknown]
    -> 12.571us BEGIN _dl_unload_cache [inferred start time]
    -> 11.183us BEGIN _dl_open [inferred start time]
    -> 11.183us BEGIN _dl_catch_exception [inferred start time]
    -> 11.183us BEGIN dl_open_worker [inferred start time]
    -> 11.183us BEGIN _dl_catch_exception [inferred start time]
    -> 11.183us BEGIN _dl_init [inferred start time]
    -> 11.183us BEGIN call_init [inferred start time]
    ->  9.601us BEGIN dl_open_worker [inferred start time]
    ->  9.601us BEGIN _dl_catch_exception [inferred start time]
    ->  9.601us BEGIN dl_open_worker_begin [inferred start time]
    ->  9.601us BEGIN _dl_relocate_object [inferred start time]
    ->  9.601us BEGIN [unknown]
    -> 10.792us END   [unknown]
    ->  9.601us BEGIN _dl_protect_relro [inferred start time]
    ->   8.24us BEGIN _dl_relocate_object [inferred start time]
    ->   8.24us BEGIN fmaf32x [inferred start time]
    ->  6.826us BEGIN [unknown]
    ->  8.045us END   [unknown]
    ->  6.826us BEGIN _dl_relocate_object [inferred start time]
    ->  5.283us BEGIN _dl_relocate_object [inferred start time]
    ->  5.283us BEGIN sinf32x [inferred start time]
    ->  1.689us BEGIN dl_open_worker_begin [inferred start time]
    ->  1.689us BEGIN dl_open_worker_begin [inferred start time]
    ->  1.689us BEGIN _dl_map_object [inferred start time]
    ->  1.689us BEGIN [unknown]
    ->  1.812us END   [unknown]
    ->  1.689us BEGIN _dl_map_object_from_fd [inferred start time]
    ->    281ns BEGIN _dl_map_object_from_fd [inferred start time]
    ->      0ns BEGIN _dl_map_object_from_fd
    -> 103.513us BEGIN native_write_msr
    -> 103.513us END   native_write_msr
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   __GI___fstatat64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object
    -> 103.513us END   __GI___read_nocancel
    -> 103.513us END   open_verify.constprop.0
    -> 103.513us END   __open64_nocancel
    -> 103.513us END   open_verify.constprop.0
    -> 103.513us END   _dl_map_object
    -> 103.513us END   _dl_load_cache_lookup
    -> 103.513us END   __GI___close_nocancel
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   __GI___fstatat64
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   __open64_nocancel
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   _dl_load_cache_lookup
    -> 103.513us END   _dl_map_object
    -> 103.513us END   dl_open_worker_begin
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   dl_open_worker
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_open
    -> 103.513us END   dlopen_doit
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_catch_error
    -> 103.513us END   _dlerror_run
    -> 103.513us END   dlopen
    -> 103.513us END   main
    -> 103.513us END   __munmap
    -> 103.513us END   _dl_unmap
    -> 103.513us END   _dl_close_worker
    -> 103.513us END   _fini
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_close_worker
    -> 103.513us END   _dl_close
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_catch_error
    -> 103.513us END   _dlerror_run
    -> 103.513us END   dlclose
    -> 103.513us END   main
    -> 103.513us END   __cos_fma
    -> 103.513us END   __cos_fma
    -> 103.513us END   __cos_fma
    -> 103.513us END   main
    -> 103.513us END   __munmap
    -> 103.513us END   _dl_unload_cache
    -> 103.513us END   _dl_open
    -> 103.513us END   _init
    -> 103.513us END   call_init
    -> 103.513us END   _dl_init
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   dl_open_worker
    -> 103.513us END   mprotect
    -> 103.513us END   _dl_protect_relro
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   fmaf32x
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   exp2f
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   sinf32x
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   dl_open_worker_begin
    -> 103.513us END   __GI___close_nocancel
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   memset
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   __GI___fstatat64
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object
    -> 103.513us END   __GI___read_nocancel
    -> 103.513us END   open_verify.constprop.0
    -> 103.513us END   __open64_nocancel
    -> 103.513us END   open_verify.constprop.0
    -> 103.513us END   _dl_map_object
    -> 103.513us END   _dl_load_cache_lookup
    -> 103.513us END   __GI___close_nocancel
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   mmap64
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   __GI___fstatat64
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   __open64_nocancel
    -> 103.513us END   _dl_sysdep_read_whole_file
    -> 103.513us END   _dl_load_cache_lookup
    -> 103.513us END   _dl_map_object
    -> 103.513us END   dl_open_worker_begin
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   dl_open_worker
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_open
    -> 103.513us END   dlopen_doit
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_catch_error
    -> 103.513us END   _dlerror_run
    -> 103.513us END   dlopen
    -> 103.513us END   main
    -> 103.513us END   __munmap
    -> 103.513us END   _dl_unmap
    -> 103.513us END   _dl_close_worker
    -> 103.513us END   _fini
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_close_worker
    -> 103.513us END   _dl_close
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   _dl_catch_error
    -> 103.513us END   _dlerror_run
    -> 103.513us END   dlclose
    -> 103.513us END   main
    -> 103.513us END   __cos_fma
    -> 103.513us END   __cos_fma
    -> 103.513us END   __cos_fma
    -> 103.513us END   main
    -> 103.513us END   __munmap
    -> 103.513us END   _dl_unload_cache
    -> 103.513us END   _dl_open
    -> 103.513us END   _init
    -> 103.513us END   call_init
    -> 103.513us END   _dl_init
    -> 103.513us END   _dl_catch_exception
    -> 103.513us END   dl_open_worker
    -> 103.513us END   mprotect
    -> 103.513us END   _dl_protect_relro
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   fmaf32x
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   exp2f
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   sinf32x
    -> 103.513us END   _dl_relocate_object
    -> 103.513us END   _dl_map_object_from_fd
    -> 103.513us END   _dl_map_object_from_fd |}]
;;
