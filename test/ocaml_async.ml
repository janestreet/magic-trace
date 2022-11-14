open! Core
open! Async

let%expect_test "" =
  let%map () =
    Perf_script.run ~trace_scope:Userspace "ocaml_async.perf"
  in
  [%expect
    {|
    4589/4589  108652.292046895:                            1   branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (foo.exe) =>           bcd5dc Time_now.nanoseconds_since_unix_epoch_1088+0x2c (foo.exe)
    4589/4589  108652.292046896:                            1   branches:uH:   return                           bcd5ea Time_now.nanoseconds_since_unix_epoch_1088+0x3a (foo.exe) =>           ae9608 Core.Span_ns.since_unix_epoch_9948+0x18 (foo.exe)
    4589/4589  108652.292046897:                            1   branches:uH:   return                           ae960c Core.Span_ns.since_unix_epoch_9948+0x1c (foo.exe) =>           81f0d1 Async_kernel.Scheduler.run_cycle_7957+0x5a1 (foo.exe)
    ->      1ns END   Time_now.nanoseconds_since_unix_epoch_1088
    4589/4589  108652.292046897:                            1   branches:uH:   call                             81f0da Async_kernel.Scheduler.run_cycle_7957+0x5aa (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046899:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           ae5b40 Core.Span_ns.-_6237+0x0 (foo.exe)
    ->      2ns END   Core.Span_ns.since_unix_epoch_9948
    ->      2ns BEGIN caml_apply2
    4589/4589  108652.292046899:                            1   branches:uH:   jmp                              ae5b5b Core.Span_ns.-_6237+0x1b (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046900:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c862f0 Base.Int63.fun_4900+0x0 (foo.exe)
    ->      4ns END   caml_apply2
    ->      4ns BEGIN Core.Span_ns.-_6237
    ->      4ns END   Core.Span_ns.-_6237
    ->      4ns BEGIN caml_apply2
    4589/4589  108652.292046900:                            1   branches:uH:   return                           c862f7 Base.Int63.fun_4900+0x7 (foo.exe) =>           81f0df Async_kernel.Scheduler.run_cycle_7957+0x5af (foo.exe)
    4589/4589  108652.292046900:                            1   branches:uH:   call                             81f123 Async_kernel.Scheduler.run_cycle_7957+0x5f3 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046910:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           ae5b10 Core.Span_ns.+_6234+0x0 (foo.exe)
    ->      5ns END   caml_apply2
    ->      5ns BEGIN Base.Int63.fun_4900
    ->     10ns END   Base.Int63.fun_4900
    ->     10ns BEGIN caml_apply2
    4589/4589  108652.292046910:                            1   branches:uH:   jmp                              ae5b2b Core.Span_ns.+_6234+0x1b (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046911:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86300 Base.Int63.fun_4898+0x0 (foo.exe)
    ->     15ns END   caml_apply2
    ->     15ns BEGIN Core.Span_ns.+_6234
    ->     15ns END   Core.Span_ns.+_6234
    ->     15ns BEGIN caml_apply2
    4589/4589  108652.292046911:                            1   branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (foo.exe) =>           81f128 Async_kernel.Scheduler.run_cycle_7957+0x5f8 (foo.exe)
    4589/4589  108652.292046911:                            1   branches:uH:   call                             81f1f1 Async_kernel.Scheduler.run_cycle_7957+0x6c1 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046913:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           be4a40 Base.Array0.iter_1696+0x0 (foo.exe)
    ->     16ns END   caml_apply2
    ->     16ns BEGIN Base.Int63.fun_4898
    ->     17ns END   Base.Int63.fun_4898
    ->     17ns BEGIN caml_apply2
    4589/4589  108652.292046913:                            1   branches:uH:   return                           be4ae1 Base.Array0.iter_1696+0xa1 (foo.exe) =>           81f1f6 Async_kernel.Scheduler.run_cycle_7957+0x6c6 (foo.exe)
    4589/4589  108652.292046915:                            1   branches:uH:   return                           81f485 Async_kernel.Scheduler.run_cycle_7957+0x955 (foo.exe) =>           6f0f24 Async_unix.Raw_scheduler.one_iter_13456+0x254 (foo.exe)
    ->     18ns END   caml_apply2
    ->     18ns BEGIN Base.Array0.iter_1696
    ->     20ns END   Base.Array0.iter_1696
    4589/4589  108652.292046920:                            1   branches:uH:   call                             6f0f61 Async_unix.Raw_scheduler.one_iter_13456+0x291 (foo.exe) =>           ae5020 Core.Span_ns.of_int_us_6033+0x0 (foo.exe)
    ->     20ns END   Async_kernel.Scheduler.run_cycle_7957
    4589/4589  108652.292046921:                            1   branches:uH:   call                             ae5058 Core.Span_ns.of_int_us_6033+0x38 (foo.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (foo.exe)
    ->     25ns BEGIN Core.Span_ns.of_int_us_6033
    4589/4589  108652.292046921:                            1   branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (foo.exe) =>           ae505a Core.Span_ns.of_int_us_6033+0x3a (foo.exe)
    4589/4589  108652.292046921:                            1   branches:uH:   jmp                              ae5067 Core.Span_ns.of_int_us_6033+0x47 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046923:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c862e0 Base.Int63.fun_4902+0x0 (foo.exe)
    ->     26ns BEGIN Base.Int.of_int_2534
    ->     27ns END   Base.Int.of_int_2534
    ->     27ns END   Core.Span_ns.of_int_us_6033
    ->     27ns BEGIN caml_apply2
    4589/4589  108652.292046923:                            1   branches:uH:   return                           c862ef Base.Int63.fun_4902+0xf (foo.exe) =>           6f0f63 Async_unix.Raw_scheduler.one_iter_13456+0x293 (foo.exe)
    4589/4589  108652.292046923:                            1   branches:uH:   call                             6f0f6f Async_unix.Raw_scheduler.one_iter_13456+0x29f (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046924:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86330 Base.Int63.fun_4892+0x0 (foo.exe)
    ->     28ns END   caml_apply2
    ->     28ns BEGIN Base.Int63.fun_4902
    ->     28ns END   Base.Int63.fun_4902
    ->     28ns BEGIN caml_apply2
    4589/4589  108652.292046925:                            1   branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (foo.exe) =>           6f0f74 Async_unix.Raw_scheduler.one_iter_13456+0x2a4 (foo.exe)
    ->     29ns END   caml_apply2
    ->     29ns BEGIN Base.Int63.fun_4892
    4589/4589  108652.292046926:                            1   branches:uH:   call                             6f0fcb Async_unix.Raw_scheduler.one_iter_13456+0x2fb (foo.exe) =>           b02db0 Thread.fun_715+0x0 (foo.exe)
    ->     30ns END   Base.Int63.fun_4892
    4589/4589  108652.292046926:                            1   branches:uH:   call                             b02db7 Thread.fun_715+0x7 (foo.exe) =>           d44690 caml_thread_self+0x0 (foo.exe)
    4589/4589  108652.292046926:                            1   branches:uH:   return                           d4469f caml_thread_self+0xf (foo.exe) =>           b02dbc Thread.fun_715+0xc (foo.exe)
    4589/4589  108652.292046926:                            1   branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (foo.exe) =>           6f0fcd Async_unix.Raw_scheduler.one_iter_13456+0x2fd (foo.exe)
    4589/4589  108652.292046927:                            1   branches:uH:   call                             6f0fd4 Async_unix.Raw_scheduler.one_iter_13456+0x304 (foo.exe) =>           b02d90 Thread.fun_713+0x0 (foo.exe)
    ->     31ns BEGIN Thread.fun_715
    ->     31ns BEGIN caml_thread_self
    ->     32ns END   caml_thread_self
    ->     32ns END   Thread.fun_715
    4589/4589  108652.292046927:                            1   branches:uH:   call                             b02d97 Thread.fun_713+0x7 (foo.exe) =>           d446b0 caml_thread_id+0x0 (foo.exe)
    4589/4589  108652.292046928:                            1   branches:uH:   return                           d446b3 caml_thread_id+0x3 (foo.exe) =>           b02d9c Thread.fun_713+0xc (foo.exe)
    ->     32ns BEGIN Thread.fun_713
    ->     32ns BEGIN caml_thread_id
    4589/4589  108652.292046928:                            1   branches:uH:   return                           b02da0 Thread.fun_713+0x10 (foo.exe) =>           6f0fd6 Async_unix.Raw_scheduler.one_iter_13456+0x306 (foo.exe)
    4589/4589  108652.292046928:                            1   branches:uH:   call                             6f0fe0 Async_unix.Raw_scheduler.one_iter_13456+0x310 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292046929:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd950 Core.Int.fun_13981+0x0 (foo.exe)
    ->     33ns END   caml_thread_id
    ->     33ns END   Thread.fun_713
    ->     33ns BEGIN caml_apply2
    4589/4589  108652.292046930:                            1   branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (foo.exe) =>           6f0fe5 Async_unix.Raw_scheduler.one_iter_13456+0x315 (foo.exe)
    ->     34ns END   caml_apply2
    ->     34ns BEGIN Core.Int.fun_13981
    4589/4589  108652.292046930:                            1   branches:uH:   return                           6f0ff4 Async_unix.Raw_scheduler.one_iter_13456+0x324 (foo.exe) =>           6f1549 Async_unix.Raw_scheduler.loop_13465+0xd9 (foo.exe)
    4589/4589  108652.292046954:                            1   branches:uH:   call                             6f14a0 Async_unix.Raw_scheduler.loop_13465+0x30 (foo.exe) =>           820330 Async_kernel.Scheduler.check_invariants_8475+0x0 (foo.exe)
    ->     35ns END   Core.Int.fun_13981
    ->     35ns END   Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292046955:                            1   branches:uH:   return                           820337 Async_kernel.Scheduler.check_invariants_8475+0x7 (foo.exe) =>           6f14a2 Async_unix.Raw_scheduler.loop_13465+0x32 (foo.exe)
    ->     59ns BEGIN Async_kernel.Scheduler.check_invariants_8475
    4589/4589  108652.292046959:                            1   branches:uH:   call                             6f14d5 Async_unix.Raw_scheduler.loop_13465+0x65 (foo.exe) =>           7ffa60 Async_kernel.Scheduler1.uncaught_exn_7315+0x0 (foo.exe)
    ->     60ns END   Async_kernel.Scheduler.check_invariants_8475
    4589/4589  108652.292046959:                            1   branches:uH:   return                           7ffae9 Async_kernel.Scheduler1.uncaught_exn_7315+0x89 (foo.exe) =>           6f14d7 Async_unix.Raw_scheduler.loop_13465+0x67 (foo.exe)
    4589/4589  108652.292046959:                            1   branches:uH:   call                             6f1544 Async_unix.Raw_scheduler.loop_13465+0xd4 (foo.exe) =>           6f0cd0 Async_unix.Raw_scheduler.one_iter_13456+0x0 (foo.exe)
    4589/4589  108652.292046973:                            1   branches:uH:   call                             6f0d01 Async_unix.Raw_scheduler.one_iter_13456+0x31 (foo.exe) =>           d0a360 Stdlib.Lazy.is_val_370+0x0 (foo.exe)
    ->     64ns BEGIN Async_kernel.Scheduler1.uncaught_exn_7315
    ->     71ns END   Async_kernel.Scheduler1.uncaught_exn_7315
    ->     71ns BEGIN Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292046973:                            1   branches:uH:   call                             d0a367 Stdlib.Lazy.is_val_370+0x7 (foo.exe) =>           d62bb0 caml_obj_tag+0x0 (foo.exe)
    4589/4589  108652.292046974:                            1   branches:uH:   call                             d62bd0 caml_obj_tag+0x20 (foo.exe) =>           d538d0 caml_page_table_lookup+0x0 (foo.exe)
    ->     78ns BEGIN Stdlib.Lazy.is_val_370
    ->     78ns BEGIN caml_obj_tag
    4589/4589  108652.292046974:                            1   branches:uH:   return                           d53942 caml_page_table_lookup+0x72 (foo.exe) =>           d62bd5 caml_obj_tag+0x25 (foo.exe)
    4589/4589  108652.292046974:                            1   branches:uH:   return                           d62beb caml_obj_tag+0x3b (foo.exe) =>           d0a36c Stdlib.Lazy.is_val_370+0xc (foo.exe)
    4589/4589  108652.292046983:                            1   branches:uH:   return                           d0a384 Stdlib.Lazy.is_val_370+0x24 (foo.exe) =>           6f0d03 Async_unix.Raw_scheduler.one_iter_13456+0x33 (foo.exe)
    ->     79ns BEGIN caml_page_table_lookup
    ->     88ns END   caml_page_table_lookup
    ->     88ns END   caml_obj_tag
    4589/4589  108652.292046983:                            1   branches:uH:   call                             6f0dfb Async_unix.Raw_scheduler.one_iter_13456+0x12b (foo.exe) =>           6eeeb0 Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x0 (foo.exe)
    4589/4589  108652.292047003:                            1   branches:uH:   call                             6eeecb Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1b (foo.exe) =>           cc66e0 Base.Stack.is_empty_1236+0x0 (foo.exe)
    ->     88ns END   Stdlib.Lazy.is_val_370
    ->     88ns BEGIN Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    4589/4589  108652.292047004:                            1   branches:uH:   return                           cc66f3 Base.Stack.is_empty_1236+0x13 (foo.exe) =>           6eeecd Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1d (foo.exe)
    ->    108ns BEGIN Base.Stack.is_empty_1236
    4589/4589  108652.292047004:                            1   branches:uH:   return                           6eeedc Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x2c (foo.exe) =>           6f0e00 Async_unix.Raw_scheduler.one_iter_13456+0x130 (foo.exe)
    4589/4589  108652.292047004:                            1   branches:uH:   call                             6f0e05 Async_unix.Raw_scheduler.one_iter_13456+0x135 (foo.exe) =>           6f07f0 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x0 (foo.exe)
    4589/4589  108652.292047004:                            1   branches:uH:   call                             6f0825 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x35 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047006:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd940 Core.Int.fun_13983+0x0 (foo.exe)
    ->    109ns END   Base.Stack.is_empty_1236
    ->    109ns END   Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    ->    109ns BEGIN Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    ->    110ns BEGIN caml_apply2
    4589/4589  108652.292047007:                            1   branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (foo.exe) =>           6f082a Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x3a (foo.exe)
    ->    111ns END   caml_apply2
    ->    111ns BEGIN Core.Int.fun_13983
    4589/4589  108652.292047007:                            1   branches:uH:   call                             6f0874 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x84 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047010:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86330 Base.Int63.fun_4892+0x0 (foo.exe)
    ->    112ns END   Core.Int.fun_13983
    ->    112ns BEGIN caml_apply2
    4589/4589  108652.292047010:                            1   branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (foo.exe) =>           6f0879 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x89 (foo.exe)
    4589/4589  108652.292047013:                            1   branches:uH:   call                             6f089b Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xab (foo.exe) =>           81c840 Async_kernel.Scheduler.can_run_a_job_5765+0x0 (foo.exe)
    ->    115ns END   caml_apply2
    ->    115ns BEGIN Base.Int63.fun_4892
    ->    118ns END   Base.Int63.fun_4892
    4589/4589  108652.292047013:                            1   branches:uH:   call                             81c86d Async_kernel.Scheduler.can_run_a_job_5765+0x2d (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047015:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd940 Core.Int.fun_13983+0x0 (foo.exe)
    ->    118ns BEGIN Async_kernel.Scheduler.can_run_a_job_5765
    ->    119ns BEGIN caml_apply2
    4589/4589  108652.292047015:                            1   branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (foo.exe) =>           81c872 Async_kernel.Scheduler.can_run_a_job_5765+0x32 (foo.exe)
    4589/4589  108652.292047015:                            1   branches:uH:   return                           81c88a Async_kernel.Scheduler.can_run_a_job_5765+0x4a (foo.exe) =>           6f089d Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xad (foo.exe)
    4589/4589  108652.292047017:                            1   branches:uH:   call                             6f0926 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x136 (foo.exe) =>           81c8a0 Async_kernel.Scheduler.has_upcoming_event_5918+0x0 (foo.exe)
    ->    120ns END   caml_apply2
    ->    120ns BEGIN Core.Int.fun_13983
    ->    122ns END   Core.Int.fun_13983
    ->    122ns END   Async_kernel.Scheduler.can_run_a_job_5765
    4589/4589  108652.292047023:                            1   branches:uH:   call                             81c8bd Async_kernel.Scheduler.has_upcoming_event_5918+0x1d (foo.exe) =>           8ad630 Timing_wheel.is_empty_19261+0x0 (foo.exe)
    ->    122ns BEGIN Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292047037:                            1   branches:uH:   jmp                              8ad657 Timing_wheel.is_empty_19261+0x27 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    ->    128ns BEGIN Timing_wheel.is_empty_19261
    4589/4589  108652.292047045:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd950 Core.Int.fun_13981+0x0 (foo.exe)
    ->    142ns END   Timing_wheel.is_empty_19261
    ->    142ns BEGIN caml_apply2
    4589/4589  108652.292047046:                            1   branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (foo.exe) =>           81c8bf Async_kernel.Scheduler.has_upcoming_event_5918+0x1f (foo.exe)
    ->    150ns END   caml_apply2
    ->    150ns BEGIN Core.Int.fun_13981
    4589/4589  108652.292047046:                            1   branches:uH:   return                           81c8ce Async_kernel.Scheduler.has_upcoming_event_5918+0x2e (foo.exe) =>           6f0928 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x138 (foo.exe)
    4589/4589  108652.292047047:                            1   branches:uH:   call                             6f094f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x15f (foo.exe) =>           81c910 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x0 (foo.exe)
    ->    151ns END   Core.Int.fun_13981
    ->    151ns END   Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292047052:                            1   branches:uH:   jmp                              81c939 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x29 (foo.exe) =>           8ae2b0 Timing_wheel.next_alarm_fires_at_exn_19321+0x0 (foo.exe)
    ->    152ns BEGIN Async_kernel.Scheduler.next_upcoming_event_exn_5924
    4589/4589  108652.292047052:                            1   branches:uH:   call                             8ae2d8 Timing_wheel.next_alarm_fires_at_exn_19321+0x28 (foo.exe) =>           8a6540 Timing_wheel.min_elt.16860+0x0 (foo.exe)
    4589/4589  108652.292047052:                            1   branches:uH:   call                             8a6579 Timing_wheel.min_elt.16860+0x39 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047055:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd950 Core.Int.fun_13981+0x0 (foo.exe)
    ->    157ns END   Async_kernel.Scheduler.next_upcoming_event_exn_5924
    ->    157ns BEGIN Timing_wheel.next_alarm_fires_at_exn_19321
    ->    158ns BEGIN Timing_wheel.min_elt.16860
    ->    159ns BEGIN caml_apply2
    4589/4589  108652.292047055:                            1   branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (foo.exe) =>           8a657e Timing_wheel.min_elt.16860+0x3e (foo.exe)
    4589/4589  108652.292047063:                            1   branches:uH:   call                             8a65c5 Timing_wheel.min_elt.16860+0x85 (foo.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (foo.exe)
    ->    160ns END   caml_apply2
    ->    160ns BEGIN Core.Int.fun_13981
    ->    168ns END   Core.Int.fun_13981
    4589/4589  108652.292047063:                            1   branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (foo.exe) =>           8a65c7 Timing_wheel.min_elt.16860+0x87 (foo.exe)
    4589/4589  108652.292047063:                            1   branches:uH:   return                           8a6a45 Timing_wheel.min_elt.16860+0x505 (foo.exe) =>           8ae2dd Timing_wheel.next_alarm_fires_at_exn_19321+0x2d (foo.exe)
    4589/4589  108652.292047075:                            1   branches:uH:   call                             8ae2fa Timing_wheel.next_alarm_fires_at_exn_19321+0x4a (foo.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (foo.exe)
    ->    168ns BEGIN Tuple_pool.is_null_4272
    ->    180ns END   Tuple_pool.is_null_4272
    ->    180ns END   Timing_wheel.min_elt.16860
    4589/4589  108652.292047076:                            1   branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (foo.exe) =>           8ae2fc Timing_wheel.next_alarm_fires_at_exn_19321+0x4c (foo.exe)
    ->    180ns BEGIN Tuple_pool.is_null_4272
    4589/4589  108652.292047076:                            1   branches:uH:   call                             8ae33a Timing_wheel.next_alarm_fires_at_exn_19321+0x8a (foo.exe) =>           6c88c0 caml_apply3+0x0 (foo.exe)
    4589/4589  108652.292047079:                            1   branches:uH:   jmp                              6c88da caml_apply3+0x1a (foo.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (foo.exe)
    ->    181ns END   Tuple_pool.is_null_4272
    ->    181ns BEGIN caml_apply3
    4589/4589  108652.292047079:                            1   branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047080:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (foo.exe)
    ->    184ns END   caml_apply3
    ->    184ns BEGIN Tuple_pool.get_8303
    ->    184ns END   Tuple_pool.get_8303
    ->    184ns BEGIN caml_apply2
    4589/4589  108652.292047080:                            1   branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (foo.exe) =>           8ae33f Timing_wheel.next_alarm_fires_at_exn_19321+0x8f (foo.exe)
    4589/4589  108652.292047080:                            1   branches:uH:   call                             8ae362 Timing_wheel.next_alarm_fires_at_exn_19321+0xb2 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047087:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c65180 Base.Int.fun_3468+0x0 (foo.exe)
    ->    185ns END   caml_apply2
    ->    185ns BEGIN Base.Uniform_array.get_1544
    ->    188ns END   Base.Uniform_array.get_1544
    ->    188ns BEGIN caml_apply2
    4589/4589  108652.292047087:                            1   branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (foo.exe) =>           8ae367 Timing_wheel.next_alarm_fires_at_exn_19321+0xb7 (foo.exe)
    4589/4589  108652.292047088:                            1   branches:uH:   call                             8ae397 Timing_wheel.next_alarm_fires_at_exn_19321+0xe7 (foo.exe) =>           c65880 Base.Int.succ_2528+0x0 (foo.exe)
    ->    192ns END   caml_apply2
    ->    192ns BEGIN Base.Int.fun_3468
    ->    193ns END   Base.Int.fun_3468
    4589/4589  108652.292047089:                            1   branches:uH:   return                           c65884 Base.Int.succ_2528+0x4 (foo.exe) =>           8ae399 Timing_wheel.next_alarm_fires_at_exn_19321+0xe9 (foo.exe)
    ->    193ns BEGIN Base.Int.succ_2528
    4589/4589  108652.292047089:                            1   branches:uH:   call                             8ae3bb Timing_wheel.next_alarm_fires_at_exn_19321+0x10b (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047089:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86320 Base.Int63.fun_4894+0x0 (foo.exe)
    4589/4589  108652.292047090:                            1   branches:uH:   return                           c8632f Base.Int63.fun_4894+0xf (foo.exe) =>           8ae3c0 Timing_wheel.next_alarm_fires_at_exn_19321+0x110 (foo.exe)
    ->    194ns END   Base.Int.succ_2528
    ->    194ns BEGIN caml_apply2
    ->    194ns END   caml_apply2
    ->    194ns BEGIN Base.Int63.fun_4894
    4589/4589  108652.292047090:                            1   branches:uH:   call                             8ae3f4 Timing_wheel.next_alarm_fires_at_exn_19321+0x144 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047091:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86330 Base.Int63.fun_4892+0x0 (foo.exe)
    ->    195ns END   Base.Int63.fun_4894
    ->    195ns BEGIN caml_apply2
    4589/4589  108652.292047091:                            1   branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (foo.exe) =>           8ae3f9 Timing_wheel.next_alarm_fires_at_exn_19321+0x149 (foo.exe)
    4589/4589  108652.292047091:                            1   branches:uH:   call                             8ae43e Timing_wheel.next_alarm_fires_at_exn_19321+0x18e (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047093:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c65960 Base.Int.shift_left_2568+0x0 (foo.exe)
    ->    196ns END   caml_apply2
    ->    196ns BEGIN Base.Int63.fun_4892
    ->    197ns END   Base.Int63.fun_4892
    ->    197ns BEGIN caml_apply2
    4589/4589  108652.292047093:                            1   branches:uH:   return                           c65971 Base.Int.shift_left_2568+0x11 (foo.exe) =>           8ae443 Timing_wheel.next_alarm_fires_at_exn_19321+0x193 (foo.exe)
    4589/4589  108652.292047094:                            1   branches:uH:   jmp                              8ae44e Timing_wheel.next_alarm_fires_at_exn_19321+0x19e (foo.exe) =>           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (foo.exe)
    ->    198ns END   caml_apply2
    ->    198ns BEGIN Base.Int.shift_left_2568
    ->    199ns END   Base.Int.shift_left_2568
    4589/4589  108652.292047094:                            1   branches:uH:   return                           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (foo.exe) =>           6f0951 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x161 (foo.exe)
    4589/4589  108652.292047094:                            1   branches:uH:   call                             6f09dc Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1ec (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047095:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c65180 Base.Int.fun_3468+0x0 (foo.exe)
    ->    199ns END   Timing_wheel.next_alarm_fires_at_exn_19321
    ->    199ns BEGIN Core.Time_ns.of_int63_ns_since_epoch_5150
    ->    199ns END   Core.Time_ns.of_int63_ns_since_epoch_5150
    ->    199ns BEGIN caml_apply2
    4589/4589  108652.292047096:                            1   branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (foo.exe) =>           6f09e1 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1f1 (foo.exe)
    ->    200ns END   caml_apply2
    ->    200ns BEGIN Base.Int.fun_3468
    4589/4589  108652.292047096:                            1   branches:uH:   call                             6f0b3f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x34f (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047098:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86350 Base.Int63.fun_4888+0x0 (foo.exe)
    ->    201ns END   Base.Int.fun_3468
    ->    201ns BEGIN caml_apply2
    4589/4589  108652.292047099:                            1   branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (foo.exe) =>           6f0b44 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x354 (foo.exe)
    ->    203ns END   caml_apply2
    ->    203ns BEGIN Base.Int63.fun_4888
    4589/4589  108652.292047099:                            1   branches:uH:   jmp                              6f0cb3 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x4c3 (foo.exe) =>           6efe20 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x0 (foo.exe)
    4589/4589  108652.292047118:                            1   branches:uH:   call                             6efe8a Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6a (foo.exe) =>           6d4ff0 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x0 (foo.exe)
    ->    204ns END   Base.Int63.fun_4888
    ->    204ns END   Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    ->    204ns BEGIN Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    4589/4589  108652.292047119:                            1   branches:uH:   return                           6d4ff5 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x5 (foo.exe) =>           6efe8c Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6c (foo.exe)
    ->    223ns BEGIN Async_unix.Epoll_file_descr_watcher.pre_check_8138
    4589/4589  108652.292047119:                            1   branches:uH:   call                             6efecd Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xad (foo.exe) =>           7af180 Nano_mutex.unlock_exn_5263+0x0 (foo.exe)
    4589/4589  108652.292047124:                            1   branches:uH:   call                             7af1bd Nano_mutex.unlock_exn_5263+0x3d (foo.exe) =>           b02db0 Thread.fun_715+0x0 (foo.exe)
    ->    224ns END   Async_unix.Epoll_file_descr_watcher.pre_check_8138
    ->    224ns BEGIN Nano_mutex.unlock_exn_5263
    4589/4589  108652.292047124:                            1   branches:uH:   call                             b02db7 Thread.fun_715+0x7 (foo.exe) =>           d44690 caml_thread_self+0x0 (foo.exe)
    4589/4589  108652.292047125:                            1   branches:uH:   return                           d4469f caml_thread_self+0xf (foo.exe) =>           b02dbc Thread.fun_715+0xc (foo.exe)
    ->    229ns BEGIN Thread.fun_715
    ->    229ns BEGIN caml_thread_self
    4589/4589  108652.292047125:                            1   branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (foo.exe) =>           7af1bf Nano_mutex.unlock_exn_5263+0x3f (foo.exe)
    4589/4589  108652.292047126:                            1   branches:uH:   call                             7af1c6 Nano_mutex.unlock_exn_5263+0x46 (foo.exe) =>           b02d90 Thread.fun_713+0x0 (foo.exe)
    ->    230ns END   caml_thread_self
    ->    230ns END   Thread.fun_715
    4589/4589  108652.292047126:                            1   branches:uH:   call                             b02d97 Thread.fun_713+0x7 (foo.exe) =>           d446b0 caml_thread_id+0x0 (foo.exe)
    4589/4589  108652.292047127:                            1   branches:uH:   return                           d446b3 caml_thread_id+0x3 (foo.exe) =>           b02d9c Thread.fun_713+0xc (foo.exe)
    ->    231ns BEGIN Thread.fun_713
    ->    231ns BEGIN caml_thread_id
    4589/4589  108652.292047127:                            1   branches:uH:   return                           b02da0 Thread.fun_713+0x10 (foo.exe) =>           7af1c8 Nano_mutex.unlock_exn_5263+0x48 (foo.exe)
    4589/4589  108652.292047127:                            1   branches:uH:   call                             7af1e9 Nano_mutex.unlock_exn_5263+0x69 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047128:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd920 Core.Int.fun_13987+0x0 (foo.exe)
    ->    232ns END   caml_thread_id
    ->    232ns END   Thread.fun_713
    ->    232ns BEGIN caml_apply2
    4589/4589  108652.292047128:                            1   branches:uH:   return                           9dd92f Core.Int.fun_13987+0xf (foo.exe) =>           7af1ee Nano_mutex.unlock_exn_5263+0x6e (foo.exe)
    4589/4589  108652.292047128:                            1   branches:uH:   call                             7af212 Nano_mutex.unlock_exn_5263+0x92 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292047131:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c65180 Base.Int.fun_3468+0x0 (foo.exe)
    ->    233ns END   caml_apply2
    ->    233ns BEGIN Core.Int.fun_13987
    ->    234ns END   Core.Int.fun_13987
    ->    234ns BEGIN caml_apply2
    4589/4589  108652.292047132:                            1   branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (foo.exe) =>           7af217 Nano_mutex.unlock_exn_5263+0x97 (foo.exe)
    ->    236ns END   caml_apply2
    ->    236ns BEGIN Base.Int.fun_3468
    4589/4589  108652.292047132:                            1   branches:uH:   call                             7af22c Nano_mutex.unlock_exn_5263+0xac (foo.exe) =>           d53b20 caml_modify+0x0 (foo.exe)
    4589/4589  108652.292047134:                            1   branches:uH:   return                           d53b48 caml_modify+0x28 (foo.exe) =>           7af231 Nano_mutex.unlock_exn_5263+0xb1 (foo.exe)
    ->    237ns END   Base.Int.fun_3468
    ->    237ns BEGIN caml_modify
    4589/4589  108652.292047136:                            1   branches:uH:   call                             7af247 Nano_mutex.unlock_exn_5263+0xc7 (foo.exe) =>           c12c50 Base.Option.is_some_1124+0x0 (foo.exe)
    ->    239ns END   caml_modify
    4589/4589  108652.292047137:                            1   branches:uH:   return                           c12c61 Base.Option.is_some_1124+0x11 (foo.exe) =>           7af249 Nano_mutex.unlock_exn_5263+0xc9 (foo.exe)
    ->    241ns BEGIN Base.Option.is_some_1124
    4589/4589  108652.292047138:                            1   branches:uH:   jmp                              7af296 Nano_mutex.unlock_exn_5263+0x116 (foo.exe) =>           c15330 Base.Or_error.ok_exn_2208+0x0 (foo.exe)
    ->    242ns END   Base.Option.is_some_1124
    4589/4589  108652.292047138:                            1   branches:uH:   return                           c15407 Base.Or_error.ok_exn_2208+0xd7 (foo.exe) =>           6efecf Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xaf (foo.exe)
    4589/4589  108652.292047139:                            1   branches:uH:   call                             6efee2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xc2 (foo.exe) =>           b02d50 Thread.fun_709+0x0 (foo.exe)
    ->    243ns END   Nano_mutex.unlock_exn_5263
    ->    243ns BEGIN Base.Or_error.ok_exn_2208
    ->    244ns END   Base.Or_error.ok_exn_2208
    4589/4589  108652.292047139:                            1   branches:uH:   call                             b02d5e Thread.fun_709+0xe (foo.exe) =>           d6d414 caml_c_call+0x0 (foo.exe)
    4589/4589  108652.292047140:                            1   branches:uH:   jmp                              d6d43c caml_c_call+0x28 (foo.exe) =>           d44780 caml_thread_yield+0x0 (foo.exe)
    ->    244ns BEGIN Thread.fun_709
    ->    244ns BEGIN caml_c_call
    4589/4589  108652.292047140:                            1   branches:uH:   call                             d44796 caml_thread_yield+0x16 (foo.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (foo.exe)
    4589/4589  108652.292047140:                            1   branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (foo.exe) =>           d4479b caml_thread_yield+0x1b (foo.exe)
    4589/4589  108652.292047140:                            1   branches:uH:   call                             d447a5 caml_thread_yield+0x25 (foo.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (foo.exe)
    4589/4589  108652.292047140:                            1   branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (foo.exe) =>           d447aa caml_thread_yield+0x2a (foo.exe)
    4589/4589  108652.292047140:                            1   branches:uH:   call                             d447fa caml_thread_yield+0x7a (foo.exe) =>           d53c20 caml_get_local_arenas+0x0 (foo.exe)
    4589/4589  108652.292047149:                            1   branches:uH:   return                           d53c3e caml_get_local_arenas+0x1e (foo.exe) =>           d447ff caml_thread_yield+0x7f (foo.exe)
    ->    245ns END   caml_c_call
    ->    245ns BEGIN caml_thread_yield
    ->    247ns BEGIN caml_process_pending_signals_exn
    ->    249ns END   caml_process_pending_signals_exn
    ->    249ns BEGIN caml_raise_async_if_exception
    ->    251ns END   caml_raise_async_if_exception
    ->    251ns BEGIN caml_get_local_arenas
    4589/4589  108652.292047149:                            1   branches:uH:   call                             d44839 caml_thread_yield+0xb9 (foo.exe) =>           d6c8d0 caml_memprof_leave_thread+0x0 (foo.exe)
    4589/4589  108652.292047149:                            1   branches:uH:   return                           d6c8db caml_memprof_leave_thread+0xb (foo.exe) =>           d4483e caml_thread_yield+0xbe (foo.exe)
    4589/4589  108652.292047149:                            1   branches:uH:   call                             d44845 caml_thread_yield+0xc5 (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292047156:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    ->    254ns END   caml_get_local_arenas
    ->    254ns BEGIN caml_memprof_leave_thread
    ->    257ns END   caml_memprof_leave_thread
    ->    257ns BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292047210:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d4484a caml_thread_yield+0xca (foo.exe)
    ->    261ns END   pthread_mutex_lock@plt
    ->    261ns BEGIN pthread_mutex_lock
    4589/4589  108652.292047221:                            1   branches:uH:   call                             d44873 caml_thread_yield+0xf3 (foo.exe) =>           d437a0 custom_condvar_signal+0x0 (foo.exe)
    ->    315ns END   pthread_mutex_lock
    4589/4589  108652.292047221:                            1   branches:uH:   call                             d437c9 custom_condvar_signal+0x29 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292047229:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    ->    326ns BEGIN custom_condvar_signal
    ->    330ns BEGIN syscall@plt
    4589/4589  108652.292047245:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    ->    334ns END   syscall@plt
    ->    334ns BEGIN syscall
    4589/4589  108652.292048074:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    ->    350ns BEGIN [syscall]
    4589/4589  108652.292048082:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d437ce custom_condvar_signal+0x2e (foo.exe)
    ->  1.179us END   [syscall]
    4589/4589  108652.292048084:                            1   branches:uH:   return                           d437d4 custom_condvar_signal+0x34 (foo.exe) =>           d44878 caml_thread_yield+0xf8 (foo.exe)
    ->  1.187us END   syscall
    4589/4589  108652.292048084:                            1   branches:uH:   call                             d4489e caml_thread_yield+0x11e (foo.exe) =>           d43750 custom_condvar_wait+0x0 (foo.exe)
    4589/4589  108652.292048084:                            1   branches:uH:   call                             d43764 custom_condvar_wait+0x14 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292048087:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    ->  1.189us END   custom_condvar_signal
    ->  1.189us BEGIN custom_condvar_wait
    ->   1.19us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292048088:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43769 custom_condvar_wait+0x19 (foo.exe)
    ->  1.192us END   pthread_mutex_unlock@plt
    ->  1.192us BEGIN pthread_mutex_unlock
    4589/4589  108652.292048088:                            1   branches:uH:   call                             d43788 custom_condvar_wait+0x38 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292048096:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    ->  1.193us END   pthread_mutex_unlock
    ->  1.193us BEGIN syscall@plt
    4589/4589  108652.292048111:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    ->  1.201us END   syscall@plt
    ->  1.201us BEGIN syscall
    4589/4589  108652.292059441:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    ->  1.216us BEGIN [syscall]
    4589/4589  108652.292059457:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d4378d custom_condvar_wait+0x3d (foo.exe)
    -> 12.546us END   [syscall]
    4589/4589  108652.292059457:                            1   branches:uH:   call                             d43790 custom_condvar_wait+0x40 (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292059485:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 12.562us END   syscall
    -> 12.562us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292059556:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43795 custom_condvar_wait+0x45 (foo.exe)
    ->  12.59us END   pthread_mutex_lock@plt
    ->  12.59us BEGIN pthread_mutex_lock
    4589/4589  108652.292059557:                            1   branches:uH:   return                           d4379f custom_condvar_wait+0x4f (foo.exe) =>           d448a3 caml_thread_yield+0x123 (foo.exe)
    -> 12.661us END   pthread_mutex_lock
    4589/4589  108652.292059571:                            1   branches:uH:   call                             d4489e caml_thread_yield+0x11e (foo.exe) =>           d43750 custom_condvar_wait+0x0 (foo.exe)
    -> 12.662us END   custom_condvar_wait
    4589/4589  108652.292059571:                            1   branches:uH:   call                             d43764 custom_condvar_wait+0x14 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292059580:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    -> 12.676us BEGIN custom_condvar_wait
    ->  12.68us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292059594:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43769 custom_condvar_wait+0x19 (foo.exe)
    -> 12.685us END   pthread_mutex_unlock@plt
    -> 12.685us BEGIN pthread_mutex_unlock
    4589/4589  108652.292059594:                            1   branches:uH:   call                             d43788 custom_condvar_wait+0x38 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292059596:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    -> 12.699us END   pthread_mutex_unlock
    -> 12.699us BEGIN syscall@plt
    4589/4589  108652.292059611:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    -> 12.701us END   syscall@plt
    -> 12.701us BEGIN syscall
    4589/4589  108652.292075757:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    -> 12.716us BEGIN [syscall]
    4589/4589  108652.292075805:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d4378d custom_condvar_wait+0x3d (foo.exe)
    -> 28.862us END   [syscall]
    4589/4589  108652.292075805:                            1   branches:uH:   call                             d43790 custom_condvar_wait+0x40 (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292075858:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    ->  28.91us END   syscall
    ->  28.91us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292076004:                            1   branches:uH:   tr end                     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe) =>                0 [unknown] (foo.exe)
    -> 28.963us END   pthread_mutex_lock@plt
    -> 28.963us BEGIN pthread_mutex_lock
    4589/4589  108652.292077837:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 29.109us BEGIN [untraced]
    4589/4589  108652.292077926:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43795 custom_condvar_wait+0x45 (foo.exe)
    -> 30.942us END   [untraced]
    4589/4589  108652.292077927:                            1   branches:uH:   return                           d4379f custom_condvar_wait+0x4f (foo.exe) =>           d448a3 caml_thread_yield+0x123 (foo.exe)
    -> 31.031us END   pthread_mutex_lock
    4589/4589  108652.292077998:                            1   branches:uH:   call                             d4489e caml_thread_yield+0x11e (foo.exe) =>           d43750 custom_condvar_wait+0x0 (foo.exe)
    -> 31.032us END   custom_condvar_wait
    4589/4589  108652.292077998:                            1   branches:uH:   call                             d43764 custom_condvar_wait+0x14 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292078010:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    -> 31.103us BEGIN custom_condvar_wait
    -> 31.109us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292078010:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43769 custom_condvar_wait+0x19 (foo.exe)
    4589/4589  108652.292078010:                            1   branches:uH:   call                             d43788 custom_condvar_wait+0x38 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292078018:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    -> 31.115us END   pthread_mutex_unlock@plt
    -> 31.115us BEGIN pthread_mutex_unlock
    -> 31.119us END   pthread_mutex_unlock
    -> 31.119us BEGIN syscall@plt
    4589/4589  108652.292078035:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    -> 31.123us END   syscall@plt
    -> 31.123us BEGIN syscall
    4589/4589  108652.292085962:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    ->  31.14us BEGIN [syscall]
    4589/4589  108652.292085978:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d4378d custom_condvar_wait+0x3d (foo.exe)
    -> 39.067us END   [syscall]
    4589/4589  108652.292085978:                            1   branches:uH:   call                             d43790 custom_condvar_wait+0x40 (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292086005:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 39.083us END   syscall
    -> 39.083us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292086062:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43795 custom_condvar_wait+0x45 (foo.exe)
    ->  39.11us END   pthread_mutex_lock@plt
    ->  39.11us BEGIN pthread_mutex_lock
    4589/4589  108652.292086068:                            1   branches:uH:   return                           d4379f custom_condvar_wait+0x4f (foo.exe) =>           d448a3 caml_thread_yield+0x123 (foo.exe)
    -> 39.167us END   pthread_mutex_lock
    4589/4589  108652.292086082:                            1   branches:uH:   call                             d4489e caml_thread_yield+0x11e (foo.exe) =>           d43750 custom_condvar_wait+0x0 (foo.exe)
    -> 39.173us END   custom_condvar_wait
    4589/4589  108652.292086082:                            1   branches:uH:   call                             d43764 custom_condvar_wait+0x14 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292086091:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    -> 39.187us BEGIN custom_condvar_wait
    -> 39.191us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292086091:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43769 custom_condvar_wait+0x19 (foo.exe)
    4589/4589  108652.292086091:                            1   branches:uH:   call                             d43788 custom_condvar_wait+0x38 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292086099:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    -> 39.196us END   pthread_mutex_unlock@plt
    -> 39.196us BEGIN pthread_mutex_unlock
    ->   39.2us END   pthread_mutex_unlock
    ->   39.2us BEGIN syscall@plt
    4589/4589  108652.292086115:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    -> 39.204us END   syscall@plt
    -> 39.204us BEGIN syscall
    4589/4589  108652.292094169:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    ->  39.22us BEGIN [syscall]
    4589/4589  108652.292094184:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d4378d custom_condvar_wait+0x3d (foo.exe)
    -> 47.274us END   [syscall]
    4589/4589  108652.292094184:                            1   branches:uH:   call                             d43790 custom_condvar_wait+0x40 (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292094209:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 47.289us END   syscall
    -> 47.289us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292094285:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43795 custom_condvar_wait+0x45 (foo.exe)
    -> 47.314us END   pthread_mutex_lock@plt
    -> 47.314us BEGIN pthread_mutex_lock
    4589/4589  108652.292094291:                            1   branches:uH:   return                           d4379f custom_condvar_wait+0x4f (foo.exe) =>           d448a3 caml_thread_yield+0x123 (foo.exe)
    ->  47.39us END   pthread_mutex_lock
    4589/4589  108652.292094305:                            1   branches:uH:   call                             d448cd caml_thread_yield+0x14d (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    -> 47.396us END   custom_condvar_wait
    4589/4589  108652.292094316:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    ->  47.41us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292094316:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d448d2 caml_thread_yield+0x152 (foo.exe)
    4589/4589  108652.292094316:                            1   branches:uH:   call                             d448d8 caml_thread_yield+0x158 (foo.exe) =>           686400 pthread_getspecific@plt+0x0 (foo.exe)
    4589/4589  108652.292094323:                            1   branches:uH:   jmp                              686400 pthread_getspecific@plt+0x0 (foo.exe) =>     7ffff79c8870 pthread_getspecific+0x0 (foo.exe)
    -> 47.421us END   pthread_mutex_unlock@plt
    -> 47.421us BEGIN pthread_mutex_unlock
    -> 47.424us END   pthread_mutex_unlock
    -> 47.424us BEGIN pthread_getspecific@plt
    4589/4589  108652.292094323:                            1   branches:uH:   return                     7ffff79c88ac pthread_getspecific+0x3c (foo.exe) =>           d448dd caml_thread_yield+0x15d (foo.exe)
    4589/4589  108652.292094323:                            1   branches:uH:   call                             d44928 caml_thread_yield+0x1a8 (foo.exe) =>           d53c40 caml_set_local_arenas+0x0 (foo.exe)
    4589/4589  108652.292094363:                            1   branches:uH:   return                           d53c8b caml_set_local_arenas+0x4b (foo.exe) =>           d4492d caml_thread_yield+0x1ad (foo.exe)
    -> 47.428us END   pthread_getspecific@plt
    -> 47.428us BEGIN pthread_getspecific
    -> 47.448us END   pthread_getspecific
    -> 47.448us BEGIN caml_set_local_arenas
    4589/4589  108652.292094363:                            1   branches:uH:   call                             d44968 caml_thread_yield+0x1e8 (foo.exe) =>           d6c8e0 caml_memprof_enter_thread+0x0 (foo.exe)
    4589/4589  108652.292094363:                            1   branches:uH:   jmp                              d6c8e9 caml_memprof_enter_thread+0x9 (foo.exe) =>           d6ba60 caml_memprof_set_suspended+0x0 (foo.exe)
    4589/4589  108652.292094363:                            1   branches:uH:   call                             d6ba6c caml_memprof_set_suspended+0xc (foo.exe) =>           d6b9c0 caml_memprof_renew_minor_sample+0x0 (foo.exe)
    4589/4589  108652.292094426:                            1   branches:uH:   jmp                              d6b9ed caml_memprof_renew_minor_sample+0x2d (foo.exe) =>           d4df50 caml_update_young_limit+0x0 (foo.exe)
    -> 47.468us END   caml_set_local_arenas
    -> 47.468us BEGIN caml_memprof_enter_thread
    -> 47.489us END   caml_memprof_enter_thread
    -> 47.489us BEGIN caml_memprof_set_suspended
    ->  47.51us BEGIN caml_memprof_renew_minor_sample
    4589/4589  108652.292094434:                            1   branches:uH:   return                           d4df85 caml_update_young_limit+0x35 (foo.exe) =>           d6ba71 caml_memprof_set_suspended+0x11 (foo.exe)
    -> 47.531us END   caml_memprof_renew_minor_sample
    -> 47.531us BEGIN caml_update_young_limit
    4589/4589  108652.292094434:                            1   branches:uH:   jmp                              d6ba81 caml_memprof_set_suspended+0x21 (foo.exe) =>           d6b150 check_action_pending+0x0 (foo.exe)
    4589/4589  108652.292094435:                            1   branches:uH:   return                           d6b180 check_action_pending+0x30 (foo.exe) =>           d4496d caml_thread_yield+0x1ed (foo.exe)
    -> 47.539us END   caml_update_young_limit
    -> 47.539us END   caml_memprof_set_suspended
    -> 47.539us BEGIN check_action_pending
    4589/4589  108652.292094435:                            1   branches:uH:   call                             d4496d caml_thread_yield+0x1ed (foo.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (foo.exe)
    4589/4589  108652.292094435:                            1   branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (foo.exe) =>           d44972 caml_thread_yield+0x1f2 (foo.exe)
    4589/4589  108652.292094435:                            1   branches:uH:   call                             d4497c caml_thread_yield+0x1fc (foo.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (foo.exe)
    4589/4589  108652.292094435:                            1   branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (foo.exe) =>           d44981 caml_thread_yield+0x201 (foo.exe)
    4589/4589  108652.292094438:                            1   branches:uH:   return                           d4498c caml_thread_yield+0x20c (foo.exe) =>           b02d63 Thread.fun_709+0x13 (foo.exe)
    ->  47.54us END   check_action_pending
    ->  47.54us BEGIN caml_process_pending_signals_exn
    -> 47.541us END   caml_process_pending_signals_exn
    -> 47.541us BEGIN caml_raise_async_if_exception
    -> 47.543us END   caml_raise_async_if_exception
    4589/4589  108652.292094453:                            1   branches:uH:   return                           b02d6b Thread.fun_709+0x1b (foo.exe) =>           6efee4 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xc4 (foo.exe)
    -> 47.543us END   caml_thread_yield
    4589/4589  108652.292094496:                            1   branches:uH:   call                             6eff90 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x170 (foo.exe) =>           7821c0 Time_stamp_counter.now_4481+0x0 (foo.exe)
    -> 47.558us END   Thread.fun_709
    4589/4589  108652.292094527:                            1   branches:uH:   jmp                              7821f3 Time_stamp_counter.now_4481+0x33 (foo.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (foo.exe)
    -> 47.601us BEGIN Time_stamp_counter.now_4481
    4589/4589  108652.292094527:                            1   branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (foo.exe) =>           6eff92 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x172 (foo.exe)
    4589/4589  108652.292094527:                            1   branches:uH:   call                             6effb2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x192 (foo.exe) =>           6c8950 caml_apply4+0x0 (foo.exe)
    4589/4589  108652.292094557:                            1   branches:uH:   jmp                              6c896a caml_apply4+0x1a (foo.exe) =>           6d5160 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x0 (foo.exe)
    -> 47.632us END   Time_stamp_counter.now_4481
    -> 47.632us BEGIN Base.Int.of_int_2534
    -> 47.647us END   Base.Int.of_int_2534
    -> 47.647us BEGIN caml_apply4
    4589/4589  108652.292094634:                            1   branches:uH:   call                             6d519f Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x3f (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    -> 47.662us END   caml_apply4
    -> 47.662us BEGIN Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694
    4589/4589  108652.292094635:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           7b8260 Linux_ext.wait_timeout_after_23376+0x0 (foo.exe)
    -> 47.739us BEGIN caml_apply2
    4589/4589  108652.292094635:                            1   branches:uH:   call                             7b8289 Linux_ext.wait_timeout_after_23376+0x29 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292094636:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86350 Base.Int63.fun_4888+0x0 (foo.exe)
    ->  47.74us END   caml_apply2
    ->  47.74us BEGIN Linux_ext.wait_timeout_after_23376
    ->  47.74us BEGIN caml_apply2
    4589/4589  108652.292094637:                            1   branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (foo.exe) =>           7b828e Linux_ext.wait_timeout_after_23376+0x2e (foo.exe)
    -> 47.741us END   caml_apply2
    -> 47.741us BEGIN Base.Int63.fun_4888
    4589/4589  108652.292094637:                            1   branches:uH:   call                             7b82c5 Linux_ext.wait_timeout_after_23376+0x65 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292094638:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           be0bf0 Base.Import0.max_16773+0x0 (foo.exe)
    -> 47.742us END   Base.Int63.fun_4888
    -> 47.742us BEGIN caml_apply2
    4589/4589  108652.292094638:                            1   branches:uH:   return                           be0bf5 Base.Import0.max_16773+0x5 (foo.exe) =>           7b82ca Linux_ext.wait_timeout_after_23376+0x6a (foo.exe)
    4589/4589  108652.292094639:                            1   branches:uH:   call                             7b8314 Linux_ext.wait_timeout_after_23376+0xb4 (foo.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (foo.exe)
    -> 47.743us END   caml_apply2
    -> 47.743us BEGIN Base.Import0.max_16773
    -> 47.744us END   Base.Import0.max_16773
    4589/4589  108652.292094640:                            1   branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (foo.exe) =>           7b8316 Linux_ext.wait_timeout_after_23376+0xb6 (foo.exe)
    -> 47.744us BEGIN Base.Int.of_int_2534
    4589/4589  108652.292094640:                            1   branches:uH:   call                             7b831e Linux_ext.wait_timeout_after_23376+0xbe (foo.exe) =>           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (foo.exe)
    4589/4589  108652.292094640:                            1   branches:uH:   return                           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (foo.exe) =>           7b8320 Linux_ext.wait_timeout_after_23376+0xc0 (foo.exe)
    4589/4589  108652.292094641:                            1   branches:uH:   call                             7b8361 Linux_ext.wait_timeout_after_23376+0x101 (foo.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (foo.exe)
    -> 47.745us END   Base.Int.of_int_2534
    -> 47.745us BEGIN Core.Span_ns.of_int63_ns_6030
    -> 47.746us END   Core.Span_ns.of_int63_ns_6030
    4589/4589  108652.292094646:                            1   branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (foo.exe) =>           7b8363 Linux_ext.wait_timeout_after_23376+0x103 (foo.exe)
    -> 47.746us BEGIN Base.Int.of_int_2534
    4589/4589  108652.292094649:                            1   branches:uH:   call                             7b836b Linux_ext.wait_timeout_after_23376+0x10b (foo.exe) =>           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (foo.exe)
    -> 47.751us END   Base.Int.of_int_2534
    4589/4589  108652.292094656:                            1   branches:uH:   return                           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (foo.exe) =>           7b836d Linux_ext.wait_timeout_after_23376+0x10d (foo.exe)
    -> 47.754us BEGIN Core.Span_ns.of_int63_ns_6030
    4589/4589  108652.292094656:                            1   branches:uH:   call                             7b837a Linux_ext.wait_timeout_after_23376+0x11a (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292094661:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           ae5b10 Core.Span_ns.+_6234+0x0 (foo.exe)
    -> 47.761us END   Core.Span_ns.of_int63_ns_6030
    -> 47.761us BEGIN caml_apply2
    4589/4589  108652.292094662:                            1   branches:uH:   jmp                              ae5b2b Core.Span_ns.+_6234+0x1b (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    -> 47.766us END   caml_apply2
    -> 47.766us BEGIN Core.Span_ns.+_6234
    4589/4589  108652.292094666:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86300 Base.Int63.fun_4898+0x0 (foo.exe)
    -> 47.767us END   Core.Span_ns.+_6234
    -> 47.767us BEGIN caml_apply2
    4589/4589  108652.292094668:                            1   branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (foo.exe) =>           7b837f Linux_ext.wait_timeout_after_23376+0x11f (foo.exe)
    -> 47.771us END   caml_apply2
    -> 47.771us BEGIN Base.Int63.fun_4898
    4589/4589  108652.292094668:                            1   branches:uH:   call                             7b8389 Linux_ext.wait_timeout_after_23376+0x129 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292094675:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c66170 Base.Int./%_2845+0x0 (foo.exe)
    -> 47.773us END   Base.Int63.fun_4898
    -> 47.773us BEGIN caml_apply2
    4589/4589  108652.292094679:                            1   branches:uH:   return                           c66267 Base.Int./%_2845+0xf7 (foo.exe) =>           7b838e Linux_ext.wait_timeout_after_23376+0x12e (foo.exe)
    ->  47.78us END   caml_apply2
    ->  47.78us BEGIN Base.Int./%_2845
    4589/4589  108652.292094689:                            1   branches:uH:   call                             7b8396 Linux_ext.wait_timeout_after_23376+0x136 (foo.exe) =>           c65890 Base.Int.to_int_2530+0x0 (foo.exe)
    -> 47.784us END   Base.Int./%_2845
    4589/4589  108652.292094690:                            1   branches:uH:   return                           c65890 Base.Int.to_int_2530+0x0 (foo.exe) =>           7b8398 Linux_ext.wait_timeout_after_23376+0x138 (foo.exe)
    -> 47.794us BEGIN Base.Int.to_int_2530
    4589/4589  108652.292094690:                            1   branches:uH:   call                             7b83b0 Linux_ext.wait_timeout_after_23376+0x150 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292094710:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd970 Core.Int.fun_13977+0x0 (foo.exe)
    -> 47.795us END   Base.Int.to_int_2530
    -> 47.795us BEGIN caml_apply2
    4589/4589  108652.292094711:                            1   branches:uH:   return                           9dd97f Core.Int.fun_13977+0xf (foo.exe) =>           7b83b5 Linux_ext.wait_timeout_after_23376+0x155 (foo.exe)
    -> 47.815us END   caml_apply2
    -> 47.815us BEGIN Core.Int.fun_13977
    4589/4589  108652.292094711:                            1   branches:uH:   call                             7b8447 Linux_ext.wait_timeout_after_23376+0x1e7 (foo.exe) =>           d6d414 caml_c_call+0x0 (foo.exe)
    4589/4589  108652.292094720:                            1   branches:uH:   jmp                              d6d43c caml_c_call+0x28 (foo.exe) =>           d3a7d0 core_linux_epoll_wait+0x0 (foo.exe)
    -> 47.816us END   Core.Int.fun_13977
    -> 47.816us BEGIN caml_c_call
    4589/4589  108652.292094732:                            1   branches:uH:   call                             d3a884 core_linux_epoll_wait+0xb4 (foo.exe) =>           d4df10 caml_enter_blocking_section+0x0 (foo.exe)
    -> 47.825us END   caml_c_call
    -> 47.825us BEGIN core_linux_epoll_wait
    4589/4589  108652.292094732:                            1   branches:uH:   call                             d4df26 caml_enter_blocking_section+0x16 (foo.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (foo.exe)
    4589/4589  108652.292094732:                            1   branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (foo.exe) =>           d4df2b caml_enter_blocking_section+0x1b (foo.exe)
    4589/4589  108652.292094732:                            1   branches:uH:   call                             d4df33 caml_enter_blocking_section+0x23 (foo.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (foo.exe)
    4589/4589  108652.292094732:                            1   branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (foo.exe) =>           d4df38 caml_enter_blocking_section+0x28 (foo.exe)
    4589/4589  108652.292094736:                            1   branches:uH:   call                             d4df38 caml_enter_blocking_section+0x28 (foo.exe) =>           d43e70 caml_thread_enter_blocking_section+0x0 (foo.exe)
    -> 47.837us BEGIN caml_enter_blocking_section
    -> 47.838us BEGIN caml_process_pending_signals_exn
    -> 47.839us END   caml_process_pending_signals_exn
    -> 47.839us BEGIN caml_raise_async_if_exception
    -> 47.841us END   caml_raise_async_if_exception
    4589/4589  108652.292094736:                            1   branches:uH:   call                             d43ec6 caml_thread_enter_blocking_section+0x56 (foo.exe) =>           d53c20 caml_get_local_arenas+0x0 (foo.exe)
    4589/4589  108652.292094804:                            1   branches:uH:   return                           d53c3e caml_get_local_arenas+0x1e (foo.exe) =>           d43ecb caml_thread_enter_blocking_section+0x5b (foo.exe)
    -> 47.841us BEGIN caml_thread_enter_blocking_section
    -> 47.875us BEGIN caml_get_local_arenas
    4589/4589  108652.292094804:                            1   branches:uH:   call                             d43f05 caml_thread_enter_blocking_section+0x95 (foo.exe) =>           d6c8d0 caml_memprof_leave_thread+0x0 (foo.exe)
    4589/4589  108652.292094804:                            1   branches:uH:   return                           d6c8db caml_memprof_leave_thread+0xb (foo.exe) =>           d43f0a caml_thread_enter_blocking_section+0x9a (foo.exe)
    4589/4589  108652.292094804:                            1   branches:uH:   jmp                              d43f10 caml_thread_enter_blocking_section+0xa0 (foo.exe) =>           d43cb0 st_masterlock_release.constprop.8+0x0 (foo.exe)
    4589/4589  108652.292094804:                            1   branches:uH:   call                             d43cbb st_masterlock_release.constprop.8+0xb (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292094807:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 47.909us END   caml_get_local_arenas
    -> 47.909us BEGIN caml_memprof_leave_thread
    ->  47.91us END   caml_memprof_leave_thread
    ->  47.91us END   caml_thread_enter_blocking_section
    ->  47.91us BEGIN st_masterlock_release.constprop.8
    -> 47.911us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292094818:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43cc0 st_masterlock_release.constprop.8+0x10 (foo.exe)
    -> 47.912us END   pthread_mutex_lock@plt
    -> 47.912us BEGIN pthread_mutex_lock
    4589/4589  108652.292094818:                            1   branches:uH:   call                             d43cd1 st_masterlock_release.constprop.8+0x21 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292094825:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    -> 47.923us END   pthread_mutex_lock
    -> 47.923us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292094825:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43cd6 st_masterlock_release.constprop.8+0x26 (foo.exe)
    4589/4589  108652.292094825:                            1   branches:uH:   jmp                              d43ce1 st_masterlock_release.constprop.8+0x31 (foo.exe) =>           d437a0 custom_condvar_signal+0x0 (foo.exe)
    4589/4589  108652.292094825:                            1   branches:uH:   call                             d437c9 custom_condvar_signal+0x29 (foo.exe) =>           685cc0 syscall@plt+0x0 (foo.exe)
    4589/4589  108652.292094838:                            1   branches:uH:   jmp                              685cc0 syscall@plt+0x0 (foo.exe) =>     7ffff71e0e10 syscall+0x0 (foo.exe)
    ->  47.93us END   pthread_mutex_unlock@plt
    ->  47.93us BEGIN pthread_mutex_unlock
    -> 47.934us END   pthread_mutex_unlock
    -> 47.934us END   st_masterlock_release.constprop.8
    -> 47.934us BEGIN custom_condvar_signal
    -> 47.938us BEGIN syscall@plt
    4589/4589  108652.292094854:                            1   branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (foo.exe) =>                0 [unknown] (foo.exe)
    -> 47.943us END   syscall@plt
    -> 47.943us BEGIN syscall
    4589/4589  108652.292096677:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e0e29 syscall+0x19 (foo.exe)
    -> 47.959us BEGIN [syscall]
    4589/4589  108652.292096687:                            1   branches:uH:   return                     7ffff71e0e31 syscall+0x21 (foo.exe) =>           d437ce custom_condvar_signal+0x2e (foo.exe)
    -> 49.782us END   [syscall]
    4589/4589  108652.292096691:                            1   branches:uH:   return                           d437d4 custom_condvar_signal+0x34 (foo.exe) =>           d4df3e caml_enter_blocking_section+0x2e (foo.exe)
    -> 49.792us END   syscall
    4589/4589  108652.292096704:                            1   branches:uH:   return                           d4df4e caml_enter_blocking_section+0x3e (foo.exe) =>           d3a889 core_linux_epoll_wait+0xb9 (foo.exe)
    -> 49.796us END   custom_condvar_signal
    4589/4589  108652.292096704:                            1   branches:uH:   call                             d3a898 core_linux_epoll_wait+0xc8 (foo.exe) =>           685d40 epoll_wait@plt+0x0 (foo.exe)
    4589/4589  108652.292096717:                            1   branches:uH:   jmp                              685d40 epoll_wait@plt+0x0 (foo.exe) =>     7ffff71e70b0 epoll_wait+0x0 (foo.exe)
    -> 49.809us END   caml_enter_blocking_section
    -> 49.809us BEGIN epoll_wait@plt
    4589/4589  108652.292096726:                            1   branches:uH:   jcc                        7ffff71e70b7 epoll_wait+0x7 (foo.exe) =>     7ffff71e70cc [unknown] (foo.exe)
    -> 49.822us END   epoll_wait@plt
    -> 49.822us BEGIN epoll_wait
    4589/4589  108652.292096726:                            1   branches:uH:   call                       7ffff71e70d0 [unknown] (foo.exe) =>     7ffff71f4830 __libc_enable_asynccancel+0x0 (foo.exe)
    4589/4589  108652.292096726:                            1   branches:uH:   return                     7ffff71f485b __libc_enable_asynccancel+0x2b (foo.exe) =>     7ffff71e70d5 [unknown] (foo.exe)
    4589/4589  108652.292096744:                            1   branches:uH:   tr end  syscall            7ffff71e70e1 [unknown] (foo.exe) =>                0 [unknown] (foo.exe)
    -> 49.831us END   epoll_wait
    -> 49.831us BEGIN [unknown @ 0x7ffff71e70cc (foo.exe)]
    -> 49.837us BEGIN __libc_enable_asynccancel
    -> 49.843us END   __libc_enable_asynccancel
    -> 49.843us END   [unknown @ 0x7ffff71e70cc (foo.exe)]
    -> 49.843us BEGIN [unknown @ 0x7ffff71e70d5 (foo.exe)]
    4589/4589  108652.292097276:                            1   branches:uH:   tr strt                               0 [unknown] (foo.exe) =>     7ffff71e70e3 [unknown] (foo.exe)
    -> 49.849us BEGIN [syscall]
    4589/4589  108652.292097276:                            1   branches:uH:   call                       7ffff71e70ea [unknown] (foo.exe) =>     7ffff71f4890 __libc_disable_asynccancel+0x0 (foo.exe)
    4589/4589  108652.292097287:                            1   branches:uH:   return                     7ffff71f48bf __libc_disable_asynccancel+0x2f (foo.exe) =>     7ffff71e70ef [unknown] (foo.exe)
    -> 50.381us END   [syscall]
    -> 50.381us BEGIN __libc_disable_asynccancel
    4589/4589  108652.292097293:                            1   branches:uH:   return                     7ffff71e70fe [unknown] (foo.exe) =>           d3a89d core_linux_epoll_wait+0xcd (foo.exe)
    -> 50.392us END   __libc_disable_asynccancel
    -> 50.392us END   [unknown @ 0x7ffff71e70d5 (foo.exe)]
    -> 50.392us BEGIN [unknown @ 0x7ffff71e70ef (foo.exe)]
    4589/4589  108652.292097293:                            1   branches:uH:   call                             d3a8a0 core_linux_epoll_wait+0xd0 (foo.exe) =>           d4dc90 caml_leave_blocking_section+0x0 (foo.exe)
    4589/4589  108652.292097293:                            1   branches:uH:   call                             d4dc96 caml_leave_blocking_section+0x6 (foo.exe) =>           685c00 __errno_location@plt+0x0 (foo.exe)
    4589/4589  108652.292097295:                            1   branches:uH:   jmp                              685c00 __errno_location@plt+0x0 (foo.exe) =>     7ffff79ccda0 __errno_location+0x0 (foo.exe)
    -> 50.398us END   [unknown @ 0x7ffff71e70ef (foo.exe)]
    -> 50.398us BEGIN caml_leave_blocking_section
    -> 50.399us BEGIN __errno_location@plt
    4589/4589  108652.292097297:                            1   branches:uH:   return                     7ffff79ccdb0 __errno_location+0x10 (foo.exe) =>           d4dc9b caml_leave_blocking_section+0xb (foo.exe)
    ->   50.4us END   __errno_location@plt
    ->   50.4us BEGIN __errno_location
    4589/4589  108652.292097301:                            1   branches:uH:   call                             d4dca0 caml_leave_blocking_section+0x10 (foo.exe) =>           d43dc0 caml_thread_leave_blocking_section+0x0 (foo.exe)
    -> 50.402us END   __errno_location
    4589/4589  108652.292097301:                            1   branches:uH:   call                             d43dc1 caml_thread_leave_blocking_section+0x1 (foo.exe) =>           d43cf0 st_masterlock_acquire.constprop.9+0x0 (foo.exe)
    4589/4589  108652.292097301:                            1   branches:uH:   call                             d43cfb st_masterlock_acquire.constprop.9+0xb (foo.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (foo.exe)
    4589/4589  108652.292097302:                            1   branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (foo.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (foo.exe)
    -> 50.406us BEGIN caml_thread_leave_blocking_section
    -> 50.406us BEGIN st_masterlock_acquire.constprop.9
    -> 50.406us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292097302:                            1   branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (foo.exe) =>           d43d00 st_masterlock_acquire.constprop.9+0x10 (foo.exe)
    4589/4589  108652.292097302:                            1   branches:uH:   jmp                              d43d60 st_masterlock_acquire.constprop.9+0x70 (foo.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe)
    4589/4589  108652.292097310:                            1   branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (foo.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (foo.exe)
    -> 50.407us END   pthread_mutex_lock@plt
    -> 50.407us BEGIN pthread_mutex_lock
    -> 50.411us END   pthread_mutex_lock
    -> 50.411us END   st_masterlock_acquire.constprop.9
    -> 50.411us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292097317:                            1   branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (foo.exe) =>           d43dc6 caml_thread_leave_blocking_section+0x6 (foo.exe)
    -> 50.415us END   pthread_mutex_unlock@plt
    -> 50.415us BEGIN pthread_mutex_unlock
    4589/4589  108652.292097317:                            1   branches:uH:   call                             d43dcc caml_thread_leave_blocking_section+0xc (foo.exe) =>           686400 pthread_getspecific@plt+0x0 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   jmp                              686400 pthread_getspecific@plt+0x0 (foo.exe) =>     7ffff79c8870 pthread_getspecific+0x0 (foo.exe)
    -> 50.422us END   pthread_mutex_unlock
    -> 50.422us BEGIN pthread_getspecific@plt
    4589/4589  108652.292097318:                            1   branches:uH:   return                     7ffff79c88ac pthread_getspecific+0x3c (foo.exe) =>           d43dd1 caml_thread_leave_blocking_section+0x11 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   call                             d43e22 caml_thread_leave_blocking_section+0x62 (foo.exe) =>           d53c40 caml_set_local_arenas+0x0 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   return                           d53c8b caml_set_local_arenas+0x4b (foo.exe) =>           d43e27 caml_thread_leave_blocking_section+0x67 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   jmp                              d43e62 caml_thread_leave_blocking_section+0xa2 (foo.exe) =>           d6c8e0 caml_memprof_enter_thread+0x0 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   jmp                              d6c8e9 caml_memprof_enter_thread+0x9 (foo.exe) =>           d6ba60 caml_memprof_set_suspended+0x0 (foo.exe)
    4589/4589  108652.292097318:                            1   branches:uH:   call                             d6ba6c caml_memprof_set_suspended+0xc (foo.exe) =>           d6b9c0 caml_memprof_renew_minor_sample+0x0 (foo.exe)
    4589/4589  108652.292097337:                            1   branches:uH:   jmp                              d6b9ed caml_memprof_renew_minor_sample+0x2d (foo.exe) =>           d4df50 caml_update_young_limit+0x0 (foo.exe)
    -> 50.423us END   pthread_getspecific@plt
    -> 50.423us BEGIN pthread_getspecific
    -> 50.426us END   pthread_getspecific
    -> 50.426us BEGIN caml_set_local_arenas
    ->  50.43us END   caml_set_local_arenas
    ->  50.43us END   caml_thread_leave_blocking_section
    ->  50.43us BEGIN caml_memprof_enter_thread
    -> 50.434us END   caml_memprof_enter_thread
    -> 50.434us BEGIN caml_memprof_set_suspended
    -> 50.438us BEGIN caml_memprof_renew_minor_sample
    4589/4589  108652.292097337:                            1   branches:uH:   return                           d4df85 caml_update_young_limit+0x35 (foo.exe) =>           d6ba71 caml_memprof_set_suspended+0x11 (foo.exe)
    4589/4589  108652.292097337:                            1   branches:uH:   jmp                              d6ba81 caml_memprof_set_suspended+0x21 (foo.exe) =>           d6b150 check_action_pending+0x0 (foo.exe)
    4589/4589  108652.292097343:                            1   branches:uH:   return                           d6b180 check_action_pending+0x30 (foo.exe) =>           d4dca6 caml_leave_blocking_section+0x16 (foo.exe)
    -> 50.442us END   caml_memprof_renew_minor_sample
    -> 50.442us BEGIN caml_update_young_limit
    -> 50.445us END   caml_update_young_limit
    -> 50.445us END   caml_memprof_set_suspended
    -> 50.445us BEGIN check_action_pending
    4589/4589  108652.292097380:                            1   branches:uH:   return                           d4dd03 caml_leave_blocking_section+0x73 (foo.exe) =>           d3a8a5 core_linux_epoll_wait+0xd5 (foo.exe)
    -> 50.448us END   check_action_pending
    4589/4589  108652.292097381:                            1   branches:uH:   return                           d3a877 core_linux_epoll_wait+0xa7 (foo.exe) =>           7b844c Linux_ext.wait_timeout_after_23376+0x1ec (foo.exe)
    -> 50.485us END   caml_leave_blocking_section
    4589/4589  108652.292097381:                            1   branches:uH:   call                             7b846f Linux_ext.wait_timeout_after_23376+0x20f (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097393:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd950 Core.Int.fun_13981+0x0 (foo.exe)
    -> 50.486us END   core_linux_epoll_wait
    -> 50.486us BEGIN caml_apply2
    4589/4589  108652.292097393:                            1   branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (foo.exe) =>           7b8474 Linux_ext.wait_timeout_after_23376+0x214 (foo.exe)
    4589/4589  108652.292097394:                            1   branches:uH:   return                           7b848d Linux_ext.wait_timeout_after_23376+0x22d (foo.exe) =>           6d51a4 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x44 (foo.exe)
    -> 50.498us END   caml_apply2
    -> 50.498us BEGIN Core.Int.fun_13981
    -> 50.499us END   Core.Int.fun_13981
    4589/4589  108652.292097517:                            1   branches:uH:   return                           6d5253 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0xf3 (foo.exe) =>           6effb7 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x197 (foo.exe)
    -> 50.499us END   Linux_ext.wait_timeout_after_23376
    4589/4589  108652.292097531:                            1   branches:uH:   call                             6effd2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1b2 (foo.exe) =>           7821c0 Time_stamp_counter.now_4481+0x0 (foo.exe)
    -> 50.622us END   Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694
    4589/4589  108652.292097535:                            1   branches:uH:   jmp                              7821f3 Time_stamp_counter.now_4481+0x33 (foo.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (foo.exe)
    -> 50.636us BEGIN Time_stamp_counter.now_4481
    4589/4589  108652.292097535:                            1   branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (foo.exe) =>           6effd4 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1b4 (foo.exe)
    4589/4589  108652.292097535:                            1   branches:uH:   call                             6efff9 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1d9 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097547:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           782140 Time_stamp_counter.diff_4466+0x0 (foo.exe)
    ->  50.64us END   Time_stamp_counter.now_4481
    ->  50.64us BEGIN Base.Int.of_int_2534
    -> 50.646us END   Base.Int.of_int_2534
    -> 50.646us BEGIN caml_apply2
    4589/4589  108652.292097547:                            1   branches:uH:   jmp                              78215b Time_stamp_counter.diff_4466+0x1b (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097548:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c862f0 Base.Int63.fun_4900+0x0 (foo.exe)
    -> 50.652us END   caml_apply2
    -> 50.652us BEGIN Time_stamp_counter.diff_4466
    -> 50.652us END   Time_stamp_counter.diff_4466
    -> 50.652us BEGIN caml_apply2
    4589/4589  108652.292097549:                            1   branches:uH:   return                           c862f7 Base.Int63.fun_4900+0x7 (foo.exe) =>           6efffe Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1de (foo.exe)
    -> 50.653us END   caml_apply2
    -> 50.653us BEGIN Base.Int63.fun_4900
    4589/4589  108652.292097549:                            1   branches:uH:   call                             6f000e Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1ee (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097570:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           c86300 Base.Int63.fun_4898+0x0 (foo.exe)
    -> 50.654us END   Base.Int63.fun_4900
    -> 50.654us BEGIN caml_apply2
    4589/4589  108652.292097570:                            1   branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (foo.exe) =>           6f0013 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1f3 (foo.exe)
    4589/4589  108652.292097571:                            1   branches:uH:   call                             6f0059 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x239 (foo.exe) =>           7aeb60 Nano_mutex.lock_exn_5235+0x0 (foo.exe)
    -> 50.675us END   caml_apply2
    -> 50.675us BEGIN Base.Int63.fun_4898
    -> 50.676us END   Base.Int63.fun_4898
    4589/4589  108652.292097571:                            1   branches:uH:   call                             7aeb78 Nano_mutex.lock_exn_5235+0x18 (foo.exe) =>           7aea00 Nano_mutex.lock_5231+0x0 (foo.exe)
    4589/4589  108652.292097589:                            1   branches:uH:   call                             7aea24 Nano_mutex.lock_5231+0x24 (foo.exe) =>           b02db0 Thread.fun_715+0x0 (foo.exe)
    -> 50.676us BEGIN Nano_mutex.lock_exn_5235
    -> 50.685us BEGIN Nano_mutex.lock_5231
    4589/4589  108652.292097589:                            1   branches:uH:   call                             b02db7 Thread.fun_715+0x7 (foo.exe) =>           d44690 caml_thread_self+0x0 (foo.exe)
    4589/4589  108652.292097590:                            1   branches:uH:   return                           d4469f caml_thread_self+0xf (foo.exe) =>           b02dbc Thread.fun_715+0xc (foo.exe)
    -> 50.694us BEGIN Thread.fun_715
    -> 50.694us BEGIN caml_thread_self
    4589/4589  108652.292097590:                            1   branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (foo.exe) =>           7aea26 Nano_mutex.lock_5231+0x26 (foo.exe)
    4589/4589  108652.292097592:                            1   branches:uH:   call                             7aea2d Nano_mutex.lock_5231+0x2d (foo.exe) =>           b02d90 Thread.fun_713+0x0 (foo.exe)
    -> 50.695us END   caml_thread_self
    -> 50.695us END   Thread.fun_715
    4589/4589  108652.292097592:                            1   branches:uH:   call                             b02d97 Thread.fun_713+0x7 (foo.exe) =>           d446b0 caml_thread_id+0x0 (foo.exe)
    4589/4589  108652.292097593:                            1   branches:uH:   return                           d446b3 caml_thread_id+0x3 (foo.exe) =>           b02d9c Thread.fun_713+0xc (foo.exe)
    -> 50.697us BEGIN Thread.fun_713
    -> 50.697us BEGIN caml_thread_id
    4589/4589  108652.292097593:                            1   branches:uH:   return                           b02da0 Thread.fun_713+0x10 (foo.exe) =>           7aea2f Nano_mutex.lock_5231+0x2f (foo.exe)
    4589/4589  108652.292097593:                            1   branches:uH:   call                             7aea50 Nano_mutex.lock_5231+0x50 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097641:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd950 Core.Int.fun_13981+0x0 (foo.exe)
    -> 50.698us END   caml_thread_id
    -> 50.698us END   Thread.fun_713
    -> 50.698us BEGIN caml_apply2
    4589/4589  108652.292097641:                            1   branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (foo.exe) =>           7aea55 Nano_mutex.lock_5231+0x55 (foo.exe)
    4589/4589  108652.292097641:                            1   branches:uH:   call                             7aea64 Nano_mutex.lock_5231+0x64 (foo.exe) =>           d53b20 caml_modify+0x0 (foo.exe)
    4589/4589  108652.292097643:                            1   branches:uH:   return                           d53b48 caml_modify+0x28 (foo.exe) =>           7aea69 Nano_mutex.lock_5231+0x69 (foo.exe)
    -> 50.746us END   caml_apply2
    -> 50.746us BEGIN Core.Int.fun_13981
    -> 50.747us END   Core.Int.fun_13981
    -> 50.747us BEGIN caml_modify
    4589/4589  108652.292097643:                            1   branches:uH:   return                           7aea74 Nano_mutex.lock_5231+0x74 (foo.exe) =>           7aeb7d Nano_mutex.lock_exn_5235+0x1d (foo.exe)
    4589/4589  108652.292097644:                            1   branches:uH:   jmp                              7aeb88 Nano_mutex.lock_exn_5235+0x28 (foo.exe) =>           c15330 Base.Or_error.ok_exn_2208+0x0 (foo.exe)
    -> 50.748us END   caml_modify
    -> 50.748us END   Nano_mutex.lock_5231
    4589/4589  108652.292097644:                            1   branches:uH:   return                           c15407 Base.Or_error.ok_exn_2208+0xd7 (foo.exe) =>           6f005b Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x23b (foo.exe)
    4589/4589  108652.292097644:                            1   branches:uH:   call                             6f0064 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x244 (foo.exe) =>           6df5d0 Async_unix.Interruptor.clear_4845+0x0 (foo.exe)
    4589/4589  108652.292097644:                            1   branches:uH:   call                             6df662 Async_unix.Interruptor.clear_4845+0x92 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097653:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           79d9e0 Read_write_pair.get_2289+0x0 (foo.exe)
    -> 50.749us END   Nano_mutex.lock_exn_5235
    -> 50.749us BEGIN Base.Or_error.ok_exn_2208
    -> 50.752us END   Base.Or_error.ok_exn_2208
    -> 50.752us BEGIN Async_unix.Interruptor.clear_4845
    -> 50.755us BEGIN caml_apply2
    4589/4589  108652.292097653:                            1   branches:uH:   return                           79d9ec Read_write_pair.get_2289+0xc (foo.exe) =>           6df667 Async_unix.Interruptor.clear_4845+0x97 (foo.exe)
    4589/4589  108652.292097653:                            1   branches:uH:   call                             6df67b Async_unix.Interruptor.clear_4845+0xab (foo.exe) =>           6dc310 Async_unix.Raw_fd.syscall_5838+0x0 (foo.exe)
    4589/4589  108652.292097672:                            1   branches:uH:   call                             6dc3a9 Async_unix.Raw_fd.syscall_5838+0x99 (foo.exe) =>           6dbef0 Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446+0x0 (foo.exe)
    -> 50.758us END   caml_apply2
    -> 50.758us BEGIN Read_write_pair.get_2289
    -> 50.767us END   Read_write_pair.get_2289
    -> 50.767us BEGIN Async_unix.Raw_fd.syscall_5838
    4589/4589  108652.292097677:                            1   branches:uH:   return                           6dbf88 Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446+0x98 (foo.exe) =>           6dc3ae Async_unix.Raw_fd.syscall_5838+0x9e (foo.exe)
    -> 50.777us BEGIN Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446
    4589/4589  108652.292097683:                            1   branches:uH:   call                             6dc3be Async_unix.Raw_fd.syscall_5838+0xae (foo.exe) =>           6dc450 Async_unix.Raw_fd.fun_7461+0x0 (foo.exe)
    -> 50.782us END   Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446
    4589/4589  108652.292097696:                            1   branches:uH:   call                             6dc4d0 Async_unix.Raw_fd.fun_7461+0x80 (foo.exe) =>           6dc580 Async_unix.Raw_fd.fun_7471+0x0 (foo.exe)
    -> 50.788us BEGIN Async_unix.Raw_fd.fun_7461
    4589/4589  108652.292097696:                            1   branches:uH:   jmp                              6dc59b Async_unix.Raw_fd.fun_7471+0x1b (foo.exe) =>           6df780 Async_unix.Interruptor.fun_5020+0x0 (foo.exe)
    4589/4589  108652.292097696:                            1   branches:uH:   call                             6df833 Async_unix.Interruptor.fun_5020+0xb3 (foo.exe) =>           6c8950 caml_apply4+0x0 (foo.exe)
    4589/4589  108652.292097737:                            1   branches:uH:   jmp                              6c896a caml_apply4+0x1a (foo.exe) =>           8f0410 Core_unix.read_assume_fd_is_nonblocking_5385+0x0 (foo.exe)
    -> 50.801us BEGIN Async_unix.Raw_fd.fun_7471
    -> 50.814us END   Async_unix.Raw_fd.fun_7471
    -> 50.814us BEGIN Async_unix.Interruptor.fun_5020
    -> 50.828us BEGIN caml_apply4
    4589/4589  108652.292097737:                            1   branches:uH:   call                             8f0443 Core_unix.read_assume_fd_is_nonblocking_5385+0x33 (foo.exe) =>           6c8840 caml_apply2+0x0 (foo.exe)
    4589/4589  108652.292097738:                            1   branches:uH:   jmp                              6c885a caml_apply2+0x1a (foo.exe) =>           9dd930 Core.Int.fun_13985+0x0 (foo.exe)
    -> 50.842us END   caml_apply4
    -> 50.842us BEGIN Core_unix.read_assume_fd_is_nonblocking_5385
    -> 50.842us BEGIN caml_apply2
    END
    ->      0ns BEGIN Async_unix.Raw_scheduler.loop_13465 [inferred start time]
    ->      0ns BEGIN Async_unix.Raw_scheduler.one_iter_13456 [inferred start time]
    ->      0ns BEGIN Async_kernel.Scheduler.run_cycle_7957 [inferred start time]
    ->      0ns BEGIN Core.Span_ns.since_unix_epoch_9948 [inferred start time]
    ->      0ns BEGIN [unknown]
    ->      0ns END   [unknown]
    ->      0ns BEGIN Time_now.nanoseconds_since_unix_epoch_1088 [inferred start time]
    -> 50.843us END   caml_apply2
    -> 50.843us BEGIN Core.Int.fun_13985
    -> 50.843us END   Core.Int.fun_13985
    -> 50.843us END   Core_unix.read_assume_fd_is_nonblocking_5385
    -> 50.843us END   Async_unix.Interruptor.fun_5020
    -> 50.843us END   Async_unix.Raw_fd.fun_7461
    -> 50.843us END   Async_unix.Raw_fd.syscall_5838
    -> 50.843us END   Async_unix.Interruptor.clear_4845
    -> 50.843us END   Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    -> 50.843us END   Async_unix.Raw_scheduler.one_iter_13456
    -> 50.843us END   Async_unix.Raw_scheduler.loop_13465 |}]
;;
