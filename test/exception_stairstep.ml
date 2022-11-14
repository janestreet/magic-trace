open! Core
open! Async

type traps =
  { pushtraps : int64 array
  ; poptraps : int64 array
  ; entertraps : int64 array
  }
[@@deriving sexp]

let%expect_test "A raise_notrace OCaml exception" =
  let { pushtraps; poptraps; entertraps } =
    Perf_script.resolve_file "exception_stairstep.traps"
    |> Sexp.of_string
    |> [%of_sexp: traps]
  in
  let ocaml_exception_info =
    Magic_trace_core.Ocaml_exception_info.create ~entertraps ~pushtraps ~poptraps
  in
  let%map () =
    Perf_script.run
      ~ocaml_exception_info
      ~trace_scope:Userspace
      "exception_stairstep.perf"
  in
  [%expect {|
    4589/4589  108652.292046895:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           bcd5dc Time_now.nanoseconds_since_unix_epoch_1088+0x2c (/tmp/clark.exe)
    4589/4589  108652.292046896:                                1 branches:uH:   return                           bcd5ea Time_now.nanoseconds_since_unix_epoch_1088+0x3a (/tmp/clark.exe) =>           ae9608 Core.Span_ns.since_unix_epoch_9948+0x18 (/tmp/clark.exe)
    4589/4589  108652.292046897:                                1 branches:uH:   return                           ae960c Core.Span_ns.since_unix_epoch_9948+0x1c (/tmp/clark.exe) =>           81f0d1 Async_kernel.Scheduler.run_cycle_7957+0x5a1 (/tmp/clark.exe)
    ->      1ns END   Time_now.nanoseconds_since_unix_epoch_1088
    4589/4589  108652.292046897:                                1 branches:uH:   call                             81f0da Async_kernel.Scheduler.run_cycle_7957+0x5aa (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046899:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           ae5b40 Core.Span_ns.-_6237+0x0 (/tmp/clark.exe)
    ->      2ns END   Core.Span_ns.since_unix_epoch_9948
    ->      2ns BEGIN caml_apply2
    4589/4589  108652.292046899:                                1 branches:uH:   jmp                              ae5b5b Core.Span_ns.-_6237+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046900:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c862f0 Base.Int63.fun_4900+0x0 (/tmp/clark.exe)
    ->      4ns END   caml_apply2
    ->      4ns BEGIN Core.Span_ns.-_6237
    ->      4ns END   Core.Span_ns.-_6237
    ->      4ns BEGIN caml_apply2
    4589/4589  108652.292046900:                                1 branches:uH:   return                           c862f7 Base.Int63.fun_4900+0x7 (/tmp/clark.exe) =>           81f0df Async_kernel.Scheduler.run_cycle_7957+0x5af (/tmp/clark.exe)
    4589/4589  108652.292046900:                                1 branches:uH:   call                             81f123 Async_kernel.Scheduler.run_cycle_7957+0x5f3 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046910:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           ae5b10 Core.Span_ns.+_6234+0x0 (/tmp/clark.exe)
    ->      5ns END   caml_apply2
    ->      5ns BEGIN Base.Int63.fun_4900
    ->     10ns END   Base.Int63.fun_4900
    ->     10ns BEGIN caml_apply2
    4589/4589  108652.292046910:                                1 branches:uH:   jmp                              ae5b2b Core.Span_ns.+_6234+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046911:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86300 Base.Int63.fun_4898+0x0 (/tmp/clark.exe)
    ->     15ns END   caml_apply2
    ->     15ns BEGIN Core.Span_ns.+_6234
    ->     15ns END   Core.Span_ns.+_6234
    ->     15ns BEGIN caml_apply2
    4589/4589  108652.292046911:                                1 branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (/tmp/clark.exe) =>           81f128 Async_kernel.Scheduler.run_cycle_7957+0x5f8 (/tmp/clark.exe)
    4589/4589  108652.292046911:                                1 branches:uH:   call                             81f1f1 Async_kernel.Scheduler.run_cycle_7957+0x6c1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046913:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           be4a40 Base.Array0.iter_1696+0x0 (/tmp/clark.exe)
    ->     16ns END   caml_apply2
    ->     16ns BEGIN Base.Int63.fun_4898
    ->     17ns END   Base.Int63.fun_4898
    ->     17ns BEGIN caml_apply2
    4589/4589  108652.292046913:                                1 branches:uH:   return                           be4ae1 Base.Array0.iter_1696+0xa1 (/tmp/clark.exe) =>           81f1f6 Async_kernel.Scheduler.run_cycle_7957+0x6c6 (/tmp/clark.exe)
    4589/4589  108652.292046915:                                1 branches:uH:   return                           81f485 Async_kernel.Scheduler.run_cycle_7957+0x955 (/tmp/clark.exe) =>           6f0f24 Async_unix.Raw_scheduler.one_iter_13456+0x254 (/tmp/clark.exe)
    ->     18ns END   caml_apply2
    ->     18ns BEGIN Base.Array0.iter_1696
    ->     20ns END   Base.Array0.iter_1696
    4589/4589  108652.292046920:                                1 branches:uH:   call                             6f0f61 Async_unix.Raw_scheduler.one_iter_13456+0x291 (/tmp/clark.exe) =>           ae5020 Core.Span_ns.of_int_us_6033+0x0 (/tmp/clark.exe)
    ->     20ns END   Async_kernel.Scheduler.run_cycle_7957
    4589/4589  108652.292046921:                                1 branches:uH:   call                             ae5058 Core.Span_ns.of_int_us_6033+0x38 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    ->     25ns BEGIN Core.Span_ns.of_int_us_6033
    4589/4589  108652.292046921:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           ae505a Core.Span_ns.of_int_us_6033+0x3a (/tmp/clark.exe)
    4589/4589  108652.292046921:                                1 branches:uH:   jmp                              ae5067 Core.Span_ns.of_int_us_6033+0x47 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046923:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c862e0 Base.Int63.fun_4902+0x0 (/tmp/clark.exe)
    ->     26ns BEGIN Base.Int.of_int_2534
    ->     27ns END   Base.Int.of_int_2534
    ->     27ns END   Core.Span_ns.of_int_us_6033
    ->     27ns BEGIN caml_apply2
    4589/4589  108652.292046923:                                1 branches:uH:   return                           c862ef Base.Int63.fun_4902+0xf (/tmp/clark.exe) =>           6f0f63 Async_unix.Raw_scheduler.one_iter_13456+0x293 (/tmp/clark.exe)
    4589/4589  108652.292046923:                                1 branches:uH:   call                             6f0f6f Async_unix.Raw_scheduler.one_iter_13456+0x29f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046924:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    ->     28ns END   caml_apply2
    ->     28ns BEGIN Base.Int63.fun_4902
    ->     28ns END   Base.Int63.fun_4902
    ->     28ns BEGIN caml_apply2
    4589/4589  108652.292046925:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           6f0f74 Async_unix.Raw_scheduler.one_iter_13456+0x2a4 (/tmp/clark.exe)
    ->     29ns END   caml_apply2
    ->     29ns BEGIN Base.Int63.fun_4892
    4589/4589  108652.292046926:                                1 branches:uH:   call                             6f0fcb Async_unix.Raw_scheduler.one_iter_13456+0x2fb (/tmp/clark.exe) =>           b02db0 Thread.fun_715+0x0 (/tmp/clark.exe)
    ->     30ns END   Base.Int63.fun_4892
    4589/4589  108652.292046926:                                1 branches:uH:   call                             b02db7 Thread.fun_715+0x7 (/tmp/clark.exe) =>           d44690 caml_thread_self+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046926:                                1 branches:uH:   return                           d4469f caml_thread_self+0xf (/tmp/clark.exe) =>           b02dbc Thread.fun_715+0xc (/tmp/clark.exe)
    4589/4589  108652.292046926:                                1 branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (/tmp/clark.exe) =>           6f0fcd Async_unix.Raw_scheduler.one_iter_13456+0x2fd (/tmp/clark.exe)
    4589/4589  108652.292046927:                                1 branches:uH:   call                             6f0fd4 Async_unix.Raw_scheduler.one_iter_13456+0x304 (/tmp/clark.exe) =>           b02d90 Thread.fun_713+0x0 (/tmp/clark.exe)
    ->     31ns BEGIN Thread.fun_715
    ->     31ns BEGIN caml_thread_self
    ->     32ns END   caml_thread_self
    ->     32ns END   Thread.fun_715
    4589/4589  108652.292046927:                                1 branches:uH:   call                             b02d97 Thread.fun_713+0x7 (/tmp/clark.exe) =>           d446b0 caml_thread_id+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046928:                                1 branches:uH:   return                           d446b3 caml_thread_id+0x3 (/tmp/clark.exe) =>           b02d9c Thread.fun_713+0xc (/tmp/clark.exe)
    ->     32ns BEGIN Thread.fun_713
    ->     32ns BEGIN caml_thread_id
    4589/4589  108652.292046928:                                1 branches:uH:   return                           b02da0 Thread.fun_713+0x10 (/tmp/clark.exe) =>           6f0fd6 Async_unix.Raw_scheduler.one_iter_13456+0x306 (/tmp/clark.exe)
    4589/4589  108652.292046928:                                1 branches:uH:   call                             6f0fe0 Async_unix.Raw_scheduler.one_iter_13456+0x310 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046929:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    ->     33ns END   caml_thread_id
    ->     33ns END   Thread.fun_713
    ->     33ns BEGIN caml_apply2
    4589/4589  108652.292046930:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           6f0fe5 Async_unix.Raw_scheduler.one_iter_13456+0x315 (/tmp/clark.exe)
    ->     34ns END   caml_apply2
    ->     34ns BEGIN Core.Int.fun_13981
    4589/4589  108652.292046930:                                1 branches:uH:   return                           6f0ff4 Async_unix.Raw_scheduler.one_iter_13456+0x324 (/tmp/clark.exe) =>           6f1549 Async_unix.Raw_scheduler.loop_13465+0xd9 (/tmp/clark.exe)
    4589/4589  108652.292046954:                                1 branches:uH:   call                             6f14a0 Async_unix.Raw_scheduler.loop_13465+0x30 (/tmp/clark.exe) =>           820330 Async_kernel.Scheduler.check_invariants_8475+0x0 (/tmp/clark.exe)
    ->     35ns END   Core.Int.fun_13981
    ->     35ns END   Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292046955:                                1 branches:uH:   return                           820337 Async_kernel.Scheduler.check_invariants_8475+0x7 (/tmp/clark.exe) =>           6f14a2 Async_unix.Raw_scheduler.loop_13465+0x32 (/tmp/clark.exe)
    ->     59ns BEGIN Async_kernel.Scheduler.check_invariants_8475
    4589/4589  108652.292046959:                                1 branches:uH:   call                             6f14d5 Async_unix.Raw_scheduler.loop_13465+0x65 (/tmp/clark.exe) =>           7ffa60 Async_kernel.Scheduler1.uncaught_exn_7315+0x0 (/tmp/clark.exe)
    ->     60ns END   Async_kernel.Scheduler.check_invariants_8475
    4589/4589  108652.292046959:                                1 branches:uH:   return                           7ffae9 Async_kernel.Scheduler1.uncaught_exn_7315+0x89 (/tmp/clark.exe) =>           6f14d7 Async_unix.Raw_scheduler.loop_13465+0x67 (/tmp/clark.exe)
    4589/4589  108652.292046959:                                1 branches:uH:   call                             6f1544 Async_unix.Raw_scheduler.loop_13465+0xd4 (/tmp/clark.exe) =>           6f0cd0 Async_unix.Raw_scheduler.one_iter_13456+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046973:                                1 branches:uH:   call                             6f0d01 Async_unix.Raw_scheduler.one_iter_13456+0x31 (/tmp/clark.exe) =>           d0a360 Stdlib.Lazy.is_val_370+0x0 (/tmp/clark.exe)
    ->     64ns BEGIN Async_kernel.Scheduler1.uncaught_exn_7315
    ->     71ns END   Async_kernel.Scheduler1.uncaught_exn_7315
    ->     71ns BEGIN Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292046973:                                1 branches:uH:   call                             d0a367 Stdlib.Lazy.is_val_370+0x7 (/tmp/clark.exe) =>           d62bb0 caml_obj_tag+0x0 (/tmp/clark.exe)
    4589/4589  108652.292046974:                                1 branches:uH:   call                             d62bd0 caml_obj_tag+0x20 (/tmp/clark.exe) =>           d538d0 caml_page_table_lookup+0x0 (/tmp/clark.exe)
    ->     78ns BEGIN Stdlib.Lazy.is_val_370
    ->     78ns BEGIN caml_obj_tag
    4589/4589  108652.292046974:                                1 branches:uH:   return                           d53942 caml_page_table_lookup+0x72 (/tmp/clark.exe) =>           d62bd5 caml_obj_tag+0x25 (/tmp/clark.exe)
    4589/4589  108652.292046974:                                1 branches:uH:   return                           d62beb caml_obj_tag+0x3b (/tmp/clark.exe) =>           d0a36c Stdlib.Lazy.is_val_370+0xc (/tmp/clark.exe)
    4589/4589  108652.292046983:                                1 branches:uH:   return                           d0a384 Stdlib.Lazy.is_val_370+0x24 (/tmp/clark.exe) =>           6f0d03 Async_unix.Raw_scheduler.one_iter_13456+0x33 (/tmp/clark.exe)
    ->     79ns BEGIN caml_page_table_lookup
    ->     88ns END   caml_page_table_lookup
    ->     88ns END   caml_obj_tag
    4589/4589  108652.292046983:                                1 branches:uH:   call                             6f0dfb Async_unix.Raw_scheduler.one_iter_13456+0x12b (/tmp/clark.exe) =>           6eeeb0 Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047003:                                1 branches:uH:   call                             6eeecb Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1b (/tmp/clark.exe) =>           cc66e0 Base.Stack.is_empty_1236+0x0 (/tmp/clark.exe)
    ->     88ns END   Stdlib.Lazy.is_val_370
    ->     88ns BEGIN Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    4589/4589  108652.292047004:                                1 branches:uH:   return                           cc66f3 Base.Stack.is_empty_1236+0x13 (/tmp/clark.exe) =>           6eeecd Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1d (/tmp/clark.exe)
    ->    108ns BEGIN Base.Stack.is_empty_1236
    4589/4589  108652.292047004:                                1 branches:uH:   return                           6eeedc Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x2c (/tmp/clark.exe) =>           6f0e00 Async_unix.Raw_scheduler.one_iter_13456+0x130 (/tmp/clark.exe)
    4589/4589  108652.292047004:                                1 branches:uH:   call                             6f0e05 Async_unix.Raw_scheduler.one_iter_13456+0x135 (/tmp/clark.exe) =>           6f07f0 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047004:                                1 branches:uH:   call                             6f0825 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x35 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047006:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    ->    109ns END   Base.Stack.is_empty_1236
    ->    109ns END   Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    ->    109ns BEGIN Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    ->    110ns BEGIN caml_apply2
    4589/4589  108652.292047007:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           6f082a Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x3a (/tmp/clark.exe)
    ->    111ns END   caml_apply2
    ->    111ns BEGIN Core.Int.fun_13983
    4589/4589  108652.292047007:                                1 branches:uH:   call                             6f0874 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x84 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047010:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    ->    112ns END   Core.Int.fun_13983
    ->    112ns BEGIN caml_apply2
    4589/4589  108652.292047010:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           6f0879 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x89 (/tmp/clark.exe)
    4589/4589  108652.292047013:                                1 branches:uH:   call                             6f089b Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xab (/tmp/clark.exe) =>           81c840 Async_kernel.Scheduler.can_run_a_job_5765+0x0 (/tmp/clark.exe)
    ->    115ns END   caml_apply2
    ->    115ns BEGIN Base.Int63.fun_4892
    ->    118ns END   Base.Int63.fun_4892
    4589/4589  108652.292047013:                                1 branches:uH:   call                             81c86d Async_kernel.Scheduler.can_run_a_job_5765+0x2d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047015:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    ->    118ns BEGIN Async_kernel.Scheduler.can_run_a_job_5765
    ->    119ns BEGIN caml_apply2
    4589/4589  108652.292047015:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           81c872 Async_kernel.Scheduler.can_run_a_job_5765+0x32 (/tmp/clark.exe)
    4589/4589  108652.292047015:                                1 branches:uH:   return                           81c88a Async_kernel.Scheduler.can_run_a_job_5765+0x4a (/tmp/clark.exe) =>           6f089d Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xad (/tmp/clark.exe)
    4589/4589  108652.292047017:                                1 branches:uH:   call                             6f0926 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x136 (/tmp/clark.exe) =>           81c8a0 Async_kernel.Scheduler.has_upcoming_event_5918+0x0 (/tmp/clark.exe)
    ->    120ns END   caml_apply2
    ->    120ns BEGIN Core.Int.fun_13983
    ->    122ns END   Core.Int.fun_13983
    ->    122ns END   Async_kernel.Scheduler.can_run_a_job_5765
    4589/4589  108652.292047023:                                1 branches:uH:   call                             81c8bd Async_kernel.Scheduler.has_upcoming_event_5918+0x1d (/tmp/clark.exe) =>           8ad630 Timing_wheel.is_empty_19261+0x0 (/tmp/clark.exe)
    ->    122ns BEGIN Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292047037:                                1 branches:uH:   jmp                              8ad657 Timing_wheel.is_empty_19261+0x27 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    ->    128ns BEGIN Timing_wheel.is_empty_19261
    4589/4589  108652.292047045:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    ->    142ns END   Timing_wheel.is_empty_19261
    ->    142ns BEGIN caml_apply2
    4589/4589  108652.292047046:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           81c8bf Async_kernel.Scheduler.has_upcoming_event_5918+0x1f (/tmp/clark.exe)
    ->    150ns END   caml_apply2
    ->    150ns BEGIN Core.Int.fun_13981
    4589/4589  108652.292047046:                                1 branches:uH:   return                           81c8ce Async_kernel.Scheduler.has_upcoming_event_5918+0x2e (/tmp/clark.exe) =>           6f0928 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x138 (/tmp/clark.exe)
    4589/4589  108652.292047047:                                1 branches:uH:   call                             6f094f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x15f (/tmp/clark.exe) =>           81c910 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x0 (/tmp/clark.exe)
    ->    151ns END   Core.Int.fun_13981
    ->    151ns END   Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292047052:                                1 branches:uH:   jmp                              81c939 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x29 (/tmp/clark.exe) =>           8ae2b0 Timing_wheel.next_alarm_fires_at_exn_19321+0x0 (/tmp/clark.exe)
    ->    152ns BEGIN Async_kernel.Scheduler.next_upcoming_event_exn_5924
    4589/4589  108652.292047052:                                1 branches:uH:   call                             8ae2d8 Timing_wheel.next_alarm_fires_at_exn_19321+0x28 (/tmp/clark.exe) =>           8a6540 Timing_wheel.min_elt.16860+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047052:                                1 branches:uH:   call                             8a6579 Timing_wheel.min_elt.16860+0x39 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047055:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    ->    157ns END   Async_kernel.Scheduler.next_upcoming_event_exn_5924
    ->    157ns BEGIN Timing_wheel.next_alarm_fires_at_exn_19321
    ->    158ns BEGIN Timing_wheel.min_elt.16860
    ->    159ns BEGIN caml_apply2
    4589/4589  108652.292047055:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           8a657e Timing_wheel.min_elt.16860+0x3e (/tmp/clark.exe)
    4589/4589  108652.292047063:                                1 branches:uH:   call                             8a65c5 Timing_wheel.min_elt.16860+0x85 (/tmp/clark.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (/tmp/clark.exe)
    ->    160ns END   caml_apply2
    ->    160ns BEGIN Core.Int.fun_13981
    ->    168ns END   Core.Int.fun_13981
    4589/4589  108652.292047063:                                1 branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (/tmp/clark.exe) =>           8a65c7 Timing_wheel.min_elt.16860+0x87 (/tmp/clark.exe)
    4589/4589  108652.292047063:                                1 branches:uH:   return                           8a6a45 Timing_wheel.min_elt.16860+0x505 (/tmp/clark.exe) =>           8ae2dd Timing_wheel.next_alarm_fires_at_exn_19321+0x2d (/tmp/clark.exe)
    4589/4589  108652.292047075:                                1 branches:uH:   call                             8ae2fa Timing_wheel.next_alarm_fires_at_exn_19321+0x4a (/tmp/clark.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (/tmp/clark.exe)
    ->    168ns BEGIN Tuple_pool.is_null_4272
    ->    180ns END   Tuple_pool.is_null_4272
    ->    180ns END   Timing_wheel.min_elt.16860
    4589/4589  108652.292047076:                                1 branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (/tmp/clark.exe) =>           8ae2fc Timing_wheel.next_alarm_fires_at_exn_19321+0x4c (/tmp/clark.exe)
    ->    180ns BEGIN Tuple_pool.is_null_4272
    4589/4589  108652.292047076:                                1 branches:uH:   call                             8ae33a Timing_wheel.next_alarm_fires_at_exn_19321+0x8a (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047079:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (/tmp/clark.exe)
    ->    181ns END   Tuple_pool.is_null_4272
    ->    181ns BEGIN caml_apply3
    4589/4589  108652.292047079:                                1 branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047080:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (/tmp/clark.exe)
    ->    184ns END   caml_apply3
    ->    184ns BEGIN Tuple_pool.get_8303
    ->    184ns END   Tuple_pool.get_8303
    ->    184ns BEGIN caml_apply2
    4589/4589  108652.292047080:                                1 branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (/tmp/clark.exe) =>           8ae33f Timing_wheel.next_alarm_fires_at_exn_19321+0x8f (/tmp/clark.exe)
    4589/4589  108652.292047080:                                1 branches:uH:   call                             8ae362 Timing_wheel.next_alarm_fires_at_exn_19321+0xb2 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047087:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    ->    185ns END   caml_apply2
    ->    185ns BEGIN Base.Uniform_array.get_1544
    ->    188ns END   Base.Uniform_array.get_1544
    ->    188ns BEGIN caml_apply2
    4589/4589  108652.292047087:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           8ae367 Timing_wheel.next_alarm_fires_at_exn_19321+0xb7 (/tmp/clark.exe)
    4589/4589  108652.292047088:                                1 branches:uH:   call                             8ae397 Timing_wheel.next_alarm_fires_at_exn_19321+0xe7 (/tmp/clark.exe) =>           c65880 Base.Int.succ_2528+0x0 (/tmp/clark.exe)
    ->    192ns END   caml_apply2
    ->    192ns BEGIN Base.Int.fun_3468
    ->    193ns END   Base.Int.fun_3468
    4589/4589  108652.292047089:                                1 branches:uH:   return                           c65884 Base.Int.succ_2528+0x4 (/tmp/clark.exe) =>           8ae399 Timing_wheel.next_alarm_fires_at_exn_19321+0xe9 (/tmp/clark.exe)
    ->    193ns BEGIN Base.Int.succ_2528
    4589/4589  108652.292047089:                                1 branches:uH:   call                             8ae3bb Timing_wheel.next_alarm_fires_at_exn_19321+0x10b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047089:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86320 Base.Int63.fun_4894+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047090:                                1 branches:uH:   return                           c8632f Base.Int63.fun_4894+0xf (/tmp/clark.exe) =>           8ae3c0 Timing_wheel.next_alarm_fires_at_exn_19321+0x110 (/tmp/clark.exe)
    ->    194ns END   Base.Int.succ_2528
    ->    194ns BEGIN caml_apply2
    ->    194ns END   caml_apply2
    ->    194ns BEGIN Base.Int63.fun_4894
    4589/4589  108652.292047090:                                1 branches:uH:   call                             8ae3f4 Timing_wheel.next_alarm_fires_at_exn_19321+0x144 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047091:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    ->    195ns END   Base.Int63.fun_4894
    ->    195ns BEGIN caml_apply2
    4589/4589  108652.292047091:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           8ae3f9 Timing_wheel.next_alarm_fires_at_exn_19321+0x149 (/tmp/clark.exe)
    4589/4589  108652.292047091:                                1 branches:uH:   call                             8ae43e Timing_wheel.next_alarm_fires_at_exn_19321+0x18e (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047093:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65960 Base.Int.shift_left_2568+0x0 (/tmp/clark.exe)
    ->    196ns END   caml_apply2
    ->    196ns BEGIN Base.Int63.fun_4892
    ->    197ns END   Base.Int63.fun_4892
    ->    197ns BEGIN caml_apply2
    4589/4589  108652.292047093:                                1 branches:uH:   return                           c65971 Base.Int.shift_left_2568+0x11 (/tmp/clark.exe) =>           8ae443 Timing_wheel.next_alarm_fires_at_exn_19321+0x193 (/tmp/clark.exe)
    4589/4589  108652.292047094:                                1 branches:uH:   jmp                              8ae44e Timing_wheel.next_alarm_fires_at_exn_19321+0x19e (/tmp/clark.exe) =>           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe)
    ->    198ns END   caml_apply2
    ->    198ns BEGIN Base.Int.shift_left_2568
    ->    199ns END   Base.Int.shift_left_2568
    4589/4589  108652.292047094:                                1 branches:uH:   return                           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe) =>           6f0951 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x161 (/tmp/clark.exe)
    4589/4589  108652.292047094:                                1 branches:uH:   call                             6f09dc Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1ec (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047095:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    ->    199ns END   Timing_wheel.next_alarm_fires_at_exn_19321
    ->    199ns BEGIN Core.Time_ns.of_int63_ns_since_epoch_5150
    ->    199ns END   Core.Time_ns.of_int63_ns_since_epoch_5150
    ->    199ns BEGIN caml_apply2
    4589/4589  108652.292047096:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           6f09e1 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1f1 (/tmp/clark.exe)
    ->    200ns END   caml_apply2
    ->    200ns BEGIN Base.Int.fun_3468
    4589/4589  108652.292047096:                                1 branches:uH:   call                             6f0b3f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x34f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047098:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86350 Base.Int63.fun_4888+0x0 (/tmp/clark.exe)
    ->    201ns END   Base.Int.fun_3468
    ->    201ns BEGIN caml_apply2
    4589/4589  108652.292047099:                                1 branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (/tmp/clark.exe) =>           6f0b44 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x354 (/tmp/clark.exe)
    ->    203ns END   caml_apply2
    ->    203ns BEGIN Base.Int63.fun_4888
    4589/4589  108652.292047099:                                1 branches:uH:   jmp                              6f0cb3 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x4c3 (/tmp/clark.exe) =>           6efe20 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047118:                                1 branches:uH:   call                             6efe8a Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6a (/tmp/clark.exe) =>           6d4ff0 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x0 (/tmp/clark.exe)
    ->    204ns END   Base.Int63.fun_4888
    ->    204ns END   Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    ->    204ns BEGIN Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    4589/4589  108652.292047119:                                1 branches:uH:   return                           6d4ff5 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x5 (/tmp/clark.exe) =>           6efe8c Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6c (/tmp/clark.exe)
    ->    223ns BEGIN Async_unix.Epoll_file_descr_watcher.pre_check_8138
    4589/4589  108652.292047119:                                1 branches:uH:   call                             6efecd Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xad (/tmp/clark.exe) =>           7af180 Nano_mutex.unlock_exn_5263+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047124:                                1 branches:uH:   call                             7af1bd Nano_mutex.unlock_exn_5263+0x3d (/tmp/clark.exe) =>           b02db0 Thread.fun_715+0x0 (/tmp/clark.exe)
    ->    224ns END   Async_unix.Epoll_file_descr_watcher.pre_check_8138
    ->    224ns BEGIN Nano_mutex.unlock_exn_5263
    4589/4589  108652.292047124:                                1 branches:uH:   call                             b02db7 Thread.fun_715+0x7 (/tmp/clark.exe) =>           d44690 caml_thread_self+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047125:                                1 branches:uH:   return                           d4469f caml_thread_self+0xf (/tmp/clark.exe) =>           b02dbc Thread.fun_715+0xc (/tmp/clark.exe)
    ->    229ns BEGIN Thread.fun_715
    ->    229ns BEGIN caml_thread_self
    4589/4589  108652.292047125:                                1 branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (/tmp/clark.exe) =>           7af1bf Nano_mutex.unlock_exn_5263+0x3f (/tmp/clark.exe)
    4589/4589  108652.292047126:                                1 branches:uH:   call                             7af1c6 Nano_mutex.unlock_exn_5263+0x46 (/tmp/clark.exe) =>           b02d90 Thread.fun_713+0x0 (/tmp/clark.exe)
    ->    230ns END   caml_thread_self
    ->    230ns END   Thread.fun_715
    4589/4589  108652.292047126:                                1 branches:uH:   call                             b02d97 Thread.fun_713+0x7 (/tmp/clark.exe) =>           d446b0 caml_thread_id+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047127:                                1 branches:uH:   return                           d446b3 caml_thread_id+0x3 (/tmp/clark.exe) =>           b02d9c Thread.fun_713+0xc (/tmp/clark.exe)
    ->    231ns BEGIN Thread.fun_713
    ->    231ns BEGIN caml_thread_id
    4589/4589  108652.292047127:                                1 branches:uH:   return                           b02da0 Thread.fun_713+0x10 (/tmp/clark.exe) =>           7af1c8 Nano_mutex.unlock_exn_5263+0x48 (/tmp/clark.exe)
    4589/4589  108652.292047127:                                1 branches:uH:   call                             7af1e9 Nano_mutex.unlock_exn_5263+0x69 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047128:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd920 Core.Int.fun_13987+0x0 (/tmp/clark.exe)
    ->    232ns END   caml_thread_id
    ->    232ns END   Thread.fun_713
    ->    232ns BEGIN caml_apply2
    4589/4589  108652.292047128:                                1 branches:uH:   return                           9dd92f Core.Int.fun_13987+0xf (/tmp/clark.exe) =>           7af1ee Nano_mutex.unlock_exn_5263+0x6e (/tmp/clark.exe)
    4589/4589  108652.292047128:                                1 branches:uH:   call                             7af212 Nano_mutex.unlock_exn_5263+0x92 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047131:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    ->    233ns END   caml_apply2
    ->    233ns BEGIN Core.Int.fun_13987
    ->    234ns END   Core.Int.fun_13987
    ->    234ns BEGIN caml_apply2
    4589/4589  108652.292047132:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           7af217 Nano_mutex.unlock_exn_5263+0x97 (/tmp/clark.exe)
    ->    236ns END   caml_apply2
    ->    236ns BEGIN Base.Int.fun_3468
    4589/4589  108652.292047132:                                1 branches:uH:   call                             7af22c Nano_mutex.unlock_exn_5263+0xac (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047134:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           7af231 Nano_mutex.unlock_exn_5263+0xb1 (/tmp/clark.exe)
    ->    237ns END   Base.Int.fun_3468
    ->    237ns BEGIN caml_modify
    4589/4589  108652.292047136:                                1 branches:uH:   call                             7af247 Nano_mutex.unlock_exn_5263+0xc7 (/tmp/clark.exe) =>           c12c50 Base.Option.is_some_1124+0x0 (/tmp/clark.exe)
    ->    239ns END   caml_modify
    4589/4589  108652.292047137:                                1 branches:uH:   return                           c12c61 Base.Option.is_some_1124+0x11 (/tmp/clark.exe) =>           7af249 Nano_mutex.unlock_exn_5263+0xc9 (/tmp/clark.exe)
    ->    241ns BEGIN Base.Option.is_some_1124
    4589/4589  108652.292047138:                                1 branches:uH:   jmp                              7af296 Nano_mutex.unlock_exn_5263+0x116 (/tmp/clark.exe) =>           c15330 Base.Or_error.ok_exn_2208+0x0 (/tmp/clark.exe)
    ->    242ns END   Base.Option.is_some_1124
    4589/4589  108652.292047138:                                1 branches:uH:   return                           c15407 Base.Or_error.ok_exn_2208+0xd7 (/tmp/clark.exe) =>           6efecf Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xaf (/tmp/clark.exe)
    4589/4589  108652.292047139:                                1 branches:uH:   call                             6efee2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xc2 (/tmp/clark.exe) =>           b02d50 Thread.fun_709+0x0 (/tmp/clark.exe)
    ->    243ns END   Nano_mutex.unlock_exn_5263
    ->    243ns BEGIN Base.Or_error.ok_exn_2208
    ->    244ns END   Base.Or_error.ok_exn_2208
    4589/4589  108652.292047139:                                1 branches:uH:   call                             b02d5e Thread.fun_709+0xe (/tmp/clark.exe) =>           d6d414 caml_c_call+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047140:                                1 branches:uH:   jmp                              d6d43c caml_c_call+0x28 (/tmp/clark.exe) =>           d44780 caml_thread_yield+0x0 (/tmp/clark.exe)
    ->    244ns BEGIN Thread.fun_709
    ->    244ns BEGIN caml_c_call
    4589/4589  108652.292047140:                                1 branches:uH:   call                             d44796 caml_thread_yield+0x16 (/tmp/clark.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047140:                                1 branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (/tmp/clark.exe) =>           d4479b caml_thread_yield+0x1b (/tmp/clark.exe)
    4589/4589  108652.292047140:                                1 branches:uH:   call                             d447a5 caml_thread_yield+0x25 (/tmp/clark.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047140:                                1 branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (/tmp/clark.exe) =>           d447aa caml_thread_yield+0x2a (/tmp/clark.exe)
    4589/4589  108652.292047140:                                1 branches:uH:   call                             d447fa caml_thread_yield+0x7a (/tmp/clark.exe) =>           d53c20 caml_get_local_arenas+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047149:                                1 branches:uH:   return                           d53c3e caml_get_local_arenas+0x1e (/tmp/clark.exe) =>           d447ff caml_thread_yield+0x7f (/tmp/clark.exe)
    ->    245ns END   caml_c_call
    ->    245ns BEGIN caml_thread_yield
    ->    247ns BEGIN caml_process_pending_signals_exn
    ->    249ns END   caml_process_pending_signals_exn
    ->    249ns BEGIN caml_raise_async_if_exception
    ->    251ns END   caml_raise_async_if_exception
    ->    251ns BEGIN caml_get_local_arenas
    4589/4589  108652.292047149:                                1 branches:uH:   call                             d44839 caml_thread_yield+0xb9 (/tmp/clark.exe) =>           d6c8d0 caml_memprof_leave_thread+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047149:                                1 branches:uH:   return                           d6c8db caml_memprof_leave_thread+0xb (/tmp/clark.exe) =>           d4483e caml_thread_yield+0xbe (/tmp/clark.exe)
    4589/4589  108652.292047149:                                1 branches:uH:   call                             d44845 caml_thread_yield+0xc5 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047156:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    ->    254ns END   caml_get_local_arenas
    ->    254ns BEGIN caml_memprof_leave_thread
    ->    257ns END   caml_memprof_leave_thread
    ->    257ns BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292047210:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d4484a caml_thread_yield+0xca (/tmp/clark.exe)
    ->    261ns END   pthread_mutex_lock@plt
    ->    261ns BEGIN pthread_mutex_lock
    4589/4589  108652.292047221:                                1 branches:uH:   call                             d44873 caml_thread_yield+0xf3 (/tmp/clark.exe) =>           d437a0 custom_condvar_signal+0x0 (/tmp/clark.exe)
    ->    315ns END   pthread_mutex_lock
    4589/4589  108652.292047221:                                1 branches:uH:   call                             d437c9 custom_condvar_signal+0x29 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292047229:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    ->    326ns BEGIN custom_condvar_signal
    ->    330ns BEGIN syscall@plt
    4589/4589  108652.292047245:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    ->    334ns END   syscall@plt
    ->    334ns BEGIN syscall
    4589/4589  108652.292048074:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    ->    350ns BEGIN [syscall]
    4589/4589  108652.292048082:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d437ce custom_condvar_signal+0x2e (/tmp/clark.exe)
    ->  1.179us END   [syscall]
    4589/4589  108652.292048084:                                1 branches:uH:   return                           d437d4 custom_condvar_signal+0x34 (/tmp/clark.exe) =>           d44878 caml_thread_yield+0xf8 (/tmp/clark.exe)
    ->  1.187us END   syscall
    4589/4589  108652.292048084:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    4589/4589  108652.292048084:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292048087:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    ->  1.189us END   custom_condvar_signal
    ->  1.189us BEGIN custom_condvar_wait
    ->   1.19us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292048088:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    ->  1.192us END   pthread_mutex_unlock@plt
    ->  1.192us BEGIN pthread_mutex_unlock
    4589/4589  108652.292048088:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292048096:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    ->  1.193us END   pthread_mutex_unlock
    ->  1.193us BEGIN syscall@plt
    4589/4589  108652.292048111:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    ->  1.201us END   syscall@plt
    ->  1.201us BEGIN syscall
    4589/4589  108652.292059441:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    ->  1.216us BEGIN [syscall]
    4589/4589  108652.292059457:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d4378d custom_condvar_wait+0x3d (/tmp/clark.exe)
    -> 12.546us END   [syscall]
    4589/4589  108652.292059457:                                1 branches:uH:   call                             d43790 custom_condvar_wait+0x40 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292059485:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 12.562us END   syscall
    -> 12.562us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292059556:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43795 custom_condvar_wait+0x45 (/tmp/clark.exe)
    ->  12.59us END   pthread_mutex_lock@plt
    ->  12.59us BEGIN pthread_mutex_lock
    4589/4589  108652.292059557:                                1 branches:uH:   return                           d4379f custom_condvar_wait+0x4f (/tmp/clark.exe) =>           d448a3 caml_thread_yield+0x123 (/tmp/clark.exe)
    -> 12.661us END   pthread_mutex_lock
    4589/4589  108652.292059571:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    -> 12.662us END   custom_condvar_wait
    4589/4589  108652.292059571:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292059580:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 12.676us BEGIN custom_condvar_wait
    ->  12.68us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292059594:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    -> 12.685us END   pthread_mutex_unlock@plt
    -> 12.685us BEGIN pthread_mutex_unlock
    4589/4589  108652.292059594:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292059596:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    -> 12.699us END   pthread_mutex_unlock
    -> 12.699us BEGIN syscall@plt
    4589/4589  108652.292059611:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 12.701us END   syscall@plt
    -> 12.701us BEGIN syscall
    4589/4589  108652.292075757:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    -> 12.716us BEGIN [syscall]
    4589/4589  108652.292075805:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d4378d custom_condvar_wait+0x3d (/tmp/clark.exe)
    -> 28.862us END   [syscall]
    4589/4589  108652.292075805:                                1 branches:uH:   call                             d43790 custom_condvar_wait+0x40 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292075858:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    ->  28.91us END   syscall
    ->  28.91us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292076004:                                1 branches:uH:   tr end                     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so) =>                0 [unknown] ([unknown])
    -> 28.963us END   pthread_mutex_lock@plt
    -> 28.963us BEGIN pthread_mutex_lock
    4589/4589  108652.292077837:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 29.109us BEGIN [untraced]
    4589/4589  108652.292077926:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43795 custom_condvar_wait+0x45 (/tmp/clark.exe)
    -> 30.942us END   [untraced]
    4589/4589  108652.292077927:                                1 branches:uH:   return                           d4379f custom_condvar_wait+0x4f (/tmp/clark.exe) =>           d448a3 caml_thread_yield+0x123 (/tmp/clark.exe)
    -> 31.031us END   pthread_mutex_lock
    4589/4589  108652.292077998:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    -> 31.032us END   custom_condvar_wait
    4589/4589  108652.292077998:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292078010:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 31.103us BEGIN custom_condvar_wait
    -> 31.109us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292078010:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    4589/4589  108652.292078010:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292078018:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    -> 31.115us END   pthread_mutex_unlock@plt
    -> 31.115us BEGIN pthread_mutex_unlock
    -> 31.119us END   pthread_mutex_unlock
    -> 31.119us BEGIN syscall@plt
    4589/4589  108652.292078035:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 31.123us END   syscall@plt
    -> 31.123us BEGIN syscall
    4589/4589  108652.292085962:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    ->  31.14us BEGIN [syscall]
    4589/4589  108652.292085978:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d4378d custom_condvar_wait+0x3d (/tmp/clark.exe)
    -> 39.067us END   [syscall]
    4589/4589  108652.292085978:                                1 branches:uH:   call                             d43790 custom_condvar_wait+0x40 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292086005:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 39.083us END   syscall
    -> 39.083us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292086062:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43795 custom_condvar_wait+0x45 (/tmp/clark.exe)
    ->  39.11us END   pthread_mutex_lock@plt
    ->  39.11us BEGIN pthread_mutex_lock
    4589/4589  108652.292086068:                                1 branches:uH:   return                           d4379f custom_condvar_wait+0x4f (/tmp/clark.exe) =>           d448a3 caml_thread_yield+0x123 (/tmp/clark.exe)
    -> 39.167us END   pthread_mutex_lock
    4589/4589  108652.292086082:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    -> 39.173us END   custom_condvar_wait
    4589/4589  108652.292086082:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292086091:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 39.187us BEGIN custom_condvar_wait
    -> 39.191us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292086091:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    4589/4589  108652.292086091:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292086099:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    -> 39.196us END   pthread_mutex_unlock@plt
    -> 39.196us BEGIN pthread_mutex_unlock
    ->   39.2us END   pthread_mutex_unlock
    ->   39.2us BEGIN syscall@plt
    4589/4589  108652.292086115:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 39.204us END   syscall@plt
    -> 39.204us BEGIN syscall
    4589/4589  108652.292094169:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    ->  39.22us BEGIN [syscall]
    4589/4589  108652.292094184:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d4378d custom_condvar_wait+0x3d (/tmp/clark.exe)
    -> 47.274us END   [syscall]
    4589/4589  108652.292094184:                                1 branches:uH:   call                             d43790 custom_condvar_wait+0x40 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094209:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 47.289us END   syscall
    -> 47.289us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292094285:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43795 custom_condvar_wait+0x45 (/tmp/clark.exe)
    -> 47.314us END   pthread_mutex_lock@plt
    -> 47.314us BEGIN pthread_mutex_lock
    4589/4589  108652.292094291:                                1 branches:uH:   return                           d4379f custom_condvar_wait+0x4f (/tmp/clark.exe) =>           d448a3 caml_thread_yield+0x123 (/tmp/clark.exe)
    ->  47.39us END   pthread_mutex_lock
    4589/4589  108652.292094305:                                1 branches:uH:   call                             d448cd caml_thread_yield+0x14d (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    -> 47.396us END   custom_condvar_wait
    4589/4589  108652.292094316:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    ->  47.41us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292094316:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d448d2 caml_thread_yield+0x152 (/tmp/clark.exe)
    4589/4589  108652.292094316:                                1 branches:uH:   call                             d448d8 caml_thread_yield+0x158 (/tmp/clark.exe) =>           686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094323:                                1 branches:uH:   jmp                              686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe) =>     7ffff79c8870 pthread_getspecific+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 47.421us END   pthread_mutex_unlock@plt
    -> 47.421us BEGIN pthread_mutex_unlock
    -> 47.424us END   pthread_mutex_unlock
    -> 47.424us BEGIN pthread_getspecific@plt
    4589/4589  108652.292094323:                                1 branches:uH:   return                     7ffff79c88ac pthread_getspecific+0x3c (/usr/lib64/libpthread-2.17.so) =>           d448dd caml_thread_yield+0x15d (/tmp/clark.exe)
    4589/4589  108652.292094323:                                1 branches:uH:   call                             d44928 caml_thread_yield+0x1a8 (/tmp/clark.exe) =>           d53c40 caml_set_local_arenas+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094363:                                1 branches:uH:   return                           d53c8b caml_set_local_arenas+0x4b (/tmp/clark.exe) =>           d4492d caml_thread_yield+0x1ad (/tmp/clark.exe)
    -> 47.428us END   pthread_getspecific@plt
    -> 47.428us BEGIN pthread_getspecific
    -> 47.448us END   pthread_getspecific
    -> 47.448us BEGIN caml_set_local_arenas
    4589/4589  108652.292094363:                                1 branches:uH:   call                             d44968 caml_thread_yield+0x1e8 (/tmp/clark.exe) =>           d6c8e0 caml_memprof_enter_thread+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094363:                                1 branches:uH:   jmp                              d6c8e9 caml_memprof_enter_thread+0x9 (/tmp/clark.exe) =>           d6ba60 caml_memprof_set_suspended+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094363:                                1 branches:uH:   call                             d6ba6c caml_memprof_set_suspended+0xc (/tmp/clark.exe) =>           d6b9c0 caml_memprof_renew_minor_sample+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094426:                                1 branches:uH:   jmp                              d6b9ed caml_memprof_renew_minor_sample+0x2d (/tmp/clark.exe) =>           d4df50 caml_update_young_limit+0x0 (/tmp/clark.exe)
    -> 47.468us END   caml_set_local_arenas
    -> 47.468us BEGIN caml_memprof_enter_thread
    -> 47.489us END   caml_memprof_enter_thread
    -> 47.489us BEGIN caml_memprof_set_suspended
    ->  47.51us BEGIN caml_memprof_renew_minor_sample
    4589/4589  108652.292094434:                                1 branches:uH:   return                           d4df85 caml_update_young_limit+0x35 (/tmp/clark.exe) =>           d6ba71 caml_memprof_set_suspended+0x11 (/tmp/clark.exe)
    -> 47.531us END   caml_memprof_renew_minor_sample
    -> 47.531us BEGIN caml_update_young_limit
    4589/4589  108652.292094434:                                1 branches:uH:   jmp                              d6ba81 caml_memprof_set_suspended+0x21 (/tmp/clark.exe) =>           d6b150 check_action_pending+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094435:                                1 branches:uH:   return                           d6b180 check_action_pending+0x30 (/tmp/clark.exe) =>           d4496d caml_thread_yield+0x1ed (/tmp/clark.exe)
    -> 47.539us END   caml_update_young_limit
    -> 47.539us END   caml_memprof_set_suspended
    -> 47.539us BEGIN check_action_pending
    4589/4589  108652.292094435:                                1 branches:uH:   call                             d4496d caml_thread_yield+0x1ed (/tmp/clark.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094435:                                1 branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (/tmp/clark.exe) =>           d44972 caml_thread_yield+0x1f2 (/tmp/clark.exe)
    4589/4589  108652.292094435:                                1 branches:uH:   call                             d4497c caml_thread_yield+0x1fc (/tmp/clark.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094435:                                1 branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (/tmp/clark.exe) =>           d44981 caml_thread_yield+0x201 (/tmp/clark.exe)
    4589/4589  108652.292094438:                                1 branches:uH:   return                           d4498c caml_thread_yield+0x20c (/tmp/clark.exe) =>           b02d63 Thread.fun_709+0x13 (/tmp/clark.exe)
    ->  47.54us END   check_action_pending
    ->  47.54us BEGIN caml_process_pending_signals_exn
    -> 47.541us END   caml_process_pending_signals_exn
    -> 47.541us BEGIN caml_raise_async_if_exception
    -> 47.543us END   caml_raise_async_if_exception
    4589/4589  108652.292094453:                                1 branches:uH:   return                           b02d6b Thread.fun_709+0x1b (/tmp/clark.exe) =>           6efee4 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xc4 (/tmp/clark.exe)
    -> 47.543us END   caml_thread_yield
    4589/4589  108652.292094496:                                1 branches:uH:   call                             6eff90 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x170 (/tmp/clark.exe) =>           7821c0 Time_stamp_counter.now_4481+0x0 (/tmp/clark.exe)
    -> 47.558us END   Thread.fun_709
    4589/4589  108652.292094527:                                1 branches:uH:   jmp                              7821f3 Time_stamp_counter.now_4481+0x33 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 47.601us BEGIN Time_stamp_counter.now_4481
    4589/4589  108652.292094527:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           6eff92 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x172 (/tmp/clark.exe)
    4589/4589  108652.292094527:                                1 branches:uH:   call                             6effb2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x192 (/tmp/clark.exe) =>           6c8950 caml_apply4+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094557:                                1 branches:uH:   jmp                              6c896a caml_apply4+0x1a (/tmp/clark.exe) =>           6d5160 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x0 (/tmp/clark.exe)
    -> 47.632us END   Time_stamp_counter.now_4481
    -> 47.632us BEGIN Base.Int.of_int_2534
    -> 47.647us END   Base.Int.of_int_2534
    -> 47.647us BEGIN caml_apply4
    4589/4589  108652.292094634:                                1 branches:uH:   call                             6d519f Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x3f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 47.662us END   caml_apply4
    -> 47.662us BEGIN Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694
    4589/4589  108652.292094635:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           7b8260 Linux_ext.wait_timeout_after_23376+0x0 (/tmp/clark.exe)
    -> 47.739us BEGIN caml_apply2
    4589/4589  108652.292094635:                                1 branches:uH:   call                             7b8289 Linux_ext.wait_timeout_after_23376+0x29 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094636:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86350 Base.Int63.fun_4888+0x0 (/tmp/clark.exe)
    ->  47.74us END   caml_apply2
    ->  47.74us BEGIN Linux_ext.wait_timeout_after_23376
    ->  47.74us BEGIN caml_apply2
    4589/4589  108652.292094637:                                1 branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (/tmp/clark.exe) =>           7b828e Linux_ext.wait_timeout_after_23376+0x2e (/tmp/clark.exe)
    -> 47.741us END   caml_apply2
    -> 47.741us BEGIN Base.Int63.fun_4888
    4589/4589  108652.292094637:                                1 branches:uH:   call                             7b82c5 Linux_ext.wait_timeout_after_23376+0x65 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094638:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           be0bf0 Base.Import0.max_16773+0x0 (/tmp/clark.exe)
    -> 47.742us END   Base.Int63.fun_4888
    -> 47.742us BEGIN caml_apply2
    4589/4589  108652.292094638:                                1 branches:uH:   return                           be0bf5 Base.Import0.max_16773+0x5 (/tmp/clark.exe) =>           7b82ca Linux_ext.wait_timeout_after_23376+0x6a (/tmp/clark.exe)
    4589/4589  108652.292094639:                                1 branches:uH:   call                             7b8314 Linux_ext.wait_timeout_after_23376+0xb4 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 47.743us END   caml_apply2
    -> 47.743us BEGIN Base.Import0.max_16773
    -> 47.744us END   Base.Import0.max_16773
    4589/4589  108652.292094640:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           7b8316 Linux_ext.wait_timeout_after_23376+0xb6 (/tmp/clark.exe)
    -> 47.744us BEGIN Base.Int.of_int_2534
    4589/4589  108652.292094640:                                1 branches:uH:   call                             7b831e Linux_ext.wait_timeout_after_23376+0xbe (/tmp/clark.exe) =>           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094640:                                1 branches:uH:   return                           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (/tmp/clark.exe) =>           7b8320 Linux_ext.wait_timeout_after_23376+0xc0 (/tmp/clark.exe)
    4589/4589  108652.292094641:                                1 branches:uH:   call                             7b8361 Linux_ext.wait_timeout_after_23376+0x101 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 47.745us END   Base.Int.of_int_2534
    -> 47.745us BEGIN Core.Span_ns.of_int63_ns_6030
    -> 47.746us END   Core.Span_ns.of_int63_ns_6030
    4589/4589  108652.292094646:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           7b8363 Linux_ext.wait_timeout_after_23376+0x103 (/tmp/clark.exe)
    -> 47.746us BEGIN Base.Int.of_int_2534
    4589/4589  108652.292094649:                                1 branches:uH:   call                             7b836b Linux_ext.wait_timeout_after_23376+0x10b (/tmp/clark.exe) =>           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (/tmp/clark.exe)
    -> 47.751us END   Base.Int.of_int_2534
    4589/4589  108652.292094656:                                1 branches:uH:   return                           ae5010 Core.Span_ns.of_int63_ns_6030+0x0 (/tmp/clark.exe) =>           7b836d Linux_ext.wait_timeout_after_23376+0x10d (/tmp/clark.exe)
    -> 47.754us BEGIN Core.Span_ns.of_int63_ns_6030
    4589/4589  108652.292094656:                                1 branches:uH:   call                             7b837a Linux_ext.wait_timeout_after_23376+0x11a (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094661:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           ae5b10 Core.Span_ns.+_6234+0x0 (/tmp/clark.exe)
    -> 47.761us END   Core.Span_ns.of_int63_ns_6030
    -> 47.761us BEGIN caml_apply2
    4589/4589  108652.292094662:                                1 branches:uH:   jmp                              ae5b2b Core.Span_ns.+_6234+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 47.766us END   caml_apply2
    -> 47.766us BEGIN Core.Span_ns.+_6234
    4589/4589  108652.292094666:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86300 Base.Int63.fun_4898+0x0 (/tmp/clark.exe)
    -> 47.767us END   Core.Span_ns.+_6234
    -> 47.767us BEGIN caml_apply2
    4589/4589  108652.292094668:                                1 branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (/tmp/clark.exe) =>           7b837f Linux_ext.wait_timeout_after_23376+0x11f (/tmp/clark.exe)
    -> 47.771us END   caml_apply2
    -> 47.771us BEGIN Base.Int63.fun_4898
    4589/4589  108652.292094668:                                1 branches:uH:   call                             7b8389 Linux_ext.wait_timeout_after_23376+0x129 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094675:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c66170 Base.Int./%_2845+0x0 (/tmp/clark.exe)
    -> 47.773us END   Base.Int63.fun_4898
    -> 47.773us BEGIN caml_apply2
    4589/4589  108652.292094679:                                1 branches:uH:   return                           c66267 Base.Int./%_2845+0xf7 (/tmp/clark.exe) =>           7b838e Linux_ext.wait_timeout_after_23376+0x12e (/tmp/clark.exe)
    ->  47.78us END   caml_apply2
    ->  47.78us BEGIN Base.Int./%_2845
    4589/4589  108652.292094689:                                1 branches:uH:   call                             7b8396 Linux_ext.wait_timeout_after_23376+0x136 (/tmp/clark.exe) =>           c65890 Base.Int.to_int_2530+0x0 (/tmp/clark.exe)
    -> 47.784us END   Base.Int./%_2845
    4589/4589  108652.292094690:                                1 branches:uH:   return                           c65890 Base.Int.to_int_2530+0x0 (/tmp/clark.exe) =>           7b8398 Linux_ext.wait_timeout_after_23376+0x138 (/tmp/clark.exe)
    -> 47.794us BEGIN Base.Int.to_int_2530
    4589/4589  108652.292094690:                                1 branches:uH:   call                             7b83b0 Linux_ext.wait_timeout_after_23376+0x150 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094710:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd970 Core.Int.fun_13977+0x0 (/tmp/clark.exe)
    -> 47.795us END   Base.Int.to_int_2530
    -> 47.795us BEGIN caml_apply2
    4589/4589  108652.292094711:                                1 branches:uH:   return                           9dd97f Core.Int.fun_13977+0xf (/tmp/clark.exe) =>           7b83b5 Linux_ext.wait_timeout_after_23376+0x155 (/tmp/clark.exe)
    -> 47.815us END   caml_apply2
    -> 47.815us BEGIN Core.Int.fun_13977
    4589/4589  108652.292094711:                                1 branches:uH:   call                             7b8447 Linux_ext.wait_timeout_after_23376+0x1e7 (/tmp/clark.exe) =>           d6d414 caml_c_call+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094720:                                1 branches:uH:   jmp                              d6d43c caml_c_call+0x28 (/tmp/clark.exe) =>           d3a7d0 core_linux_epoll_wait+0x0 (/tmp/clark.exe)
    -> 47.816us END   Core.Int.fun_13977
    -> 47.816us BEGIN caml_c_call
    4589/4589  108652.292094732:                                1 branches:uH:   call                             d3a884 core_linux_epoll_wait+0xb4 (/tmp/clark.exe) =>           d4df10 caml_enter_blocking_section+0x0 (/tmp/clark.exe)
    -> 47.825us END   caml_c_call
    -> 47.825us BEGIN core_linux_epoll_wait
    4589/4589  108652.292094732:                                1 branches:uH:   call                             d4df26 caml_enter_blocking_section+0x16 (/tmp/clark.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094732:                                1 branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (/tmp/clark.exe) =>           d4df2b caml_enter_blocking_section+0x1b (/tmp/clark.exe)
    4589/4589  108652.292094732:                                1 branches:uH:   call                             d4df33 caml_enter_blocking_section+0x23 (/tmp/clark.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094732:                                1 branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (/tmp/clark.exe) =>           d4df38 caml_enter_blocking_section+0x28 (/tmp/clark.exe)
    4589/4589  108652.292094736:                                1 branches:uH:   call                             d4df38 caml_enter_blocking_section+0x28 (/tmp/clark.exe) =>           d43e70 caml_thread_enter_blocking_section+0x0 (/tmp/clark.exe)
    -> 47.837us BEGIN caml_enter_blocking_section
    -> 47.838us BEGIN caml_process_pending_signals_exn
    -> 47.839us END   caml_process_pending_signals_exn
    -> 47.839us BEGIN caml_raise_async_if_exception
    -> 47.841us END   caml_raise_async_if_exception
    4589/4589  108652.292094736:                                1 branches:uH:   call                             d43ec6 caml_thread_enter_blocking_section+0x56 (/tmp/clark.exe) =>           d53c20 caml_get_local_arenas+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094804:                                1 branches:uH:   return                           d53c3e caml_get_local_arenas+0x1e (/tmp/clark.exe) =>           d43ecb caml_thread_enter_blocking_section+0x5b (/tmp/clark.exe)
    -> 47.841us BEGIN caml_thread_enter_blocking_section
    -> 47.875us BEGIN caml_get_local_arenas
    4589/4589  108652.292094804:                                1 branches:uH:   call                             d43f05 caml_thread_enter_blocking_section+0x95 (/tmp/clark.exe) =>           d6c8d0 caml_memprof_leave_thread+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094804:                                1 branches:uH:   return                           d6c8db caml_memprof_leave_thread+0xb (/tmp/clark.exe) =>           d43f0a caml_thread_enter_blocking_section+0x9a (/tmp/clark.exe)
    4589/4589  108652.292094804:                                1 branches:uH:   jmp                              d43f10 caml_thread_enter_blocking_section+0xa0 (/tmp/clark.exe) =>           d43cb0 st_masterlock_release.constprop.8+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094804:                                1 branches:uH:   call                             d43cbb st_masterlock_release.constprop.8+0xb (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094807:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 47.909us END   caml_get_local_arenas
    -> 47.909us BEGIN caml_memprof_leave_thread
    ->  47.91us END   caml_memprof_leave_thread
    ->  47.91us END   caml_thread_enter_blocking_section
    ->  47.91us BEGIN st_masterlock_release.constprop.8
    -> 47.911us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292094818:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43cc0 st_masterlock_release.constprop.8+0x10 (/tmp/clark.exe)
    -> 47.912us END   pthread_mutex_lock@plt
    -> 47.912us BEGIN pthread_mutex_lock
    4589/4589  108652.292094818:                                1 branches:uH:   call                             d43cd1 st_masterlock_release.constprop.8+0x21 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094825:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 47.923us END   pthread_mutex_lock
    -> 47.923us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292094825:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43cd6 st_masterlock_release.constprop.8+0x26 (/tmp/clark.exe)
    4589/4589  108652.292094825:                                1 branches:uH:   jmp                              d43ce1 st_masterlock_release.constprop.8+0x31 (/tmp/clark.exe) =>           d437a0 custom_condvar_signal+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094825:                                1 branches:uH:   call                             d437c9 custom_condvar_signal+0x29 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292094838:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    ->  47.93us END   pthread_mutex_unlock@plt
    ->  47.93us BEGIN pthread_mutex_unlock
    -> 47.934us END   pthread_mutex_unlock
    -> 47.934us END   st_masterlock_release.constprop.8
    -> 47.934us BEGIN custom_condvar_signal
    -> 47.938us BEGIN syscall@plt
    4589/4589  108652.292094854:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 47.943us END   syscall@plt
    -> 47.943us BEGIN syscall
    4589/4589  108652.292096677:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    -> 47.959us BEGIN [syscall]
    4589/4589  108652.292096687:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d437ce custom_condvar_signal+0x2e (/tmp/clark.exe)
    -> 49.782us END   [syscall]
    4589/4589  108652.292096691:                                1 branches:uH:   return                           d437d4 custom_condvar_signal+0x34 (/tmp/clark.exe) =>           d4df3e caml_enter_blocking_section+0x2e (/tmp/clark.exe)
    -> 49.792us END   syscall
    4589/4589  108652.292096704:                                1 branches:uH:   return                           d4df4e caml_enter_blocking_section+0x3e (/tmp/clark.exe) =>           d3a889 core_linux_epoll_wait+0xb9 (/tmp/clark.exe)
    -> 49.796us END   custom_condvar_signal
    4589/4589  108652.292096704:                                1 branches:uH:   call                             d3a898 core_linux_epoll_wait+0xc8 (/tmp/clark.exe) =>           685d40 epoll_wait@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292096717:                                1 branches:uH:   jmp                              685d40 epoll_wait@plt+0x0 (/tmp/clark.exe) =>     7ffff71e70b0 epoll_wait+0x0 (/usr/lib64/libc-2.17.so)
    -> 49.809us END   caml_enter_blocking_section
    -> 49.809us BEGIN epoll_wait@plt
    4589/4589  108652.292096726:                                1 branches:uH:   jcc                        7ffff71e70b7 epoll_wait+0x7 (/usr/lib64/libc-2.17.so) =>     7ffff71e70cc [unknown] (/usr/lib64/libc-2.17.so)
    -> 49.822us END   epoll_wait@plt
    -> 49.822us BEGIN epoll_wait
    4589/4589  108652.292096726:                                1 branches:uH:   call                       7ffff71e70d0 [unknown] (/usr/lib64/libc-2.17.so) =>     7ffff71f4830 __libc_enable_asynccancel+0x0 (/usr/lib64/libc-2.17.so)
    4589/4589  108652.292096726:                                1 branches:uH:   return                     7ffff71f485b __libc_enable_asynccancel+0x2b (/usr/lib64/libc-2.17.so) =>     7ffff71e70d5 [unknown] (/usr/lib64/libc-2.17.so)
    4589/4589  108652.292096744:                                1 branches:uH:   tr end  syscall            7ffff71e70e1 [unknown] (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 49.831us END   epoll_wait
    -> 49.831us BEGIN [unknown @ 0x7ffff71e70cc (/usr/lib64/libc-2.17.so)]
    -> 49.837us BEGIN __libc_enable_asynccancel
    -> 49.843us END   __libc_enable_asynccancel
    -> 49.843us END   [unknown @ 0x7ffff71e70cc (/usr/lib64/libc-2.17.so)]
    -> 49.843us BEGIN [unknown @ 0x7ffff71e70d5 (/usr/lib64/libc-2.17.so)]
    4589/4589  108652.292097276:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e70e3 [unknown] (/usr/lib64/libc-2.17.so)
    -> 49.849us BEGIN [syscall]
    4589/4589  108652.292097276:                                1 branches:uH:   call                       7ffff71e70ea [unknown] (/usr/lib64/libc-2.17.so) =>     7ffff71f4890 __libc_disable_asynccancel+0x0 (/usr/lib64/libc-2.17.so)
    4589/4589  108652.292097287:                                1 branches:uH:   return                     7ffff71f48bf __libc_disable_asynccancel+0x2f (/usr/lib64/libc-2.17.so) =>     7ffff71e70ef [unknown] (/usr/lib64/libc-2.17.so)
    -> 50.381us END   [syscall]
    -> 50.381us BEGIN __libc_disable_asynccancel
    4589/4589  108652.292097293:                                1 branches:uH:   return                     7ffff71e70fe [unknown] (/usr/lib64/libc-2.17.so) =>           d3a89d core_linux_epoll_wait+0xcd (/tmp/clark.exe)
    -> 50.392us END   __libc_disable_asynccancel
    -> 50.392us END   [unknown @ 0x7ffff71e70d5 (/usr/lib64/libc-2.17.so)]
    -> 50.392us BEGIN [unknown @ 0x7ffff71e70ef (/usr/lib64/libc-2.17.so)]
    4589/4589  108652.292097293:                                1 branches:uH:   call                             d3a8a0 core_linux_epoll_wait+0xd0 (/tmp/clark.exe) =>           d4dc90 caml_leave_blocking_section+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097293:                                1 branches:uH:   call                             d4dc96 caml_leave_blocking_section+0x6 (/tmp/clark.exe) =>           685c00 __errno_location@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097295:                                1 branches:uH:   jmp                              685c00 __errno_location@plt+0x0 (/tmp/clark.exe) =>     7ffff79ccda0 __errno_location+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 50.398us END   [unknown @ 0x7ffff71e70ef (/usr/lib64/libc-2.17.so)]
    -> 50.398us BEGIN caml_leave_blocking_section
    -> 50.399us BEGIN __errno_location@plt
    4589/4589  108652.292097297:                                1 branches:uH:   return                     7ffff79ccdb0 __errno_location+0x10 (/usr/lib64/libpthread-2.17.so) =>           d4dc9b caml_leave_blocking_section+0xb (/tmp/clark.exe)
    ->   50.4us END   __errno_location@plt
    ->   50.4us BEGIN __errno_location
    4589/4589  108652.292097301:                                1 branches:uH:   call                             d4dca0 caml_leave_blocking_section+0x10 (/tmp/clark.exe) =>           d43dc0 caml_thread_leave_blocking_section+0x0 (/tmp/clark.exe)
    -> 50.402us END   __errno_location
    4589/4589  108652.292097301:                                1 branches:uH:   call                             d43dc1 caml_thread_leave_blocking_section+0x1 (/tmp/clark.exe) =>           d43cf0 st_masterlock_acquire.constprop.9+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097301:                                1 branches:uH:   call                             d43cfb st_masterlock_acquire.constprop.9+0xb (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097302:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 50.406us BEGIN caml_thread_leave_blocking_section
    -> 50.406us BEGIN st_masterlock_acquire.constprop.9
    -> 50.406us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292097302:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43d00 st_masterlock_acquire.constprop.9+0x10 (/tmp/clark.exe)
    4589/4589  108652.292097302:                                1 branches:uH:   jmp                              d43d60 st_masterlock_acquire.constprop.9+0x70 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097310:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 50.407us END   pthread_mutex_lock@plt
    -> 50.407us BEGIN pthread_mutex_lock
    -> 50.411us END   pthread_mutex_lock
    -> 50.411us END   st_masterlock_acquire.constprop.9
    -> 50.411us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292097317:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43dc6 caml_thread_leave_blocking_section+0x6 (/tmp/clark.exe)
    -> 50.415us END   pthread_mutex_unlock@plt
    -> 50.415us BEGIN pthread_mutex_unlock
    4589/4589  108652.292097317:                                1 branches:uH:   call                             d43dcc caml_thread_leave_blocking_section+0xc (/tmp/clark.exe) =>           686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   jmp                              686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe) =>     7ffff79c8870 pthread_getspecific+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 50.422us END   pthread_mutex_unlock
    -> 50.422us BEGIN pthread_getspecific@plt
    4589/4589  108652.292097318:                                1 branches:uH:   return                     7ffff79c88ac pthread_getspecific+0x3c (/usr/lib64/libpthread-2.17.so) =>           d43dd1 caml_thread_leave_blocking_section+0x11 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   call                             d43e22 caml_thread_leave_blocking_section+0x62 (/tmp/clark.exe) =>           d53c40 caml_set_local_arenas+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   return                           d53c8b caml_set_local_arenas+0x4b (/tmp/clark.exe) =>           d43e27 caml_thread_leave_blocking_section+0x67 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   jmp                              d43e62 caml_thread_leave_blocking_section+0xa2 (/tmp/clark.exe) =>           d6c8e0 caml_memprof_enter_thread+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   jmp                              d6c8e9 caml_memprof_enter_thread+0x9 (/tmp/clark.exe) =>           d6ba60 caml_memprof_set_suspended+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097318:                                1 branches:uH:   call                             d6ba6c caml_memprof_set_suspended+0xc (/tmp/clark.exe) =>           d6b9c0 caml_memprof_renew_minor_sample+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097337:                                1 branches:uH:   jmp                              d6b9ed caml_memprof_renew_minor_sample+0x2d (/tmp/clark.exe) =>           d4df50 caml_update_young_limit+0x0 (/tmp/clark.exe)
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
    4589/4589  108652.292097337:                                1 branches:uH:   return                           d4df85 caml_update_young_limit+0x35 (/tmp/clark.exe) =>           d6ba71 caml_memprof_set_suspended+0x11 (/tmp/clark.exe)
    4589/4589  108652.292097337:                                1 branches:uH:   jmp                              d6ba81 caml_memprof_set_suspended+0x21 (/tmp/clark.exe) =>           d6b150 check_action_pending+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097343:                                1 branches:uH:   return                           d6b180 check_action_pending+0x30 (/tmp/clark.exe) =>           d4dca6 caml_leave_blocking_section+0x16 (/tmp/clark.exe)
    -> 50.442us END   caml_memprof_renew_minor_sample
    -> 50.442us BEGIN caml_update_young_limit
    -> 50.445us END   caml_update_young_limit
    -> 50.445us END   caml_memprof_set_suspended
    -> 50.445us BEGIN check_action_pending
    4589/4589  108652.292097380:                                1 branches:uH:   return                           d4dd03 caml_leave_blocking_section+0x73 (/tmp/clark.exe) =>           d3a8a5 core_linux_epoll_wait+0xd5 (/tmp/clark.exe)
    -> 50.448us END   check_action_pending
    4589/4589  108652.292097381:                                1 branches:uH:   return                           d3a877 core_linux_epoll_wait+0xa7 (/tmp/clark.exe) =>           7b844c Linux_ext.wait_timeout_after_23376+0x1ec (/tmp/clark.exe)
    -> 50.485us END   caml_leave_blocking_section
    4589/4589  108652.292097381:                                1 branches:uH:   call                             7b846f Linux_ext.wait_timeout_after_23376+0x20f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097393:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    -> 50.486us END   core_linux_epoll_wait
    -> 50.486us BEGIN caml_apply2
    4589/4589  108652.292097393:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           7b8474 Linux_ext.wait_timeout_after_23376+0x214 (/tmp/clark.exe)
    4589/4589  108652.292097394:                                1 branches:uH:   return                           7b848d Linux_ext.wait_timeout_after_23376+0x22d (/tmp/clark.exe) =>           6d51a4 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0x44 (/tmp/clark.exe)
    -> 50.498us END   caml_apply2
    -> 50.498us BEGIN Core.Int.fun_13981
    -> 50.499us END   Core.Int.fun_13981
    4589/4589  108652.292097517:                                1 branches:uH:   return                           6d5253 Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694+0xf3 (/tmp/clark.exe) =>           6effb7 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x197 (/tmp/clark.exe)
    -> 50.499us END   Linux_ext.wait_timeout_after_23376
    -> 50.499us END   Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694
    4589/4589  108652.292097531:                                1 branches:uH:   call                             6effd2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1b2 (/tmp/clark.exe) =>           7821c0 Time_stamp_counter.now_4481+0x0 (/tmp/clark.exe)
    -> 50.622us END   Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694
    4589/4589  108652.292097535:                                1 branches:uH:   jmp                              7821f3 Time_stamp_counter.now_4481+0x33 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 50.636us BEGIN Time_stamp_counter.now_4481
    4589/4589  108652.292097535:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           6effd4 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1b4 (/tmp/clark.exe)
    4589/4589  108652.292097535:                                1 branches:uH:   call                             6efff9 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1d9 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097547:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           782140 Time_stamp_counter.diff_4466+0x0 (/tmp/clark.exe)
    ->  50.64us END   Time_stamp_counter.now_4481
    ->  50.64us BEGIN Base.Int.of_int_2534
    -> 50.646us END   Base.Int.of_int_2534
    -> 50.646us BEGIN caml_apply2
    4589/4589  108652.292097547:                                1 branches:uH:   jmp                              78215b Time_stamp_counter.diff_4466+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097548:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c862f0 Base.Int63.fun_4900+0x0 (/tmp/clark.exe)
    -> 50.652us END   caml_apply2
    -> 50.652us BEGIN Time_stamp_counter.diff_4466
    -> 50.652us END   Time_stamp_counter.diff_4466
    -> 50.652us BEGIN caml_apply2
    4589/4589  108652.292097549:                                1 branches:uH:   return                           c862f7 Base.Int63.fun_4900+0x7 (/tmp/clark.exe) =>           6efffe Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1de (/tmp/clark.exe)
    -> 50.653us END   caml_apply2
    -> 50.653us BEGIN Base.Int63.fun_4900
    4589/4589  108652.292097549:                                1 branches:uH:   call                             6f000e Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1ee (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097570:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86300 Base.Int63.fun_4898+0x0 (/tmp/clark.exe)
    -> 50.654us END   Base.Int63.fun_4900
    -> 50.654us BEGIN caml_apply2
    4589/4589  108652.292097570:                                1 branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (/tmp/clark.exe) =>           6f0013 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x1f3 (/tmp/clark.exe)
    4589/4589  108652.292097571:                                1 branches:uH:   call                             6f0059 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x239 (/tmp/clark.exe) =>           7aeb60 Nano_mutex.lock_exn_5235+0x0 (/tmp/clark.exe)
    -> 50.675us END   caml_apply2
    -> 50.675us BEGIN Base.Int63.fun_4898
    -> 50.676us END   Base.Int63.fun_4898
    4589/4589  108652.292097571:                                1 branches:uH:   call                             7aeb78 Nano_mutex.lock_exn_5235+0x18 (/tmp/clark.exe) =>           7aea00 Nano_mutex.lock_5231+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097589:                                1 branches:uH:   call                             7aea24 Nano_mutex.lock_5231+0x24 (/tmp/clark.exe) =>           b02db0 Thread.fun_715+0x0 (/tmp/clark.exe)
    -> 50.676us BEGIN Nano_mutex.lock_exn_5235
    -> 50.685us BEGIN Nano_mutex.lock_5231
    4589/4589  108652.292097589:                                1 branches:uH:   call                             b02db7 Thread.fun_715+0x7 (/tmp/clark.exe) =>           d44690 caml_thread_self+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097590:                                1 branches:uH:   return                           d4469f caml_thread_self+0xf (/tmp/clark.exe) =>           b02dbc Thread.fun_715+0xc (/tmp/clark.exe)
    -> 50.694us BEGIN Thread.fun_715
    -> 50.694us BEGIN caml_thread_self
    4589/4589  108652.292097590:                                1 branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (/tmp/clark.exe) =>           7aea26 Nano_mutex.lock_5231+0x26 (/tmp/clark.exe)
    4589/4589  108652.292097592:                                1 branches:uH:   call                             7aea2d Nano_mutex.lock_5231+0x2d (/tmp/clark.exe) =>           b02d90 Thread.fun_713+0x0 (/tmp/clark.exe)
    -> 50.695us END   caml_thread_self
    -> 50.695us END   Thread.fun_715
    4589/4589  108652.292097592:                                1 branches:uH:   call                             b02d97 Thread.fun_713+0x7 (/tmp/clark.exe) =>           d446b0 caml_thread_id+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097593:                                1 branches:uH:   return                           d446b3 caml_thread_id+0x3 (/tmp/clark.exe) =>           b02d9c Thread.fun_713+0xc (/tmp/clark.exe)
    -> 50.697us BEGIN Thread.fun_713
    -> 50.697us BEGIN caml_thread_id
    4589/4589  108652.292097593:                                1 branches:uH:   return                           b02da0 Thread.fun_713+0x10 (/tmp/clark.exe) =>           7aea2f Nano_mutex.lock_5231+0x2f (/tmp/clark.exe)
    4589/4589  108652.292097593:                                1 branches:uH:   call                             7aea50 Nano_mutex.lock_5231+0x50 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097641:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    -> 50.698us END   caml_thread_id
    -> 50.698us END   Thread.fun_713
    -> 50.698us BEGIN caml_apply2
    4589/4589  108652.292097641:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           7aea55 Nano_mutex.lock_5231+0x55 (/tmp/clark.exe)
    4589/4589  108652.292097641:                                1 branches:uH:   call                             7aea64 Nano_mutex.lock_5231+0x64 (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097643:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           7aea69 Nano_mutex.lock_5231+0x69 (/tmp/clark.exe)
    -> 50.746us END   caml_apply2
    -> 50.746us BEGIN Core.Int.fun_13981
    -> 50.747us END   Core.Int.fun_13981
    -> 50.747us BEGIN caml_modify
    4589/4589  108652.292097643:                                1 branches:uH:   return                           7aea74 Nano_mutex.lock_5231+0x74 (/tmp/clark.exe) =>           7aeb7d Nano_mutex.lock_exn_5235+0x1d (/tmp/clark.exe)
    4589/4589  108652.292097644:                                1 branches:uH:   jmp                              7aeb88 Nano_mutex.lock_exn_5235+0x28 (/tmp/clark.exe) =>           c15330 Base.Or_error.ok_exn_2208+0x0 (/tmp/clark.exe)
    -> 50.748us END   caml_modify
    -> 50.748us END   Nano_mutex.lock_5231
    4589/4589  108652.292097644:                                1 branches:uH:   return                           c15407 Base.Or_error.ok_exn_2208+0xd7 (/tmp/clark.exe) =>           6f005b Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x23b (/tmp/clark.exe)
    4589/4589  108652.292097644:                                1 branches:uH:   call                             6f0064 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x244 (/tmp/clark.exe) =>           6df5d0 Async_unix.Interruptor.clear_4845+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097644:                                1 branches:uH:   call                             6df662 Async_unix.Interruptor.clear_4845+0x92 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097653:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           79d9e0 Read_write_pair.get_2289+0x0 (/tmp/clark.exe)
    -> 50.749us END   Nano_mutex.lock_exn_5235
    -> 50.749us BEGIN Base.Or_error.ok_exn_2208
    -> 50.752us END   Base.Or_error.ok_exn_2208
    -> 50.752us BEGIN Async_unix.Interruptor.clear_4845
    -> 50.755us BEGIN caml_apply2
    4589/4589  108652.292097653:                                1 branches:uH:   return                           79d9ec Read_write_pair.get_2289+0xc (/tmp/clark.exe) =>           6df667 Async_unix.Interruptor.clear_4845+0x97 (/tmp/clark.exe)
    4589/4589  108652.292097653:                                1 branches:uH:   call                             6df67b Async_unix.Interruptor.clear_4845+0xab (/tmp/clark.exe) =>           6dc310 Async_unix.Raw_fd.syscall_5838+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097672:                                1 branches:uH:   call                             6dc3a9 Async_unix.Raw_fd.syscall_5838+0x99 (/tmp/clark.exe) =>           6dbef0 Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446+0x0 (/tmp/clark.exe)
    -> 50.758us END   caml_apply2
    -> 50.758us BEGIN Read_write_pair.get_2289
    -> 50.767us END   Read_write_pair.get_2289
    -> 50.767us BEGIN Async_unix.Raw_fd.syscall_5838
    4589/4589  108652.292097677:                                1 branches:uH:   return                           6dbf88 Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446+0x98 (/tmp/clark.exe) =>           6dc3ae Async_unix.Raw_fd.syscall_5838+0x9e (/tmp/clark.exe)
    -> 50.777us BEGIN Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446
    4589/4589  108652.292097683:                                1 branches:uH:   call                             6dc3be Async_unix.Raw_fd.syscall_5838+0xae (/tmp/clark.exe) =>           6dc450 Async_unix.Raw_fd.fun_7461+0x0 (/tmp/clark.exe)
    -> 50.782us END   Async_unix.Raw_fd.set_nonblock_if_necessary_inner_7446
    4589/4589  108652.292097696:                                1 branches:uH:   call                             6dc4d0 Async_unix.Raw_fd.fun_7461+0x80 (/tmp/clark.exe) =>           6dc580 Async_unix.Raw_fd.fun_7471+0x0 (/tmp/clark.exe)
    -> 50.788us BEGIN Async_unix.Raw_fd.fun_7461
    4589/4589  108652.292097696:                                1 branches:uH:   jmp                              6dc59b Async_unix.Raw_fd.fun_7471+0x1b (/tmp/clark.exe) =>           6df780 Async_unix.Interruptor.fun_5020+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097696:                                1 branches:uH:   call                             6df833 Async_unix.Interruptor.fun_5020+0xb3 (/tmp/clark.exe) =>           6c8950 caml_apply4+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097737:                                1 branches:uH:   jmp                              6c896a caml_apply4+0x1a (/tmp/clark.exe) =>           8f0410 Core_unix.read_assume_fd_is_nonblocking_5385+0x0 (/tmp/clark.exe)
    -> 50.801us BEGIN Async_unix.Raw_fd.fun_7471
    -> 50.814us END   Async_unix.Raw_fd.fun_7471
    -> 50.814us BEGIN Async_unix.Interruptor.fun_5020
    -> 50.828us BEGIN caml_apply4
    4589/4589  108652.292097737:                                1 branches:uH:   call                             8f0443 Core_unix.read_assume_fd_is_nonblocking_5385+0x33 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097738:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 50.842us END   caml_apply4
    -> 50.842us BEGIN Core_unix.read_assume_fd_is_nonblocking_5385
    -> 50.842us BEGIN caml_apply2
    4589/4589  108652.292097739:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f0448 Core_unix.read_assume_fd_is_nonblocking_5385+0x38 (/tmp/clark.exe)
    -> 50.843us END   caml_apply2
    -> 50.843us BEGIN Core.Int.fun_13985
    4589/4589  108652.292097739:                                1 branches:uH:   call                             8f04f2 Core_unix.read_assume_fd_is_nonblocking_5385+0xe2 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097741:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 50.844us END   Core.Int.fun_13985
    -> 50.844us BEGIN caml_apply2
    4589/4589  108652.292097741:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f04f7 Core_unix.read_assume_fd_is_nonblocking_5385+0xe7 (/tmp/clark.exe)
    4589/4589  108652.292097741:                                1 branches:uH:   call                             8f0548 Core_unix.read_assume_fd_is_nonblocking_5385+0x138 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097742:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 50.846us END   caml_apply2
    -> 50.846us BEGIN Core.Int.fun_13985
    -> 50.846us END   Core.Int.fun_13985
    -> 50.846us BEGIN caml_apply2
    4589/4589  108652.292097743:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f054d Core_unix.read_assume_fd_is_nonblocking_5385+0x13d (/tmp/clark.exe)
    -> 50.847us END   caml_apply2
    -> 50.847us BEGIN Core.Int.fun_13985
    4589/4589  108652.292097743:                                1 branches:uH:   call                             8f05c5 Core_unix.read_assume_fd_is_nonblocking_5385+0x1b5 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097744:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 50.848us END   Core.Int.fun_13985
    -> 50.848us BEGIN caml_apply2
    4589/4589  108652.292097745:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f05ca Core_unix.read_assume_fd_is_nonblocking_5385+0x1ba (/tmp/clark.exe)
    -> 50.849us END   caml_apply2
    -> 50.849us BEGIN Core.Int.fun_13985
    4589/4589  108652.292097745:                                1 branches:uH:   call                             8f0622 Core_unix.read_assume_fd_is_nonblocking_5385+0x212 (/tmp/clark.exe) =>           d6d414 caml_c_call+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097746:                                1 branches:uH:   jmp                              d6d43c caml_c_call+0x28 (/tmp/clark.exe) =>           d3eda0 core_unix_read_assume_fd_is_nonblocking_stub+0x0 (/tmp/clark.exe)
    ->  50.85us END   Core.Int.fun_13985
    ->  50.85us BEGIN caml_c_call
    4589/4589  108652.292097746:                                1 branches:uH:   call                             d3edb6 core_unix_read_assume_fd_is_nonblocking_stub+0x16 (/tmp/clark.exe) =>           685d90 read@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292097747:                                1 branches:uH:   jmp                              685d90 read@plt+0x0 (/tmp/clark.exe) =>     7ffff79ca730 __libc_read+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 50.851us END   caml_c_call
    -> 50.851us BEGIN core_unix_read_assume_fd_is_nonblocking_stub
    -> 50.851us BEGIN read@plt
    4589/4589  108652.292097747:                                1 branches:uH:   jcc                        7ffff79ca737 __libc_read+0x7 (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca749 [unknown] (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292097747:                                1 branches:uH:   call                       7ffff79ca74d [unknown] (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca440 __pthread_enable_asynccancel+0x0 (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292097747:                                1 branches:uH:   return                     7ffff79ca46b __pthread_enable_asynccancel+0x2b (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca752 [unknown] (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292097765:                                1 branches:uH:   tr end  syscall            7ffff79ca75b [unknown] (/usr/lib64/libpthread-2.17.so) =>                0 [unknown] ([unknown])
    -> 50.852us END   read@plt
    -> 50.852us BEGIN __libc_read
    -> 50.856us END   __libc_read
    -> 50.856us BEGIN [unknown @ 0x7ffff79ca749 (/usr/lib64/libpthread-2.17.so)]
    ->  50.86us BEGIN __pthread_enable_asynccancel
    -> 50.865us END   __pthread_enable_asynccancel
    -> 50.865us END   [unknown @ 0x7ffff79ca749 (/usr/lib64/libpthread-2.17.so)]
    -> 50.865us BEGIN [unknown @ 0x7ffff79ca752 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098327:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff79ca75d [unknown] (/usr/lib64/libpthread-2.17.so)
    ->  50.87us BEGIN [syscall]
    4589/4589  108652.292098327:                                1 branches:uH:   call                       7ffff79ca764 [unknown] (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca4a0 __pthread_disable_asynccancel+0x0 (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098338:                                1 branches:uH:   return                     7ffff79ca4cf __pthread_disable_asynccancel+0x2f (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca769 [unknown] (/usr/lib64/libpthread-2.17.so)
    -> 51.432us END   [syscall]
    -> 51.432us BEGIN __pthread_disable_asynccancel
    4589/4589  108652.292098344:                                1 branches:uH:   return                     7ffff79ca778 [unknown] (/usr/lib64/libpthread-2.17.so) =>           d3edbb core_unix_read_assume_fd_is_nonblocking_stub+0x1b (/tmp/clark.exe)
    -> 51.443us END   __pthread_disable_asynccancel
    -> 51.443us END   [unknown @ 0x7ffff79ca752 (/usr/lib64/libpthread-2.17.so)]
    -> 51.443us BEGIN [unknown @ 0x7ffff79ca769 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098345:                                1 branches:uH:   return                           d3edca core_unix_read_assume_fd_is_nonblocking_stub+0x2a (/tmp/clark.exe) =>           8f0627 Core_unix.read_assume_fd_is_nonblocking_5385+0x217 (/tmp/clark.exe)
    -> 51.449us END   [unknown @ 0x7ffff79ca769 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098345:                                1 branches:uH:   return                           8f062f Core_unix.read_assume_fd_is_nonblocking_5385+0x21f (/tmp/clark.exe) =>           6df838 Async_unix.Interruptor.fun_5020+0xb8 (/tmp/clark.exe)
    4589/4589  108652.292098345:                                1 branches:uH:   jmp                              6df89f Async_unix.Interruptor.fun_5020+0x11f (/tmp/clark.exe) =>           6df8c0 Async_unix.Interruptor.loop_4849+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098345:                                1 branches:uH:   call                             6df942 Async_unix.Interruptor.loop_4849+0x82 (/tmp/clark.exe) =>           6c8950 caml_apply4+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098353:                                1 branches:uH:   jmp                              6c896a caml_apply4+0x1a (/tmp/clark.exe) =>           8f0410 Core_unix.read_assume_fd_is_nonblocking_5385+0x0 (/tmp/clark.exe)
    ->  51.45us END   core_unix_read_assume_fd_is_nonblocking_stub
    ->  51.45us END   Core_unix.read_assume_fd_is_nonblocking_5385
    ->  51.45us END   Async_unix.Interruptor.fun_5020
    ->  51.45us END   Async_unix.Interruptor.fun_5020
    ->  51.45us BEGIN Async_unix.Interruptor.loop_4849
    -> 51.454us BEGIN caml_apply4
    4589/4589  108652.292098353:                                1 branches:uH:   call                             8f0443 Core_unix.read_assume_fd_is_nonblocking_5385+0x33 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098354:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 51.458us END   caml_apply4
    -> 51.458us BEGIN Core_unix.read_assume_fd_is_nonblocking_5385
    -> 51.458us BEGIN caml_apply2
    4589/4589  108652.292098354:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f0448 Core_unix.read_assume_fd_is_nonblocking_5385+0x38 (/tmp/clark.exe)
    4589/4589  108652.292098354:                                1 branches:uH:   call                             8f04f2 Core_unix.read_assume_fd_is_nonblocking_5385+0xe2 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098356:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 51.459us END   caml_apply2
    -> 51.459us BEGIN Core.Int.fun_13985
    ->  51.46us END   Core.Int.fun_13985
    ->  51.46us BEGIN caml_apply2
    4589/4589  108652.292098357:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f04f7 Core_unix.read_assume_fd_is_nonblocking_5385+0xe7 (/tmp/clark.exe)
    -> 51.461us END   caml_apply2
    -> 51.461us BEGIN Core.Int.fun_13985
    4589/4589  108652.292098357:                                1 branches:uH:   call                             8f0548 Core_unix.read_assume_fd_is_nonblocking_5385+0x138 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098358:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 51.462us END   Core.Int.fun_13985
    -> 51.462us BEGIN caml_apply2
    4589/4589  108652.292098359:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f054d Core_unix.read_assume_fd_is_nonblocking_5385+0x13d (/tmp/clark.exe)
    -> 51.463us END   caml_apply2
    -> 51.463us BEGIN Core.Int.fun_13985
    4589/4589  108652.292098359:                                1 branches:uH:   call                             8f05c5 Core_unix.read_assume_fd_is_nonblocking_5385+0x1b5 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098360:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 51.464us END   Core.Int.fun_13985
    -> 51.464us BEGIN caml_apply2
    4589/4589  108652.292098360:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           8f05ca Core_unix.read_assume_fd_is_nonblocking_5385+0x1ba (/tmp/clark.exe)
    4589/4589  108652.292098360:                                1 branches:uH:   call                             8f0622 Core_unix.read_assume_fd_is_nonblocking_5385+0x212 (/tmp/clark.exe) =>           d6d414 caml_c_call+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098361:                                1 branches:uH:   jmp                              d6d43c caml_c_call+0x28 (/tmp/clark.exe) =>           d3eda0 core_unix_read_assume_fd_is_nonblocking_stub+0x0 (/tmp/clark.exe)
    -> 51.465us END   caml_apply2
    -> 51.465us BEGIN Core.Int.fun_13985
    -> 51.465us END   Core.Int.fun_13985
    -> 51.465us BEGIN caml_c_call
    4589/4589  108652.292098361:                                1 branches:uH:   call                             d3edb6 core_unix_read_assume_fd_is_nonblocking_stub+0x16 (/tmp/clark.exe) =>           685d90 read@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098362:                                1 branches:uH:   jmp                              685d90 read@plt+0x0 (/tmp/clark.exe) =>     7ffff79ca730 __libc_read+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 51.466us END   caml_c_call
    -> 51.466us BEGIN core_unix_read_assume_fd_is_nonblocking_stub
    -> 51.466us BEGIN read@plt
    4589/4589  108652.292098363:                                1 branches:uH:   jcc                        7ffff79ca737 __libc_read+0x7 (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca749 [unknown] (/usr/lib64/libpthread-2.17.so)
    -> 51.467us END   read@plt
    -> 51.467us BEGIN __libc_read
    4589/4589  108652.292098363:                                1 branches:uH:   call                       7ffff79ca74d [unknown] (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca440 __pthread_enable_asynccancel+0x0 (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098363:                                1 branches:uH:   return                     7ffff79ca46b __pthread_enable_asynccancel+0x2b (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca752 [unknown] (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098381:                                1 branches:uH:   tr end  syscall            7ffff79ca75b [unknown] (/usr/lib64/libpthread-2.17.so) =>                0 [unknown] ([unknown])
    -> 51.468us END   __libc_read
    -> 51.468us BEGIN [unknown @ 0x7ffff79ca749 (/usr/lib64/libpthread-2.17.so)]
    -> 51.474us BEGIN __pthread_enable_asynccancel
    ->  51.48us END   __pthread_enable_asynccancel
    ->  51.48us END   [unknown @ 0x7ffff79ca749 (/usr/lib64/libpthread-2.17.so)]
    ->  51.48us BEGIN [unknown @ 0x7ffff79ca752 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098632:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff79ca75d [unknown] (/usr/lib64/libpthread-2.17.so)
    -> 51.486us BEGIN [syscall]
    4589/4589  108652.292098632:                                1 branches:uH:   call                       7ffff79ca764 [unknown] (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca4a0 __pthread_disable_asynccancel+0x0 (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098641:                                1 branches:uH:   return                     7ffff79ca4cf __pthread_disable_asynccancel+0x2f (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca769 [unknown] (/usr/lib64/libpthread-2.17.so)
    -> 51.737us END   [syscall]
    -> 51.737us BEGIN __pthread_disable_asynccancel
    4589/4589  108652.292098641:                                1 branches:uH:   jcc                        7ffff79ca776 [unknown] (/usr/lib64/libpthread-2.17.so) =>     7ffff79ca779 [unknown] (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098648:                                1 branches:uH:   return                     7ffff79ca789 [unknown] (/usr/lib64/libpthread-2.17.so) =>           d3edbb core_unix_read_assume_fd_is_nonblocking_stub+0x1b (/tmp/clark.exe)
    -> 51.746us END   __pthread_disable_asynccancel
    -> 51.746us END   [unknown @ 0x7ffff79ca752 (/usr/lib64/libpthread-2.17.so)]
    -> 51.746us BEGIN [unknown @ 0x7ffff79ca769 (/usr/lib64/libpthread-2.17.so)]
    -> 51.749us END   [unknown @ 0x7ffff79ca769 (/usr/lib64/libpthread-2.17.so)]
    -> 51.749us BEGIN [unknown @ 0x7ffff79ca779 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098649:                                1 branches:uH:   call                             d3edd4 core_unix_read_assume_fd_is_nonblocking_stub+0x34 (/tmp/clark.exe) =>           d4ac30 uerror+0x0 (/tmp/clark.exe)
    -> 51.753us END   [unknown @ 0x7ffff79ca779 (/usr/lib64/libpthread-2.17.so)]
    4589/4589  108652.292098649:                                1 branches:uH:   call                             d4ac3c uerror+0xc (/tmp/clark.exe) =>           685c00 __errno_location@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098666:                                1 branches:uH:   jmp                              685c00 __errno_location@plt+0x0 (/tmp/clark.exe) =>     7ffff79ccda0 __errno_location+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 51.754us BEGIN uerror
    -> 51.762us BEGIN __errno_location@plt
    4589/4589  108652.292098668:                                1 branches:uH:   return                     7ffff79ccdb0 __errno_location+0x10 (/usr/lib64/libpthread-2.17.so) =>           d4ac41 uerror+0x11 (/tmp/clark.exe)
    -> 51.771us END   __errno_location@plt
    -> 51.771us BEGIN __errno_location
    4589/4589  108652.292098668:                                1 branches:uH:   call                             d4ac49 uerror+0x19 (/tmp/clark.exe) =>           d4ab00 unix_error+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098668:                                1 branches:uH:   call                             d4abfc unix_error+0xfc (/tmp/clark.exe) =>           d54fb0 caml_copy_string+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098668:                                1 branches:uH:   call                             d54fb9 caml_copy_string+0x9 (/tmp/clark.exe) =>           685c50 strlen@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098680:                                1 branches:uH:   jmp                              685c50 strlen@plt+0x0 (/tmp/clark.exe) =>     7ffff72578c0 __strlen_sse2_pminub+0x0 (/usr/lib64/libc-2.17.so)
    -> 51.773us END   __errno_location
    -> 51.773us BEGIN unix_error
    -> 51.777us BEGIN caml_copy_string
    -> 51.781us BEGIN strlen@plt
    4589/4589  108652.292098693:                                1 branches:uH:   return                     7ffff7257b3a __strlen_sse2_pminub+0x27a (/usr/lib64/libc-2.17.so) =>           d54fbe caml_copy_string+0xe (/tmp/clark.exe)
    -> 51.785us END   strlen@plt
    -> 51.785us BEGIN __strlen_sse2_pminub
    4589/4589  108652.292098693:                                1 branches:uH:   call                             d54fc4 caml_copy_string+0x14 (/tmp/clark.exe) =>           d54ee0 caml_alloc_string+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098693:                                1 branches:uH:   return                           d54f57 caml_alloc_string+0x77 (/tmp/clark.exe) =>           d54fc9 caml_copy_string+0x19 (/tmp/clark.exe)
    4589/4589  108652.292098693:                                1 branches:uH:   call                             d54fd2 caml_copy_string+0x22 (/tmp/clark.exe) =>           685e30 memcpy@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098712:                                1 branches:uH:   jmp                              685e30 memcpy@plt+0x0 (/tmp/clark.exe) =>     7ffff723cc80 __memcpy_ssse3_back+0x0 (/usr/lib64/libc-2.17.so)
    -> 51.798us END   __strlen_sse2_pminub
    -> 51.798us BEGIN caml_alloc_string
    -> 51.807us END   caml_alloc_string
    -> 51.807us BEGIN memcpy@plt
    4589/4589  108652.292098723:                                1 branches:uH:   return                     7ffff723f0ae __memcpy_ssse3_back+0x242e (/usr/lib64/libc-2.17.so) =>           d54fd7 caml_copy_string+0x27 (/tmp/clark.exe)
    -> 51.817us END   memcpy@plt
    -> 51.817us BEGIN __memcpy_ssse3_back
    4589/4589  108652.292098723:                                1 branches:uH:   return                           d54fdd caml_copy_string+0x2d (/tmp/clark.exe) =>           d4ac01 unix_error+0x101 (/tmp/clark.exe)
    4589/4589  108652.292098723:                                1 branches:uH:   call                             d4ab85 unix_error+0x85 (/tmp/clark.exe) =>           d54fb0 caml_copy_string+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098723:                                1 branches:uH:   call                             d54fb9 caml_copy_string+0x9 (/tmp/clark.exe) =>           685c50 strlen@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098726:                                1 branches:uH:   jmp                              685c50 strlen@plt+0x0 (/tmp/clark.exe) =>     7ffff72578c0 __strlen_sse2_pminub+0x0 (/usr/lib64/libc-2.17.so)
    -> 51.828us END   __memcpy_ssse3_back
    -> 51.828us END   caml_copy_string
    -> 51.828us BEGIN caml_copy_string
    -> 51.829us BEGIN strlen@plt
    4589/4589  108652.292098727:                                1 branches:uH:   return                     7ffff7257b5e __strlen_sse2_pminub+0x29e (/usr/lib64/libc-2.17.so) =>           d54fbe caml_copy_string+0xe (/tmp/clark.exe)
    -> 51.831us END   strlen@plt
    -> 51.831us BEGIN __strlen_sse2_pminub
    4589/4589  108652.292098727:                                1 branches:uH:   call                             d54fc4 caml_copy_string+0x14 (/tmp/clark.exe) =>           d54ee0 caml_alloc_string+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098740:                                1 branches:uH:   return                           d54f57 caml_alloc_string+0x77 (/tmp/clark.exe) =>           d54fc9 caml_copy_string+0x19 (/tmp/clark.exe)
    -> 51.832us END   __strlen_sse2_pminub
    -> 51.832us BEGIN caml_alloc_string
    4589/4589  108652.292098740:                                1 branches:uH:   call                             d54fd2 caml_copy_string+0x22 (/tmp/clark.exe) =>           685e30 memcpy@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098746:                                1 branches:uH:   jmp                              685e30 memcpy@plt+0x0 (/tmp/clark.exe) =>     7ffff723cc80 __memcpy_ssse3_back+0x0 (/usr/lib64/libc-2.17.so)
    -> 51.845us END   caml_alloc_string
    -> 51.845us BEGIN memcpy@plt
    4589/4589  108652.292098763:                                1 branches:uH:   return                     7ffff723efc0 __memcpy_ssse3_back+0x2340 (/usr/lib64/libc-2.17.so) =>           d54fd7 caml_copy_string+0x27 (/tmp/clark.exe)
    -> 51.851us END   memcpy@plt
    -> 51.851us BEGIN __memcpy_ssse3_back
    4589/4589  108652.292098763:                                1 branches:uH:   return                           d54fdd caml_copy_string+0x2d (/tmp/clark.exe) =>           d4ab8a unix_error+0x8a (/tmp/clark.exe)
    4589/4589  108652.292098763:                                1 branches:uH:   call                             d4ab91 unix_error+0x91 (/tmp/clark.exe) =>           d4aa80 unix_error_of_code+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098763:                                1 branches:uH:   call                             d4aa97 unix_error_of_code+0x17 (/tmp/clark.exe) =>           d4b370 cst_to_constr+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098777:                                1 branches:uH:   return                           d4b3a5 cst_to_constr+0x35 (/tmp/clark.exe) =>           d4aa9c unix_error_of_code+0x1c (/tmp/clark.exe)
    -> 51.868us END   __memcpy_ssse3_back
    -> 51.868us END   caml_copy_string
    -> 51.868us BEGIN unix_error_of_code
    -> 51.875us BEGIN cst_to_constr
    4589/4589  108652.292098777:                                1 branches:uH:   return                           d4aaa7 unix_error_of_code+0x27 (/tmp/clark.exe) =>           d4ab96 unix_error+0x96 (/tmp/clark.exe)
    4589/4589  108652.292098777:                                1 branches:uH:   call                             d4abac unix_error+0xac (/tmp/clark.exe) =>           d54e60 caml_alloc_small+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098779:                                1 branches:uH:   return                           d54ecc caml_alloc_small+0x6c (/tmp/clark.exe) =>           d4abb1 unix_error+0xb1 (/tmp/clark.exe)
    -> 51.882us END   cst_to_constr
    -> 51.882us END   unix_error_of_code
    -> 51.882us BEGIN caml_alloc_small
    4589/4589  108652.292098779:                                1 branches:uH:   call                             d4abeb unix_error+0xeb (/tmp/clark.exe) =>           d4c7a0 caml_raise+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098797:                                1 branches:uH:   call                             d4c7b5 caml_raise+0x15 (/tmp/clark.exe) =>           d438f0 caml_io_mutex_unlock_exn+0x0 (/tmp/clark.exe)
    -> 51.884us END   caml_alloc_small
    -> 51.884us BEGIN caml_raise
    4589/4589  108652.292098797:                                1 branches:uH:   call                             d438fa caml_io_mutex_unlock_exn+0xa (/tmp/clark.exe) =>           686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098797:                                1 branches:uH:   jmp                              686400 pthread_getspecific@plt+0x0 (/tmp/clark.exe) =>     7ffff79c8870 pthread_getspecific+0x0 (/usr/lib64/libpthread-2.17.so)
    4589/4589  108652.292098797:                                1 branches:uH:   return                     7ffff79c88b2 pthread_getspecific+0x42 (/usr/lib64/libpthread-2.17.so) =>           d438ff caml_io_mutex_unlock_exn+0xf (/tmp/clark.exe)
    4589/4589  108652.292098797:                                1 branches:uH:   return                           d43914 caml_io_mutex_unlock_exn+0x24 (/tmp/clark.exe) =>           d4c7b7 caml_raise+0x17 (/tmp/clark.exe)
    4589/4589  108652.292098797:                                1 branches:uH:   call                             d4c7bc caml_raise+0x1c (/tmp/clark.exe) =>           d4e180 caml_process_pending_actions_with_root+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098797:                                1 branches:uH:   call                             d4e1a0 caml_process_pending_actions_with_root+0x20 (/tmp/clark.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098814:                                1 branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (/tmp/clark.exe) =>           d4e1a5 caml_process_pending_actions_with_root+0x25 (/tmp/clark.exe)
    -> 51.902us BEGIN caml_io_mutex_unlock_exn
    -> 51.905us BEGIN pthread_getspecific@plt
    -> 51.908us END   pthread_getspecific@plt
    -> 51.908us BEGIN pthread_getspecific
    -> 51.911us END   pthread_getspecific
    -> 51.911us END   caml_io_mutex_unlock_exn
    -> 51.911us BEGIN caml_process_pending_actions_with_root
    -> 51.915us BEGIN caml_raise_async_if_exception
    4589/4589  108652.292098814:                                1 branches:uH:   return                           d4e1ae caml_process_pending_actions_with_root+0x2e (/tmp/clark.exe) =>           d4c7c1 caml_raise+0x21 (/tmp/clark.exe)
    4589/4589  108652.292098814:                                1 branches:uH:   call                             d4c7f7 caml_raise+0x57 (/tmp/clark.exe) =>           d6d500 caml_raise_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098814:                                1 branches:uH:   call                             d6d53c caml_raise_exception+0x3c (/tmp/clark.exe) =>           d6d750 caml_stash_backtrace+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098818:                                1 branches:uH:   call                             d6d7cb caml_stash_backtrace+0x7b (/tmp/clark.exe) =>           d6d660 caml_next_frame_descriptor+0x0 (/tmp/clark.exe)
    -> 51.919us END   caml_raise_async_if_exception
    -> 51.919us END   caml_process_pending_actions_with_root
    -> 51.919us BEGIN caml_raise_exception
    -> 51.921us BEGIN caml_stash_backtrace
    4589/4589  108652.292098843:                                1 branches:uH:   call                             d6d6e6 caml_next_frame_descriptor+0x86 (/tmp/clark.exe) =>           d4cfa0 get_frame_size+0x0 (/tmp/clark.exe)
    -> 51.923us BEGIN caml_next_frame_descriptor
    4589/4589  108652.292098843:                                1 branches:uH:   return                           d4cfab get_frame_size+0xb (/tmp/clark.exe) =>           d6d6eb caml_next_frame_descriptor+0x8b (/tmp/clark.exe)
    4589/4589  108652.292098843:                                1 branches:uH:   return                           d6d6da caml_next_frame_descriptor+0x7a (/tmp/clark.exe) =>           d6d7d0 caml_stash_backtrace+0x80 (/tmp/clark.exe)
    4589/4589  108652.292098860:                                1 branches:uH:   call                             d6d7cb caml_stash_backtrace+0x7b (/tmp/clark.exe) =>           d6d660 caml_next_frame_descriptor+0x0 (/tmp/clark.exe)
    -> 51.948us BEGIN get_frame_size
    -> 51.965us END   get_frame_size
    -> 51.965us END   caml_next_frame_descriptor
    4589/4589  108652.292098876:                                1 branches:uH:   call                             d6d6e6 caml_next_frame_descriptor+0x86 (/tmp/clark.exe) =>           d4cfa0 get_frame_size+0x0 (/tmp/clark.exe)
    -> 51.965us BEGIN caml_next_frame_descriptor
    4589/4589  108652.292098876:                                1 branches:uH:   return                           d4cfab get_frame_size+0xb (/tmp/clark.exe) =>           d6d6eb caml_next_frame_descriptor+0x8b (/tmp/clark.exe)
    4589/4589  108652.292098876:                                1 branches:uH:   return                           d6d6da caml_next_frame_descriptor+0x7a (/tmp/clark.exe) =>           d6d7d0 caml_stash_backtrace+0x80 (/tmp/clark.exe)
    4589/4589  108652.292098880:                                1 branches:uH:   return                           d6d7da caml_stash_backtrace+0x8a (/tmp/clark.exe) =>           d6d541 caml_raise_exception+0x41 (/tmp/clark.exe)
    -> 51.981us BEGIN get_frame_size
    -> 51.985us END   get_frame_size
    -> 51.985us END   caml_next_frame_descriptor
    4589/4589  108652.292098882:                                1 branches:uH:   return                           d6d550 caml_raise_exception+0x50 (/tmp/clark.exe) =>           6df958 Async_unix.Interruptor.loop_4849+0x98 (/tmp/clark.exe)
    -> 51.985us END   caml_stash_backtrace
    4589/4589  108652.292098883:                                1 branches:uH:   return                           6df9b9 Async_unix.Interruptor.loop_4849+0xf9 (/tmp/clark.exe) =>           6dc4d2 Async_unix.Raw_fd.fun_7461+0x82 (/tmp/clark.exe)
    -> 51.987us END   caml_raise_exception
    -> 51.987us END   caml_raise
    -> 51.987us BEGIN Async_unix.Interruptor.loop_4849
    4589/4589  108652.292098885:                                1 branches:uH:   jmp                              6dc565 Async_unix.Raw_fd.fun_7461+0x115 (/tmp/clark.exe) =>           bf1680 Base.Result.ok_exn_2063+0x0 (/tmp/clark.exe)
    -> 51.988us END   Async_unix.Interruptor.loop_4849
    -> 51.988us END   unix_error
    -> 51.988us BEGIN Async_unix.Raw_fd.fun_7461
    -> 51.989us END   Async_unix.Raw_fd.fun_7461
    -> 51.989us END   uerror
    -> 51.989us END   core_unix_read_assume_fd_is_nonblocking_stub
    -> 51.989us END   Core_unix.read_assume_fd_is_nonblocking_5385
    -> 51.989us END   Async_unix.Interruptor.loop_4849
    -> 51.989us BEGIN Async_unix.Raw_fd.fun_7461
    4589/4589  108652.292098885:                                1 branches:uH:   return                           bf169f Base.Result.ok_exn_2063+0x1f (/tmp/clark.exe) =>           6dc3c0 Async_unix.Raw_fd.syscall_5838+0xb0 (/tmp/clark.exe)
    4589/4589  108652.292098888:                                1 branches:uH:   return                           6dc3ef Async_unix.Raw_fd.syscall_5838+0xdf (/tmp/clark.exe) =>           6df680 Async_unix.Interruptor.clear_4845+0xb0 (/tmp/clark.exe)
    ->  51.99us END   Async_unix.Raw_fd.fun_7461
    ->  51.99us BEGIN Base.Result.ok_exn_2063
    -> 51.993us END   Base.Result.ok_exn_2063
    4589/4589  108652.292098905:                                1 branches:uH:   return                           6df755 Async_unix.Interruptor.clear_4845+0x185 (/tmp/clark.exe) =>           6f0069 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x249 (/tmp/clark.exe)
    -> 51.993us END   Async_unix.Raw_fd.syscall_5838
    -> 51.993us END   Async_unix.Raw_fd.fun_7461
    -> 51.993us END   Async_unix.Raw_fd.syscall_5838
    -> 51.993us BEGIN Async_unix.Interruptor.clear_4845
    4589/4589  108652.292098915:                                1 branches:uH:   jmp                              6f0106 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x2e6 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    ->  52.01us END   Async_unix.Interruptor.clear_4845
    4589/4589  108652.292098924:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           6d5260 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x0 (/tmp/clark.exe)
    ->  52.02us END   Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    ->  52.02us BEGIN caml_apply2
    4589/4589  108652.292098926:                                1 branches:uH:   call                             6d54d8 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x278 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 52.029us END   caml_apply2
    -> 52.029us BEGIN Async_unix.Epoll_file_descr_watcher.post_check_9714
    4589/4589  108652.292098929:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           7b89b0 Linux_ext.iter_ready_23395+0x0 (/tmp/clark.exe)
    -> 52.031us BEGIN caml_apply2
    4589/4589  108652.292098929:                                1 branches:uH:   call                             7b8a51 Linux_ext.iter_ready_23395+0xa1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098956:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           b191c0 Base_bigstring.unsafe_read_int32_int_4581+0x0 (/tmp/clark.exe)
    -> 52.034us END   caml_apply2
    -> 52.034us BEGIN Linux_ext.iter_ready_23395
    -> 52.047us BEGIN caml_apply2
    4589/4589  108652.292098956:                                1 branches:uH:   return                           b191d6 Base_bigstring.unsafe_read_int32_int_4581+0x16 (/tmp/clark.exe) =>           7b8a56 Linux_ext.iter_ready_23395+0xa6 (/tmp/clark.exe)
    4589/4589  108652.292098957:                                1 branches:uH:   call                             7b8a5d Linux_ext.iter_ready_23395+0xad (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 52.061us END   caml_apply2
    -> 52.061us BEGIN Base_bigstring.unsafe_read_int32_int_4581
    -> 52.062us END   Base_bigstring.unsafe_read_int32_int_4581
    4589/4589  108652.292098957:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           7b8a5f Linux_ext.iter_ready_23395+0xaf (/tmp/clark.exe)
    4589/4589  108652.292098957:                                1 branches:uH:   call                             7b8ab5 Linux_ext.iter_ready_23395+0x105 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098958:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           b191c0 Base_bigstring.unsafe_read_int32_int_4581+0x0 (/tmp/clark.exe)
    -> 52.062us BEGIN Base.Int.of_int_2534
    -> 52.062us END   Base.Int.of_int_2534
    -> 52.062us BEGIN caml_apply2
    4589/4589  108652.292098959:                                1 branches:uH:   return                           b191d6 Base_bigstring.unsafe_read_int32_int_4581+0x16 (/tmp/clark.exe) =>           7b8aba Linux_ext.iter_ready_23395+0x10a (/tmp/clark.exe)
    -> 52.063us END   caml_apply2
    -> 52.063us BEGIN Base_bigstring.unsafe_read_int32_int_4581
    4589/4589  108652.292098959:                                1 branches:uH:   call                             7b8ac1 Linux_ext.iter_ready_23395+0x111 (/tmp/clark.exe) =>           8e8b20 Core_unix.File_descr.fun_6838+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098970:                                1 branches:uH:   return                           8e8b20 Core_unix.File_descr.fun_6838+0x0 (/tmp/clark.exe) =>           7b8ac3 Linux_ext.iter_ready_23395+0x113 (/tmp/clark.exe)
    -> 52.064us END   Base_bigstring.unsafe_read_int32_int_4581
    -> 52.064us BEGIN Core_unix.File_descr.fun_6838
    4589/4589  108652.292098970:                                1 branches:uH:   call                             7b8acd Linux_ext.iter_ready_23395+0x11d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292098977:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           6d4b10 Async_unix.Epoll_file_descr_watcher.fun_9948+0x0 (/tmp/clark.exe)
    -> 52.075us END   Core_unix.File_descr.fun_6838
    -> 52.075us BEGIN caml_apply2
    4589/4589  108652.292098980:                                1 branches:uH:   call                             6d4b43 Async_unix.Epoll_file_descr_watcher.fun_9948+0x33 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 52.082us END   caml_apply2
    -> 52.082us BEGIN Async_unix.Epoll_file_descr_watcher.fun_9948
    4589/4589  108652.292098995:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           93f870 Flags.do_intersect_4857+0x0 (/tmp/clark.exe)
    -> 52.085us BEGIN caml_apply2
    4589/4589  108652.292098995:                                1 branches:uH:   call                             93f89b Flags.do_intersect_4857+0x2b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099004:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c659c0 Base.Int.bit_and_2579+0x0 (/tmp/clark.exe)
    ->   52.1us END   caml_apply2
    ->   52.1us BEGIN Flags.do_intersect_4857
    -> 52.104us BEGIN caml_apply2
    4589/4589  108652.292099004:                                1 branches:uH:   return                           c659c3 Base.Int.bit_and_2579+0x3 (/tmp/clark.exe) =>           93f8a0 Flags.do_intersect_4857+0x30 (/tmp/clark.exe)
    4589/4589  108652.292099004:                                1 branches:uH:   jmp                              93f8ad Flags.do_intersect_4857+0x3d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099006:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86310 Base.Int63.fun_4896+0x0 (/tmp/clark.exe)
    -> 52.109us END   caml_apply2
    -> 52.109us BEGIN Base.Int.bit_and_2579
    ->  52.11us END   Base.Int.bit_and_2579
    ->  52.11us END   Flags.do_intersect_4857
    ->  52.11us BEGIN caml_apply2
    4589/4589  108652.292099007:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           6d4b48 Async_unix.Epoll_file_descr_watcher.fun_9948+0x38 (/tmp/clark.exe)
    -> 52.111us END   caml_apply2
    -> 52.111us BEGIN Base.Int63.fun_4896
    4589/4589  108652.292099007:                                1 branches:uH:   call                             6d4b6d Async_unix.Epoll_file_descr_watcher.fun_9948+0x5d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099008:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           93f870 Flags.do_intersect_4857+0x0 (/tmp/clark.exe)
    -> 52.112us END   Base.Int63.fun_4896
    -> 52.112us BEGIN caml_apply2
    4589/4589  108652.292099008:                                1 branches:uH:   call                             93f89b Flags.do_intersect_4857+0x2b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099009:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c659c0 Base.Int.bit_and_2579+0x0 (/tmp/clark.exe)
    -> 52.113us END   caml_apply2
    -> 52.113us BEGIN Flags.do_intersect_4857
    -> 52.113us BEGIN caml_apply2
    4589/4589  108652.292099009:                                1 branches:uH:   return                           c659c3 Base.Int.bit_and_2579+0x3 (/tmp/clark.exe) =>           93f8a0 Flags.do_intersect_4857+0x30 (/tmp/clark.exe)
    4589/4589  108652.292099009:                                1 branches:uH:   jmp                              93f8ad Flags.do_intersect_4857+0x3d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099010:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86310 Base.Int63.fun_4896+0x0 (/tmp/clark.exe)
    -> 52.114us END   caml_apply2
    -> 52.114us BEGIN Base.Int.bit_and_2579
    -> 52.114us END   Base.Int.bit_and_2579
    -> 52.114us END   Flags.do_intersect_4857
    -> 52.114us BEGIN caml_apply2
    4589/4589  108652.292099010:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           6d4b72 Async_unix.Epoll_file_descr_watcher.fun_9948+0x62 (/tmp/clark.exe)
    4589/4589  108652.292099010:                                1 branches:uH:   return                           6d4bd0 Async_unix.Epoll_file_descr_watcher.fun_9948+0xc0 (/tmp/clark.exe) =>           7b8ad2 Linux_ext.iter_ready_23395+0x122 (/tmp/clark.exe)
    4589/4589  108652.292099010:                                1 branches:uH:   return                           7b8b01 Linux_ext.iter_ready_23395+0x151 (/tmp/clark.exe) =>           6d54dd Async_unix.Epoll_file_descr_watcher.post_check_9714+0x27d (/tmp/clark.exe)
    4589/4589  108652.292099010:                                1 branches:uH:   call                             6d54fc Async_unix.Epoll_file_descr_watcher.post_check_9714+0x29c (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099013:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           7b89b0 Linux_ext.iter_ready_23395+0x0 (/tmp/clark.exe)
    -> 52.115us END   caml_apply2
    -> 52.115us BEGIN Base.Int63.fun_4896
    -> 52.116us END   Base.Int63.fun_4896
    -> 52.116us END   Async_unix.Epoll_file_descr_watcher.fun_9948
    -> 52.116us END   Linux_ext.iter_ready_23395
    -> 52.116us BEGIN caml_apply2
    4589/4589  108652.292099013:                                1 branches:uH:   call                             7b8a51 Linux_ext.iter_ready_23395+0xa1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099018:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           b191c0 Base_bigstring.unsafe_read_int32_int_4581+0x0 (/tmp/clark.exe)
    -> 52.118us END   caml_apply2
    -> 52.118us BEGIN Linux_ext.iter_ready_23395
    ->  52.12us BEGIN caml_apply2
    4589/4589  108652.292099020:                                1 branches:uH:   return                           b191d6 Base_bigstring.unsafe_read_int32_int_4581+0x16 (/tmp/clark.exe) =>           7b8a56 Linux_ext.iter_ready_23395+0xa6 (/tmp/clark.exe)
    -> 52.123us END   caml_apply2
    -> 52.123us BEGIN Base_bigstring.unsafe_read_int32_int_4581
    4589/4589  108652.292099021:                                1 branches:uH:   call                             7b8a5d Linux_ext.iter_ready_23395+0xad (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 52.125us END   Base_bigstring.unsafe_read_int32_int_4581
    4589/4589  108652.292099021:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           7b8a5f Linux_ext.iter_ready_23395+0xaf (/tmp/clark.exe)
    4589/4589  108652.292099021:                                1 branches:uH:   call                             7b8ab5 Linux_ext.iter_ready_23395+0x105 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099022:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           b191c0 Base_bigstring.unsafe_read_int32_int_4581+0x0 (/tmp/clark.exe)
    -> 52.126us BEGIN Base.Int.of_int_2534
    -> 52.126us END   Base.Int.of_int_2534
    -> 52.126us BEGIN caml_apply2
    4589/4589  108652.292099023:                                1 branches:uH:   return                           b191d6 Base_bigstring.unsafe_read_int32_int_4581+0x16 (/tmp/clark.exe) =>           7b8aba Linux_ext.iter_ready_23395+0x10a (/tmp/clark.exe)
    -> 52.127us END   caml_apply2
    -> 52.127us BEGIN Base_bigstring.unsafe_read_int32_int_4581
    4589/4589  108652.292099023:                                1 branches:uH:   call                             7b8ac1 Linux_ext.iter_ready_23395+0x111 (/tmp/clark.exe) =>           8e8b20 Core_unix.File_descr.fun_6838+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099024:                                1 branches:uH:   return                           8e8b20 Core_unix.File_descr.fun_6838+0x0 (/tmp/clark.exe) =>           7b8ac3 Linux_ext.iter_ready_23395+0x113 (/tmp/clark.exe)
    -> 52.128us END   Base_bigstring.unsafe_read_int32_int_4581
    -> 52.128us BEGIN Core_unix.File_descr.fun_6838
    4589/4589  108652.292099024:                                1 branches:uH:   call                             7b8acd Linux_ext.iter_ready_23395+0x11d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099025:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           6d4b10 Async_unix.Epoll_file_descr_watcher.fun_9948+0x0 (/tmp/clark.exe)
    -> 52.129us END   Core_unix.File_descr.fun_6838
    -> 52.129us BEGIN caml_apply2
    4589/4589  108652.292099025:                                1 branches:uH:   call                             6d4b43 Async_unix.Epoll_file_descr_watcher.fun_9948+0x33 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099025:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           93f870 Flags.do_intersect_4857+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099025:                                1 branches:uH:   call                             93f89b Flags.do_intersect_4857+0x2b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099026:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c659c0 Base.Int.bit_and_2579+0x0 (/tmp/clark.exe)
    ->  52.13us END   caml_apply2
    ->  52.13us BEGIN Async_unix.Epoll_file_descr_watcher.fun_9948
    ->  52.13us BEGIN caml_apply2
    ->  52.13us END   caml_apply2
    ->  52.13us BEGIN Flags.do_intersect_4857
    ->  52.13us BEGIN caml_apply2
    4589/4589  108652.292099027:                                1 branches:uH:   return                           c659c3 Base.Int.bit_and_2579+0x3 (/tmp/clark.exe) =>           93f8a0 Flags.do_intersect_4857+0x30 (/tmp/clark.exe)
    -> 52.131us END   caml_apply2
    -> 52.131us BEGIN Base.Int.bit_and_2579
    4589/4589  108652.292099027:                                1 branches:uH:   jmp                              93f8ad Flags.do_intersect_4857+0x3d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099028:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86310 Base.Int63.fun_4896+0x0 (/tmp/clark.exe)
    -> 52.132us END   Base.Int.bit_and_2579
    -> 52.132us END   Flags.do_intersect_4857
    -> 52.132us BEGIN caml_apply2
    4589/4589  108652.292099028:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           6d4b48 Async_unix.Epoll_file_descr_watcher.fun_9948+0x38 (/tmp/clark.exe)
    4589/4589  108652.292099030:                                1 branches:uH:   jmp                              6d4be9 Async_unix.Epoll_file_descr_watcher.fun_9948+0xd9 (/tmp/clark.exe) =>           6edee0 Async_unix.Raw_scheduler.fun_16762+0x0 (/tmp/clark.exe)
    -> 52.133us END   caml_apply2
    -> 52.133us BEGIN Base.Int63.fun_4896
    -> 52.135us END   Base.Int63.fun_4896
    4589/4589  108652.292099036:                                1 branches:uH:   jmp                              6edf0a Async_unix.Raw_scheduler.fun_16762+0x2a (/tmp/clark.exe) =>           6ec7d0 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x0 (/tmp/clark.exe)
    -> 52.135us END   Async_unix.Epoll_file_descr_watcher.fun_9948
    -> 52.135us BEGIN Async_unix.Raw_scheduler.fun_16762
    4589/4589  108652.292099042:                                1 branches:uH:   call                             6ec805 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x35 (/tmp/clark.exe) =>           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe)
    -> 52.141us END   Async_unix.Raw_scheduler.fun_16762
    -> 52.141us BEGIN Async_unix.Raw_scheduler.post_check_handle_fd_11240
    4589/4589  108652.292099042:                                1 branches:uH:   return                           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe) =>           6ec807 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x37 (/tmp/clark.exe)
    4589/4589  108652.292099042:                                1 branches:uH:   call                             6ec81e Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x4e (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099053:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd960 Core.Int.fun_13979+0x0 (/tmp/clark.exe)
    -> 52.147us BEGIN Core_unix.File_descr.code_begin
    -> 52.152us END   Core_unix.File_descr.code_begin
    -> 52.152us BEGIN caml_apply2
    4589/4589  108652.292099053:                                1 branches:uH:   return                           9dd96f Core.Int.fun_13979+0xf (/tmp/clark.exe) =>           6ec823 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x53 (/tmp/clark.exe)
    4589/4589  108652.292099069:                                1 branches:uH:   call                             6ec850 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x80 (/tmp/clark.exe) =>           c1acc0 Base.Obj_array.length_1479+0x0 (/tmp/clark.exe)
    -> 52.158us END   caml_apply2
    -> 52.158us BEGIN Core.Int.fun_13979
    -> 52.174us END   Core.Int.fun_13979
    4589/4589  108652.292099196:                                1 branches:uH:   return                           c1accc Base.Obj_array.length_1479+0xc (/tmp/clark.exe) =>           6ec852 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x82 (/tmp/clark.exe)
    -> 52.174us BEGIN Base.Obj_array.length_1479
    4589/4589  108652.292099196:                                1 branches:uH:   call                             6ec85e Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x8e (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099199:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 52.301us END   Base.Obj_array.length_1479
    -> 52.301us BEGIN caml_apply2
    4589/4589  108652.292099200:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           6ec863 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x93 (/tmp/clark.exe)
    -> 52.304us END   caml_apply2
    -> 52.304us BEGIN Core.Int.fun_13985
    4589/4589  108652.292099201:                                1 branches:uH:   call                             6ec892 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xc2 (/tmp/clark.exe) =>           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe)
    -> 52.305us END   Core.Int.fun_13985
    4589/4589  108652.292099201:                                1 branches:uH:   return                           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe) =>           6ec894 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xc4 (/tmp/clark.exe)
    4589/4589  108652.292099201:                                1 branches:uH:   call                             6ec8a0 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xd0 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099202:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           cbda20 Base.Option_array.is_some_1894+0x0 (/tmp/clark.exe)
    -> 52.306us BEGIN Core_unix.File_descr.code_begin
    -> 52.306us END   Core_unix.File_descr.code_begin
    -> 52.306us BEGIN caml_apply2
    4589/4589  108652.292099203:                                1 branches:uH:   return                           cbda4c Base.Option_array.is_some_1894+0x2c (/tmp/clark.exe) =>           6ec8a5 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xd5 (/tmp/clark.exe)
    -> 52.307us END   caml_apply2
    -> 52.307us BEGIN Base.Option_array.is_some_1894
    4589/4589  108652.292099203:                                1 branches:uH:   call                             6ec8c2 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xf2 (/tmp/clark.exe) =>           6ddc10 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099211:                                1 branches:uH:   call                             6ddc2f Async_unix.Fd_by_descr.bounds_check_exn_4259+0x1f (/tmp/clark.exe) =>           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe)
    -> 52.308us END   Base.Option_array.is_some_1894
    -> 52.308us BEGIN Async_unix.Fd_by_descr.bounds_check_exn_4259
    4589/4589  108652.292099211:                                1 branches:uH:   return                           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe) =>           6ddc31 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x21 (/tmp/clark.exe)
    4589/4589  108652.292099211:                                1 branches:uH:   call                             6ddc48 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x38 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099212:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd960 Core.Int.fun_13979+0x0 (/tmp/clark.exe)
    -> 52.316us BEGIN Core_unix.File_descr.code_begin
    -> 52.316us END   Core_unix.File_descr.code_begin
    -> 52.316us BEGIN caml_apply2
    4589/4589  108652.292099213:                                1 branches:uH:   return                           9dd96f Core.Int.fun_13979+0xf (/tmp/clark.exe) =>           6ddc4d Async_unix.Fd_by_descr.bounds_check_exn_4259+0x3d (/tmp/clark.exe)
    -> 52.317us END   caml_apply2
    -> 52.317us BEGIN Core.Int.fun_13979
    4589/4589  108652.292099215:                                1 branches:uH:   call                             6ddc76 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x66 (/tmp/clark.exe) =>           c1acc0 Base.Obj_array.length_1479+0x0 (/tmp/clark.exe)
    -> 52.318us END   Core.Int.fun_13979
    4589/4589  108652.292099216:                                1 branches:uH:   return                           c1accc Base.Obj_array.length_1479+0xc (/tmp/clark.exe) =>           6ddc78 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x68 (/tmp/clark.exe)
    ->  52.32us BEGIN Base.Obj_array.length_1479
    4589/4589  108652.292099216:                                1 branches:uH:   call                             6ddc84 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x74 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099217:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 52.321us END   Base.Obj_array.length_1479
    -> 52.321us BEGIN caml_apply2
    4589/4589  108652.292099217:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           6ddc89 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x79 (/tmp/clark.exe)
    4589/4589  108652.292099217:                                1 branches:uH:   return                           6ddc98 Async_unix.Fd_by_descr.bounds_check_exn_4259+0x88 (/tmp/clark.exe) =>           6ec8c7 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0xf7 (/tmp/clark.exe)
    4589/4589  108652.292099219:                                1 branches:uH:   call                             6ec8ec Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x11c (/tmp/clark.exe) =>           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe)
    -> 52.322us END   caml_apply2
    -> 52.322us BEGIN Core.Int.fun_13985
    -> 52.324us END   Core.Int.fun_13985
    -> 52.324us END   Async_unix.Fd_by_descr.bounds_check_exn_4259
    4589/4589  108652.292099219:                                1 branches:uH:   return                           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe) =>           6ec8ee Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x11e (/tmp/clark.exe)
    4589/4589  108652.292099219:                                1 branches:uH:   call                             6ec8fa Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x12a (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099220:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           cbd9e0 Base.Option_array.is_none_1890+0x0 (/tmp/clark.exe)
    -> 52.324us BEGIN Core_unix.File_descr.code_begin
    -> 52.324us END   Core_unix.File_descr.code_begin
    -> 52.324us BEGIN caml_apply2
    4589/4589  108652.292099220:                                1 branches:uH:   return                           cbda0c Base.Option_array.is_none_1890+0x2c (/tmp/clark.exe) =>           6ec8ff Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x12f (/tmp/clark.exe)
    4589/4589  108652.292099223:                                1 branches:uH:   call                             6eca1a Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x24a (/tmp/clark.exe) =>           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe)
    -> 52.325us END   caml_apply2
    -> 52.325us BEGIN Base.Option_array.is_none_1890
    -> 52.328us END   Base.Option_array.is_none_1890
    4589/4589  108652.292099224:                                1 branches:uH:   return                           8e8b00 Core_unix.File_descr.code_begin+0x0 (/tmp/clark.exe) =>           6eca1c Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x24c (/tmp/clark.exe)
    -> 52.328us BEGIN Core_unix.File_descr.code_begin
    4589/4589  108652.292099224:                                1 branches:uH:   call                             6eca28 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x258 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099225:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           cbd960 Base.Option_array.get_some_exn_1886+0x0 (/tmp/clark.exe)
    -> 52.329us END   Core_unix.File_descr.code_begin
    -> 52.329us BEGIN caml_apply2
    4589/4589  108652.292099225:                                1 branches:uH:   return                           cbd9c8 Base.Option_array.get_some_exn_1886+0x68 (/tmp/clark.exe) =>           6eca2d Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x25d (/tmp/clark.exe)
    4589/4589  108652.292099225:                                1 branches:uH:   jmp                              6eca43 Async_unix.Raw_scheduler.post_check_handle_fd_11240+0x273 (/tmp/clark.exe) =>           6ec180 Async_unix.Raw_scheduler.request_stop_watching_11215+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099229:                                1 branches:uH:   call                             6ec210 Async_unix.Raw_scheduler.request_stop_watching_11215+0x90 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    ->  52.33us END   caml_apply2
    ->  52.33us BEGIN Base.Option_array.get_some_exn_1886
    -> 52.332us END   Base.Option_array.get_some_exn_1886
    -> 52.332us END   Async_unix.Raw_scheduler.post_check_handle_fd_11240
    -> 52.332us BEGIN Async_unix.Raw_scheduler.request_stop_watching_11215
    4589/4589  108652.292099231:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           79d9e0 Read_write_pair.get_2289+0x0 (/tmp/clark.exe)
    -> 52.334us BEGIN caml_apply2
    4589/4589  108652.292099234:                                1 branches:uH:   return                           79d9ec Read_write_pair.get_2289+0xc (/tmp/clark.exe) =>           6ec215 Async_unix.Raw_scheduler.request_stop_watching_11215+0x95 (/tmp/clark.exe)
    -> 52.336us END   caml_apply2
    -> 52.336us BEGIN Read_write_pair.get_2289
    4589/4589  108652.292099234:                                1 branches:uH:   jmp                              6ec374 Async_unix.Raw_scheduler.request_stop_watching_11215+0x1f4 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099257:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           800e80 Async_kernel.Scheduler1.enqueue_job_8188+0x0 (/tmp/clark.exe)
    -> 52.339us END   Read_write_pair.get_2289
    -> 52.339us END   Async_unix.Raw_scheduler.request_stop_watching_11215
    -> 52.339us BEGIN caml_apply3
    4589/4589  108652.292099258:                                1 branches:uH:   call                             800eba Async_kernel.Scheduler1.enqueue_job_8188+0x3a (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    -> 52.362us END   caml_apply3
    -> 52.362us BEGIN Async_kernel.Scheduler1.enqueue_job_8188
    4589/4589  108652.292099287:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (/tmp/clark.exe)
    -> 52.363us BEGIN caml_apply3
    4589/4589  108652.292099287:                                1 branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099289:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (/tmp/clark.exe)
    -> 52.392us END   caml_apply3
    -> 52.392us BEGIN Tuple_pool.get_8303
    -> 52.393us END   Tuple_pool.get_8303
    -> 52.393us BEGIN caml_apply2
    4589/4589  108652.292099313:                                1 branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (/tmp/clark.exe) =>           800ebf Async_kernel.Scheduler1.enqueue_job_8188+0x3f (/tmp/clark.exe)
    -> 52.394us END   caml_apply2
    -> 52.394us BEGIN Base.Uniform_array.get_1544
    4589/4589  108652.292099313:                                1 branches:uH:   call                             800ee3 Async_kernel.Scheduler1.enqueue_job_8188+0x63 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099314:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (/tmp/clark.exe)
    -> 52.418us END   Base.Uniform_array.get_1544
    -> 52.418us BEGIN caml_apply3
    4589/4589  108652.292099314:                                1 branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099316:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (/tmp/clark.exe)
    -> 52.419us END   caml_apply3
    -> 52.419us BEGIN Tuple_pool.get_8303
    ->  52.42us END   Tuple_pool.get_8303
    ->  52.42us BEGIN caml_apply2
    4589/4589  108652.292099316:                                1 branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (/tmp/clark.exe) =>           800ee8 Async_kernel.Scheduler1.enqueue_job_8188+0x68 (/tmp/clark.exe)
    4589/4589  108652.292099316:                                1 branches:uH:   call                             800f0c Async_kernel.Scheduler1.enqueue_job_8188+0x8c (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099317:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (/tmp/clark.exe)
    -> 52.421us END   caml_apply2
    -> 52.421us BEGIN Base.Uniform_array.get_1544
    -> 52.421us END   Base.Uniform_array.get_1544
    -> 52.421us BEGIN caml_apply3
    4589/4589  108652.292099317:                                1 branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099318:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (/tmp/clark.exe)
    -> 52.422us END   caml_apply3
    -> 52.422us BEGIN Tuple_pool.get_8303
    -> 52.422us END   Tuple_pool.get_8303
    -> 52.422us BEGIN caml_apply2
    4589/4589  108652.292099319:                                1 branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (/tmp/clark.exe) =>           800f11 Async_kernel.Scheduler1.enqueue_job_8188+0x91 (/tmp/clark.exe)
    -> 52.423us END   caml_apply2
    -> 52.423us BEGIN Base.Uniform_array.get_1544
    4589/4589  108652.292099358:                                1 branches:uH:   call                             800f2f Async_kernel.Scheduler1.enqueue_job_8188+0xaf (/tmp/clark.exe) =>           c12c30 Base.Option.is_none_1121+0x0 (/tmp/clark.exe)
    -> 52.424us END   Base.Uniform_array.get_1544
    4589/4589  108652.292099358:                                1 branches:uH:   return                           c12c41 Base.Option.is_none_1121+0x11 (/tmp/clark.exe) =>           800f31 Async_kernel.Scheduler1.enqueue_job_8188+0xb1 (/tmp/clark.exe)
    4589/4589  108652.292099358:                                1 branches:uH:   call                             800f67 Async_kernel.Scheduler1.enqueue_job_8188+0xe7 (/tmp/clark.exe) =>           7e5760 Async_kernel.Job_queue.enqueue_5173+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099358:                                1 branches:uH:   call                             7e578e Async_kernel.Job_queue.enqueue_5173+0x2e (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099393:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    -> 52.463us BEGIN Base.Option.is_none_1121
    -> 52.474us END   Base.Option.is_none_1121
    -> 52.474us BEGIN Async_kernel.Job_queue.enqueue_5173
    -> 52.486us BEGIN caml_apply2
    4589/4589  108652.292099394:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           7e5793 Async_kernel.Job_queue.enqueue_5173+0x33 (/tmp/clark.exe)
    -> 52.498us END   caml_apply2
    -> 52.498us BEGIN Core.Int.fun_13981
    4589/4589  108652.292099394:                                1 branches:uH:   call                             7e59d3 Async_kernel.Job_queue.enqueue_5173+0x273 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099396:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    -> 52.499us END   Core.Int.fun_13981
    -> 52.499us BEGIN caml_apply3
    4589/4589  108652.292099453:                                1 branches:uH:   return                           c96382 Base.Uniform_array.unsafe_set_1557+0x42 (/tmp/clark.exe) =>           7e59d8 Async_kernel.Job_queue.enqueue_5173+0x278 (/tmp/clark.exe)
    -> 52.501us END   caml_apply3
    -> 52.501us BEGIN Base.Uniform_array.unsafe_set_1557
    4589/4589  108652.292099453:                                1 branches:uH:   call                             7e59fd Async_kernel.Job_queue.enqueue_5173+0x29d (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099455:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    -> 52.558us END   Base.Uniform_array.unsafe_set_1557
    -> 52.558us BEGIN caml_apply3
    4589/4589  108652.292099456:                                1 branches:uH:   call                             c9638c Base.Uniform_array.unsafe_set_1557+0x4c (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    ->  52.56us END   caml_apply3
    ->  52.56us BEGIN Base.Uniform_array.unsafe_set_1557
    4589/4589  108652.292099457:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           c96391 Base.Uniform_array.unsafe_set_1557+0x51 (/tmp/clark.exe)
    -> 52.561us BEGIN caml_modify
    4589/4589  108652.292099459:                                1 branches:uH:   return                           c9639a Base.Uniform_array.unsafe_set_1557+0x5a (/tmp/clark.exe) =>           7e5a02 Async_kernel.Job_queue.enqueue_5173+0x2a2 (/tmp/clark.exe)
    -> 52.562us END   caml_modify
    4589/4589  108652.292099459:                                1 branches:uH:   call                             7e5a27 Async_kernel.Job_queue.enqueue_5173+0x2c7 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099459:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099459:                                1 branches:uH:   return                           c96372 Base.Uniform_array.unsafe_set_1557+0x32 (/tmp/clark.exe) =>           7e5a2c Async_kernel.Job_queue.enqueue_5173+0x2cc (/tmp/clark.exe)
    4589/4589  108652.292099459:                                1 branches:uH:   return                           7e5a46 Async_kernel.Job_queue.enqueue_5173+0x2e6 (/tmp/clark.exe) =>           800f6c Async_kernel.Scheduler1.enqueue_job_8188+0xec (/tmp/clark.exe)
    4589/4589  108652.292099461:                                1 branches:uH:   return                           800fc1 Async_kernel.Scheduler1.enqueue_job_8188+0x141 (/tmp/clark.exe) =>           7b8ad2 Linux_ext.iter_ready_23395+0x122 (/tmp/clark.exe)
    -> 52.564us END   Base.Uniform_array.unsafe_set_1557
    -> 52.564us BEGIN caml_apply3
    -> 52.565us END   caml_apply3
    -> 52.565us BEGIN Base.Uniform_array.unsafe_set_1557
    -> 52.566us END   Base.Uniform_array.unsafe_set_1557
    -> 52.566us END   Async_kernel.Job_queue.enqueue_5173
    4589/4589  108652.292099462:                                1 branches:uH:   return                           7b8b01 Linux_ext.iter_ready_23395+0x151 (/tmp/clark.exe) =>           6d5501 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x2a1 (/tmp/clark.exe)
    -> 52.566us END   Async_kernel.Scheduler1.enqueue_job_8188
    4589/4589  108652.292099463:                                1 branches:uH:   call                             6d5522 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x2c2 (/tmp/clark.exe) =>           7b8b10 Linux_ext.clear_ready_23401+0x0 (/tmp/clark.exe)
    -> 52.567us END   Linux_ext.iter_ready_23395
    4589/4589  108652.292099463:                                1 branches:uH:   return                           7b8b49 Linux_ext.clear_ready_23401+0x39 (/tmp/clark.exe) =>           6d5524 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x2c4 (/tmp/clark.exe)
    4589/4589  108652.292099464:                                1 branches:uH:   return                           6d5530 Async_unix.Epoll_file_descr_watcher.post_check_9714+0x2d0 (/tmp/clark.exe) =>           6f0e0a Async_unix.Raw_scheduler.one_iter_13456+0x13a (/tmp/clark.exe)
    -> 52.568us BEGIN Linux_ext.clear_ready_23401
    -> 52.569us END   Linux_ext.clear_ready_23401
    4589/4589  108652.292099465:                                1 branches:uH:   call                             6f0e68 Async_unix.Raw_scheduler.one_iter_13456+0x198 (/tmp/clark.exe) =>           883e00 Thread_safe_queue.length_2152+0x0 (/tmp/clark.exe)
    -> 52.569us END   Async_unix.Epoll_file_descr_watcher.post_check_9714
    -> 52.569us END   Async_unix.Epoll_file_descr_watcher.post_check_9714
    4589/4589  108652.292099465:                                1 branches:uH:   return                           883e03 Thread_safe_queue.length_2152+0x3 (/tmp/clark.exe) =>           6f0e6a Async_unix.Raw_scheduler.one_iter_13456+0x19a (/tmp/clark.exe)
    4589/4589  108652.292099465:                                1 branches:uH:   call                             6f0e73 Async_unix.Raw_scheduler.one_iter_13456+0x1a3 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099466:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    ->  52.57us BEGIN Thread_safe_queue.length_2152
    ->  52.57us END   Thread_safe_queue.length_2152
    ->  52.57us BEGIN caml_apply2
    4589/4589  108652.292099467:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           6f0e78 Async_unix.Raw_scheduler.one_iter_13456+0x1a8 (/tmp/clark.exe)
    -> 52.571us END   caml_apply2
    -> 52.571us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099468:                                1 branches:uH:   call                             6f0f22 Async_unix.Raw_scheduler.one_iter_13456+0x252 (/tmp/clark.exe) =>           81eb30 Async_kernel.Scheduler.run_cycle_7957+0x0 (/tmp/clark.exe)
    -> 52.572us END   Core.Int.fun_13983
    4589/4589  108652.292099469:                                1 branches:uH:   call                             81ed3d Async_kernel.Scheduler.run_cycle_7957+0x20d (/tmp/clark.exe) =>           ae95f0 Core.Span_ns.since_unix_epoch_9948+0x0 (/tmp/clark.exe)
    -> 52.573us BEGIN Async_kernel.Scheduler.run_cycle_7957
    4589/4589  108652.292099469:                                1 branches:uH:   call                             ae9606 Core.Span_ns.since_unix_epoch_9948+0x16 (/tmp/clark.exe) =>           bcd5b0 Time_now.nanoseconds_since_unix_epoch_1088+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099469:                                1 branches:uH:   call                             bcd5b9 Time_now.nanoseconds_since_unix_epoch_1088+0x9 (/tmp/clark.exe) =>           d4bb03 time_now_nanoseconds_since_unix_epoch_or_zero+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099469:                                1 branches:uH:   call                             d4bb17 time_now_nanoseconds_since_unix_epoch_or_zero+0x14 (/tmp/clark.exe) =>           686ba0 timespec_get@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099470:                                1 branches:uH:   jmp                              686ba0 timespec_get@plt+0x0 (/tmp/clark.exe) =>     7ffff71a8380 timespec_get+0x0 (/usr/lib64/libc-2.17.so)
    -> 52.574us BEGIN Core.Span_ns.since_unix_epoch_9948
    -> 52.574us BEGIN Time_now.nanoseconds_since_unix_epoch_1088
    -> 52.574us BEGIN time_now_nanoseconds_since_unix_epoch_or_zero
    -> 52.574us BEGIN timespec_get@plt
    4589/4589  108652.292099471:                                1 branches:uH:   call                       7ffff71a83b0 timespec_get+0x30 (/usr/lib64/libc-2.17.so) =>     7ffff7ffa600 __vdso_clock_gettime+0x0 ([vdso])
    -> 52.575us END   timespec_get@plt
    -> 52.575us BEGIN timespec_get
    4589/4589  108652.292099473:                                1 branches:uH:   return                     7ffff7ffa665 __vdso_clock_gettime+0x65 ([vdso]) =>     7ffff71a83b2 timespec_get+0x32 (/usr/lib64/libc-2.17.so)
    -> 52.576us BEGIN __vdso_clock_gettime
    4589/4589  108652.292099489:                                1 branches:uH:   return                     7ffff71a83c1 timespec_get+0x41 (/usr/lib64/libc-2.17.so) =>           d4bb1c time_now_nanoseconds_since_unix_epoch_or_zero+0x19 (/tmp/clark.exe)
    -> 52.578us END   __vdso_clock_gettime
    4589/4589  108652.292099489:                                1 branches:uH:   return                           d4bb42 time_now_nanoseconds_since_unix_epoch_or_zero+0x3f (/tmp/clark.exe) =>           bcd5be Time_now.nanoseconds_since_unix_epoch_1088+0xe (/tmp/clark.exe)
    4589/4589  108652.292099489:                                1 branches:uH:   call                             bcd5d7 Time_now.nanoseconds_since_unix_epoch_1088+0x27 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099490:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86310 Base.Int63.fun_4896+0x0 (/tmp/clark.exe)
    -> 52.594us END   timespec_get
    -> 52.594us END   time_now_nanoseconds_since_unix_epoch_or_zero
    -> 52.594us BEGIN caml_apply2
    4589/4589  108652.292099491:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           bcd5dc Time_now.nanoseconds_since_unix_epoch_1088+0x2c (/tmp/clark.exe)
    -> 52.595us END   caml_apply2
    -> 52.595us BEGIN Base.Int63.fun_4896
    4589/4589  108652.292099491:                                1 branches:uH:   return                           bcd5ea Time_now.nanoseconds_since_unix_epoch_1088+0x3a (/tmp/clark.exe) =>           ae9608 Core.Span_ns.since_unix_epoch_9948+0x18 (/tmp/clark.exe)
    4589/4589  108652.292099491:                                1 branches:uH:   return                           ae960c Core.Span_ns.since_unix_epoch_9948+0x1c (/tmp/clark.exe) =>           81ed3f Async_kernel.Scheduler.run_cycle_7957+0x20f (/tmp/clark.exe)
    4589/4589  108652.292099491:                                1 branches:uH:   call                             81edee Async_kernel.Scheduler.run_cycle_7957+0x2be (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099544:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           be4a40 Base.Array0.iter_1696+0x0 (/tmp/clark.exe)
    -> 52.596us END   Base.Int63.fun_4896
    -> 52.596us END   Time_now.nanoseconds_since_unix_epoch_1088
    -> 52.596us END   Core.Span_ns.since_unix_epoch_9948
    -> 52.596us BEGIN caml_apply2
    4589/4589  108652.292099545:                                1 branches:uH:   return                           be4ae1 Base.Array0.iter_1696+0xa1 (/tmp/clark.exe) =>           81edf3 Async_kernel.Scheduler.run_cycle_7957+0x2c3 (/tmp/clark.exe)
    -> 52.649us END   caml_apply2
    -> 52.649us BEGIN Base.Array0.iter_1696
    4589/4589  108652.292099545:                                1 branches:uH:   call                             81ee31 Async_kernel.Scheduler.run_cycle_7957+0x301 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099546:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8b09a0 Timing_wheel.advance_clock_19410+0x0 (/tmp/clark.exe)
    ->  52.65us END   Base.Array0.iter_1696
    ->  52.65us BEGIN caml_apply3
    4589/4589  108652.292099546:                                1 branches:uH:   call                             8b09ca Timing_wheel.advance_clock_19410+0x2a (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099601:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    -> 52.651us END   caml_apply3
    -> 52.651us BEGIN Timing_wheel.advance_clock_19410
    -> 52.678us BEGIN caml_apply2
    4589/4589  108652.292099601:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           8b09cf Timing_wheel.advance_clock_19410+0x2f (/tmp/clark.exe)
    4589/4589  108652.292099614:                                1 branches:uH:   call                             8b0a14 Timing_wheel.advance_clock_19410+0x74 (/tmp/clark.exe) =>           af2020 Core.Time_ns.to_int63_ns_since_epoch_5147+0x0 (/tmp/clark.exe)
    -> 52.706us END   caml_apply2
    -> 52.706us BEGIN Base.Int63.fun_4892
    -> 52.719us END   Base.Int63.fun_4892
    4589/4589  108652.292099615:                                1 branches:uH:   return                           af2020 Core.Time_ns.to_int63_ns_since_epoch_5147+0x0 (/tmp/clark.exe) =>           8b0a16 Timing_wheel.advance_clock_19410+0x76 (/tmp/clark.exe)
    -> 52.719us BEGIN Core.Time_ns.to_int63_ns_since_epoch_5147
    4589/4589  108652.292099615:                                1 branches:uH:   call                             8b0a1f Timing_wheel.advance_clock_19410+0x7f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099615:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65940 Base.Int.shift_right_2560+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099616:                                1 branches:uH:   return                           c6594d Base.Int.shift_right_2560+0xd (/tmp/clark.exe) =>           8b0a24 Timing_wheel.advance_clock_19410+0x84 (/tmp/clark.exe)
    ->  52.72us END   Core.Time_ns.to_int63_ns_since_epoch_5147
    ->  52.72us BEGIN caml_apply2
    ->  52.72us END   caml_apply2
    ->  52.72us BEGIN Base.Int.shift_right_2560
    4589/4589  108652.292099616:                                1 branches:uH:   call                             8b0a54 Timing_wheel.advance_clock_19410+0xb4 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099617:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65960 Base.Int.shift_left_2568+0x0 (/tmp/clark.exe)
    -> 52.721us END   Base.Int.shift_right_2560
    -> 52.721us BEGIN caml_apply2
    4589/4589  108652.292099618:                                1 branches:uH:   return                           c65971 Base.Int.shift_left_2568+0x11 (/tmp/clark.exe) =>           8b0a59 Timing_wheel.advance_clock_19410+0xb9 (/tmp/clark.exe)
    -> 52.722us END   caml_apply2
    -> 52.722us BEGIN Base.Int.shift_left_2568
    4589/4589  108652.292099618:                                1 branches:uH:   call                             8b0a60 Timing_wheel.advance_clock_19410+0xc0 (/tmp/clark.exe) =>           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099619:                                1 branches:uH:   return                           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe) =>           8b0a62 Timing_wheel.advance_clock_19410+0xc2 (/tmp/clark.exe)
    -> 52.723us END   Base.Int.shift_left_2568
    -> 52.723us BEGIN Core.Time_ns.of_int63_ns_since_epoch_5150
    4589/4589  108652.292099619:                                1 branches:uH:   call                             8b0ac2 Timing_wheel.advance_clock_19410+0x122 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099620:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86350 Base.Int63.fun_4888+0x0 (/tmp/clark.exe)
    -> 52.724us END   Core.Time_ns.of_int63_ns_since_epoch_5150
    -> 52.724us BEGIN caml_apply2
    4589/4589  108652.292099620:                                1 branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (/tmp/clark.exe) =>           8b0ac7 Timing_wheel.advance_clock_19410+0x127 (/tmp/clark.exe)
    4589/4589  108652.292099620:                                1 branches:uH:   return                           8b0ec1 Timing_wheel.advance_clock_19410+0x521 (/tmp/clark.exe) =>           81ee36 Async_kernel.Scheduler.run_cycle_7957+0x306 (/tmp/clark.exe)
    4589/4589  108652.292099620:                                1 branches:uH:   call                             81ee40 Async_kernel.Scheduler.run_cycle_7957+0x310 (/tmp/clark.exe) =>           7f0620 Async_kernel.Synchronous_time_source0.run_fired_events_9079+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099623:                                1 branches:uH:   return                           7f0a2b Async_kernel.Synchronous_time_source0.run_fired_events_9079+0x40b (/tmp/clark.exe) =>           81ee45 Async_kernel.Scheduler.run_cycle_7957+0x315 (/tmp/clark.exe)
    -> 52.725us END   caml_apply2
    -> 52.725us BEGIN Base.Int63.fun_4888
    -> 52.726us END   Base.Int63.fun_4888
    -> 52.726us END   Timing_wheel.advance_clock_19410
    -> 52.726us BEGIN Async_kernel.Synchronous_time_source0.run_fired_events_9079
    4589/4589  108652.292099623:                                1 branches:uH:   call                             81ee60 Async_kernel.Scheduler.run_cycle_7957+0x330 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099623:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           8b3560 Timing_wheel.fire_past_alarms_19511+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099624:                                1 branches:uH:   call                             8b35e0 Timing_wheel.fire_past_alarms_19511+0x80 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 52.728us END   Async_kernel.Synchronous_time_source0.run_fired_events_9079
    -> 52.728us BEGIN caml_apply2
    -> 52.728us END   caml_apply2
    -> 52.728us BEGIN Timing_wheel.fire_past_alarms_19511
    4589/4589  108652.292099625:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.729us BEGIN caml_apply2
    4589/4589  108652.292099625:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           8b35e5 Timing_wheel.fire_past_alarms_19511+0x85 (/tmp/clark.exe)
    4589/4589  108652.292099625:                                1 branches:uH:   call                             8b3636 Timing_wheel.fire_past_alarms_19511+0xd6 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099627:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65940 Base.Int.shift_right_2560+0x0 (/tmp/clark.exe)
    ->  52.73us END   caml_apply2
    ->  52.73us BEGIN Core.Int.fun_13983
    -> 52.731us END   Core.Int.fun_13983
    -> 52.731us BEGIN caml_apply2
    4589/4589  108652.292099627:                                1 branches:uH:   return                           c6594d Base.Int.shift_right_2560+0xd (/tmp/clark.exe) =>           8b363b Timing_wheel.fire_past_alarms_19511+0xdb (/tmp/clark.exe)
    4589/4589  108652.292099627:                                1 branches:uH:   call                             8b3645 Timing_wheel.fire_past_alarms_19511+0xe5 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099628:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c659c0 Base.Int.bit_and_2579+0x0 (/tmp/clark.exe)
    -> 52.732us END   caml_apply2
    -> 52.732us BEGIN Base.Int.shift_right_2560
    -> 52.732us END   Base.Int.shift_right_2560
    -> 52.732us BEGIN caml_apply2
    4589/4589  108652.292099628:                                1 branches:uH:   return                           c659c3 Base.Int.bit_and_2579+0x3 (/tmp/clark.exe) =>           8b364a Timing_wheel.fire_past_alarms_19511+0xea (/tmp/clark.exe)
    4589/4589  108652.292099629:                                1 branches:uH:   call                             8b3652 Timing_wheel.fire_past_alarms_19511+0xf2 (/tmp/clark.exe) =>           c65890 Base.Int.to_int_2530+0x0 (/tmp/clark.exe)
    -> 52.733us END   caml_apply2
    -> 52.733us BEGIN Base.Int.bit_and_2579
    -> 52.734us END   Base.Int.bit_and_2579
    4589/4589  108652.292099629:                                1 branches:uH:   return                           c65890 Base.Int.to_int_2530+0x0 (/tmp/clark.exe) =>           8b3654 Timing_wheel.fire_past_alarms_19511+0xf4 (/tmp/clark.exe)
    4589/4589  108652.292099630:                                1 branches:uH:   call                             8b36a0 Timing_wheel.fire_past_alarms_19511+0x140 (/tmp/clark.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (/tmp/clark.exe)
    -> 52.734us BEGIN Base.Int.to_int_2530
    -> 52.735us END   Base.Int.to_int_2530
    4589/4589  108652.292099630:                                1 branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (/tmp/clark.exe) =>           8b36a2 Timing_wheel.fire_past_alarms_19511+0x142 (/tmp/clark.exe)
    4589/4589  108652.292099630:                                1 branches:uH:   return                           8b36bd Timing_wheel.fire_past_alarms_19511+0x15d (/tmp/clark.exe) =>           81ee65 Async_kernel.Scheduler.run_cycle_7957+0x335 (/tmp/clark.exe)
    4589/4589  108652.292099630:                                1 branches:uH:   call                             81ee6f Async_kernel.Scheduler.run_cycle_7957+0x33f (/tmp/clark.exe) =>           7f0620 Async_kernel.Synchronous_time_source0.run_fired_events_9079+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099630:                                1 branches:uH:   return                           7f0a2b Async_kernel.Synchronous_time_source0.run_fired_events_9079+0x40b (/tmp/clark.exe) =>           81ee74 Async_kernel.Scheduler.run_cycle_7957+0x344 (/tmp/clark.exe)
    4589/4589  108652.292099630:                                1 branches:uH:   call                             81ee80 Async_kernel.Scheduler.run_cycle_7957+0x350 (/tmp/clark.exe) =>           802130 Async_kernel.Scheduler1.start_cycle_9229+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099644:                                1 branches:uH:   call                             80214d Async_kernel.Scheduler1.start_cycle_9229+0x1d (/tmp/clark.exe) =>           aa51f0 Core.Validated.raw_4464+0x0 (/tmp/clark.exe)
    -> 52.735us BEGIN Tuple_pool.is_null_4272
    -> 52.739us END   Tuple_pool.is_null_4272
    -> 52.739us END   Timing_wheel.fire_past_alarms_19511
    -> 52.739us BEGIN Async_kernel.Synchronous_time_source0.run_fired_events_9079
    -> 52.744us END   Async_kernel.Synchronous_time_source0.run_fired_events_9079
    -> 52.744us BEGIN Async_kernel.Scheduler1.start_cycle_9229
    4589/4589  108652.292099657:                                1 branches:uH:   return                           aa51f0 Core.Validated.raw_4464+0x0 (/tmp/clark.exe) =>           80214f Async_kernel.Scheduler1.start_cycle_9229+0x1f (/tmp/clark.exe)
    -> 52.749us BEGIN Core.Validated.raw_4464
    4589/4589  108652.292099657:                                1 branches:uH:   call                             802171 Async_kernel.Scheduler1.start_cycle_9229+0x41 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099666:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 52.762us END   Core.Validated.raw_4464
    -> 52.762us BEGIN caml_apply2
    4589/4589  108652.292099667:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           802176 Async_kernel.Scheduler1.start_cycle_9229+0x46 (/tmp/clark.exe)
    -> 52.771us END   caml_apply2
    -> 52.771us BEGIN Core.Int.fun_13985
    4589/4589  108652.292099667:                                1 branches:uH:   call                             802313 Async_kernel.Scheduler1.start_cycle_9229+0x1e3 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099668:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd930 Core.Int.fun_13985+0x0 (/tmp/clark.exe)
    -> 52.772us END   Core.Int.fun_13985
    -> 52.772us BEGIN caml_apply2
    4589/4589  108652.292099669:                                1 branches:uH:   return                           9dd93f Core.Int.fun_13985+0xf (/tmp/clark.exe) =>           802318 Async_kernel.Scheduler1.start_cycle_9229+0x1e8 (/tmp/clark.exe)
    -> 52.773us END   caml_apply2
    -> 52.773us BEGIN Core.Int.fun_13985
    4589/4589  108652.292099669:                                1 branches:uH:   return                           80249c Async_kernel.Scheduler1.start_cycle_9229+0x36c (/tmp/clark.exe) =>           81ee85 Async_kernel.Scheduler.run_cycle_7957+0x355 (/tmp/clark.exe)
    4589/4589  108652.292099669:                                1 branches:uH:   call                             81ee8e Async_kernel.Scheduler.run_cycle_7957+0x35e (/tmp/clark.exe) =>           7e5db0 Async_kernel.Job_queue.run_jobs_5243+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099675:                                1 branches:uH:   call                             7e5e09 Async_kernel.Job_queue.run_jobs_5243+0x59 (/tmp/clark.exe) =>           883e00 Thread_safe_queue.length_2152+0x0 (/tmp/clark.exe)
    -> 52.774us END   Core.Int.fun_13985
    -> 52.774us END   Async_kernel.Scheduler1.start_cycle_9229
    -> 52.774us BEGIN Async_kernel.Job_queue.run_jobs_5243
    4589/4589  108652.292099679:                                1 branches:uH:   return                           883e03 Thread_safe_queue.length_2152+0x3 (/tmp/clark.exe) =>           7e5e0b Async_kernel.Job_queue.run_jobs_5243+0x5b (/tmp/clark.exe)
    ->  52.78us BEGIN Thread_safe_queue.length_2152
    4589/4589  108652.292099679:                                1 branches:uH:   call                             7e5e15 Async_kernel.Job_queue.run_jobs_5243+0x65 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099679:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099680:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5e1a Async_kernel.Job_queue.run_jobs_5243+0x6a (/tmp/clark.exe)
    -> 52.784us END   Thread_safe_queue.length_2152
    -> 52.784us BEGIN caml_apply2
    -> 52.784us END   caml_apply2
    -> 52.784us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099680:                                1 branches:uH:   call                             7e5e91 Async_kernel.Job_queue.run_jobs_5243+0xe1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099681:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.785us END   Core.Int.fun_13983
    -> 52.785us BEGIN caml_apply2
    4589/4589  108652.292099682:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5e96 Async_kernel.Job_queue.run_jobs_5243+0xe6 (/tmp/clark.exe)
    -> 52.786us END   caml_apply2
    -> 52.786us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099682:                                1 branches:uH:   call                             7e5eb9 Async_kernel.Job_queue.run_jobs_5243+0x109 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099683:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.787us END   Core.Int.fun_13983
    -> 52.787us BEGIN caml_apply2
    4589/4589  108652.292099684:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5ebe Async_kernel.Job_queue.run_jobs_5243+0x10e (/tmp/clark.exe)
    -> 52.788us END   caml_apply2
    -> 52.788us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099684:                                1 branches:uH:   call                             7e5ef7 Async_kernel.Job_queue.run_jobs_5243+0x147 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099687:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c96330 Base.Uniform_array.unsafe_get_1553+0x0 (/tmp/clark.exe)
    -> 52.789us END   Core.Int.fun_13983
    -> 52.789us BEGIN caml_apply2
    4589/4589  108652.292099688:                                1 branches:uH:   return                           c9633b Base.Uniform_array.unsafe_get_1553+0xb (/tmp/clark.exe) =>           7e5efc Async_kernel.Job_queue.run_jobs_5243+0x14c (/tmp/clark.exe)
    -> 52.792us END   caml_apply2
    -> 52.792us BEGIN Base.Uniform_array.unsafe_get_1553
    4589/4589  108652.292099688:                                1 branches:uH:   call                             7e5f21 Async_kernel.Job_queue.run_jobs_5243+0x171 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099689:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c96330 Base.Uniform_array.unsafe_get_1553+0x0 (/tmp/clark.exe)
    -> 52.793us END   Base.Uniform_array.unsafe_get_1553
    -> 52.793us BEGIN caml_apply2
    4589/4589  108652.292099690:                                1 branches:uH:   return                           c9633b Base.Uniform_array.unsafe_get_1553+0xb (/tmp/clark.exe) =>           7e5f26 Async_kernel.Job_queue.run_jobs_5243+0x176 (/tmp/clark.exe)
    -> 52.794us END   caml_apply2
    -> 52.794us BEGIN Base.Uniform_array.unsafe_get_1553
    4589/4589  108652.292099690:                                1 branches:uH:   call                             7e5f4b Async_kernel.Job_queue.run_jobs_5243+0x19b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099692:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c96330 Base.Uniform_array.unsafe_get_1553+0x0 (/tmp/clark.exe)
    -> 52.795us END   Base.Uniform_array.unsafe_get_1553
    -> 52.795us BEGIN caml_apply2
    4589/4589  108652.292099693:                                1 branches:uH:   return                           c9633b Base.Uniform_array.unsafe_get_1553+0xb (/tmp/clark.exe) =>           7e5f50 Async_kernel.Job_queue.run_jobs_5243+0x1a0 (/tmp/clark.exe)
    -> 52.797us END   caml_apply2
    -> 52.797us BEGIN Base.Uniform_array.unsafe_get_1553
    4589/4589  108652.292099693:                                1 branches:uH:   call                             7e5f98 Async_kernel.Job_queue.run_jobs_5243+0x1e8 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099703:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    -> 52.798us END   Base.Uniform_array.unsafe_get_1553
    -> 52.798us BEGIN caml_apply3
    4589/4589  108652.292099704:                                1 branches:uH:   return                           c96382 Base.Uniform_array.unsafe_set_1557+0x42 (/tmp/clark.exe) =>           7e5f9d Async_kernel.Job_queue.run_jobs_5243+0x1ed (/tmp/clark.exe)
    -> 52.808us END   caml_apply3
    -> 52.808us BEGIN Base.Uniform_array.unsafe_set_1557
    4589/4589  108652.292099704:                                1 branches:uH:   call                             7e5fc2 Async_kernel.Job_queue.run_jobs_5243+0x212 (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099705:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    -> 52.809us END   Base.Uniform_array.unsafe_set_1557
    -> 52.809us BEGIN caml_apply3
    4589/4589  108652.292099706:                                1 branches:uH:   call                             c9638c Base.Uniform_array.unsafe_set_1557+0x4c (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    ->  52.81us END   caml_apply3
    ->  52.81us BEGIN Base.Uniform_array.unsafe_set_1557
    4589/4589  108652.292099707:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           c96391 Base.Uniform_array.unsafe_set_1557+0x51 (/tmp/clark.exe)
    -> 52.811us BEGIN caml_modify
    4589/4589  108652.292099709:                                1 branches:uH:   return                           c9639a Base.Uniform_array.unsafe_set_1557+0x5a (/tmp/clark.exe) =>           7e5fc7 Async_kernel.Job_queue.run_jobs_5243+0x217 (/tmp/clark.exe)
    -> 52.812us END   caml_modify
    4589/4589  108652.292099709:                                1 branches:uH:   call                             7e5fec Async_kernel.Job_queue.run_jobs_5243+0x23c (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099709:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           c96340 Base.Uniform_array.unsafe_set_1557+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099709:                                1 branches:uH:   return                           c96372 Base.Uniform_array.unsafe_set_1557+0x32 (/tmp/clark.exe) =>           7e5ff1 Async_kernel.Job_queue.run_jobs_5243+0x241 (/tmp/clark.exe)
    4589/4589  108652.292099719:                                1 branches:uH:   call                             7e603c Async_kernel.Job_queue.run_jobs_5243+0x28c (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    -> 52.814us END   Base.Uniform_array.unsafe_set_1557
    -> 52.814us BEGIN caml_apply3
    -> 52.819us END   caml_apply3
    -> 52.819us BEGIN Base.Uniform_array.unsafe_set_1557
    -> 52.824us END   Base.Uniform_array.unsafe_set_1557
    4589/4589  108652.292099719:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           7e6041 Async_kernel.Job_queue.run_jobs_5243+0x291 (/tmp/clark.exe)
    4589/4589  108652.292099730:                                1 branches:uH:   call                             7e604e Async_kernel.Job_queue.run_jobs_5243+0x29e (/tmp/clark.exe) =>           6efba0 Async_unix.Raw_scheduler.fun_16931+0x0 (/tmp/clark.exe)
    -> 52.824us BEGIN caml_modify
    -> 52.835us END   caml_modify
    4589/4589  108652.292099731:                                1 branches:uH:   return                           6efba5 Async_unix.Raw_scheduler.fun_16931+0x5 (/tmp/clark.exe) =>           7e6050 Async_kernel.Job_queue.run_jobs_5243+0x2a0 (/tmp/clark.exe)
    -> 52.835us BEGIN Async_unix.Raw_scheduler.fun_16931
    4589/4589  108652.292099731:                                1 branches:uH:   call                             7e6084 Async_kernel.Job_queue.run_jobs_5243+0x2d4 (/tmp/clark.exe) =>           883e00 Thread_safe_queue.length_2152+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099732:                                1 branches:uH:   return                           883e03 Thread_safe_queue.length_2152+0x3 (/tmp/clark.exe) =>           7e6086 Async_kernel.Job_queue.run_jobs_5243+0x2d6 (/tmp/clark.exe)
    -> 52.836us END   Async_unix.Raw_scheduler.fun_16931
    -> 52.836us BEGIN Thread_safe_queue.length_2152
    4589/4589  108652.292099732:                                1 branches:uH:   call                             7e6090 Async_kernel.Job_queue.run_jobs_5243+0x2e0 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099733:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.837us END   Thread_safe_queue.length_2152
    -> 52.837us BEGIN caml_apply2
    4589/4589  108652.292099733:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e6095 Async_kernel.Job_queue.run_jobs_5243+0x2e5 (/tmp/clark.exe)
    4589/4589  108652.292099733:                                1 branches:uH:   call                             7e5e91 Async_kernel.Job_queue.run_jobs_5243+0xe1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099734:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.838us END   caml_apply2
    -> 52.838us BEGIN Core.Int.fun_13983
    -> 52.838us END   Core.Int.fun_13983
    -> 52.838us BEGIN caml_apply2
    4589/4589  108652.292099735:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5e96 Async_kernel.Job_queue.run_jobs_5243+0xe6 (/tmp/clark.exe)
    -> 52.839us END   caml_apply2
    -> 52.839us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099735:                                1 branches:uH:   return                           7e6113 Async_kernel.Job_queue.run_jobs_5243+0x363 (/tmp/clark.exe) =>           81ee93 Async_kernel.Scheduler.run_cycle_7957+0x363 (/tmp/clark.exe)
    4589/4589  108652.292099735:                                1 branches:uH:   call                             81eeb1 Async_kernel.Scheduler.run_cycle_7957+0x381 (/tmp/clark.exe) =>           7e5db0 Async_kernel.Job_queue.run_jobs_5243+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099738:                                1 branches:uH:   call                             7e5e09 Async_kernel.Job_queue.run_jobs_5243+0x59 (/tmp/clark.exe) =>           883e00 Thread_safe_queue.length_2152+0x0 (/tmp/clark.exe)
    ->  52.84us END   Core.Int.fun_13983
    ->  52.84us END   Async_kernel.Job_queue.run_jobs_5243
    ->  52.84us END   Async_kernel.Job_queue.run_jobs_5243
    ->  52.84us BEGIN Async_kernel.Job_queue.run_jobs_5243
    4589/4589  108652.292099738:                                1 branches:uH:   return                           883e03 Thread_safe_queue.length_2152+0x3 (/tmp/clark.exe) =>           7e5e0b Async_kernel.Job_queue.run_jobs_5243+0x5b (/tmp/clark.exe)
    4589/4589  108652.292099738:                                1 branches:uH:   call                             7e5e15 Async_kernel.Job_queue.run_jobs_5243+0x65 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099739:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.843us BEGIN Thread_safe_queue.length_2152
    -> 52.843us END   Thread_safe_queue.length_2152
    -> 52.843us BEGIN caml_apply2
    4589/4589  108652.292099739:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5e1a Async_kernel.Job_queue.run_jobs_5243+0x6a (/tmp/clark.exe)
    4589/4589  108652.292099739:                                1 branches:uH:   call                             7e5e91 Async_kernel.Job_queue.run_jobs_5243+0xe1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099740:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.844us END   caml_apply2
    -> 52.844us BEGIN Core.Int.fun_13983
    -> 52.844us END   Core.Int.fun_13983
    -> 52.844us BEGIN caml_apply2
    4589/4589  108652.292099740:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           7e5e96 Async_kernel.Job_queue.run_jobs_5243+0xe6 (/tmp/clark.exe)
    4589/4589  108652.292099740:                                1 branches:uH:   return                           7e6113 Async_kernel.Job_queue.run_jobs_5243+0x363 (/tmp/clark.exe) =>           81eeb6 Async_kernel.Scheduler.run_cycle_7957+0x386 (/tmp/clark.exe)
    4589/4589  108652.292099740:                                1 branches:uH:   call                             81eee9 Async_kernel.Scheduler.run_cycle_7957+0x3b9 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099742:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.845us END   caml_apply2
    -> 52.845us BEGIN Core.Int.fun_13983
    -> 52.846us END   Core.Int.fun_13983
    -> 52.846us END   Async_kernel.Job_queue.run_jobs_5243
    -> 52.846us END   Async_kernel.Job_queue.run_jobs_5243
    -> 52.846us BEGIN caml_apply2
    4589/4589  108652.292099743:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           81eeee Async_kernel.Scheduler.run_cycle_7957+0x3be (/tmp/clark.exe)
    -> 52.847us END   caml_apply2
    -> 52.847us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099743:                                1 branches:uH:   call                             81ef38 Async_kernel.Scheduler.run_cycle_7957+0x408 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099744:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 52.848us END   Core.Int.fun_13983
    -> 52.848us BEGIN caml_apply2
    4589/4589  108652.292099745:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           81ef3d Async_kernel.Scheduler.run_cycle_7957+0x40d (/tmp/clark.exe)
    -> 52.849us END   caml_apply2
    -> 52.849us BEGIN Core.Int.fun_13983
    4589/4589  108652.292099759:                                1 branches:uH:   call                             81f0cf Async_kernel.Scheduler.run_cycle_7957+0x59f (/tmp/clark.exe) =>           ae95f0 Core.Span_ns.since_unix_epoch_9948+0x0 (/tmp/clark.exe)
    ->  52.85us END   Core.Int.fun_13983
    4589/4589  108652.292099762:                                1 branches:uH:   call                             ae9606 Core.Span_ns.since_unix_epoch_9948+0x16 (/tmp/clark.exe) =>           bcd5b0 Time_now.nanoseconds_since_unix_epoch_1088+0x0 (/tmp/clark.exe)
    -> 52.864us BEGIN Core.Span_ns.since_unix_epoch_9948
    4589/4589  108652.292099762:                                1 branches:uH:   call                             bcd5b9 Time_now.nanoseconds_since_unix_epoch_1088+0x9 (/tmp/clark.exe) =>           d4bb03 time_now_nanoseconds_since_unix_epoch_or_zero+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099762:                                1 branches:uH:   call                             d4bb17 time_now_nanoseconds_since_unix_epoch_or_zero+0x14 (/tmp/clark.exe) =>           686ba0 timespec_get@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099763:                                1 branches:uH:   jmp                              686ba0 timespec_get@plt+0x0 (/tmp/clark.exe) =>     7ffff71a8380 timespec_get+0x0 (/usr/lib64/libc-2.17.so)
    -> 52.867us BEGIN Time_now.nanoseconds_since_unix_epoch_1088
    -> 52.867us BEGIN time_now_nanoseconds_since_unix_epoch_or_zero
    -> 52.867us BEGIN timespec_get@plt
    4589/4589  108652.292099765:                                1 branches:uH:   call                       7ffff71a83b0 timespec_get+0x30 (/usr/lib64/libc-2.17.so) =>     7ffff7ffa600 __vdso_clock_gettime+0x0 ([vdso])
    -> 52.868us END   timespec_get@plt
    -> 52.868us BEGIN timespec_get
    4589/4589  108652.292099779:                                1 branches:uH:   return                     7ffff7ffa665 __vdso_clock_gettime+0x65 ([vdso]) =>     7ffff71a83b2 timespec_get+0x32 (/usr/lib64/libc-2.17.so)
    ->  52.87us BEGIN __vdso_clock_gettime
    4589/4589  108652.292099779:                                1 branches:uH:   return                     7ffff71a83c1 timespec_get+0x41 (/usr/lib64/libc-2.17.so) =>           d4bb1c time_now_nanoseconds_since_unix_epoch_or_zero+0x19 (/tmp/clark.exe)
    4589/4589  108652.292099782:                                1 branches:uH:   return                           d4bb42 time_now_nanoseconds_since_unix_epoch_or_zero+0x3f (/tmp/clark.exe) =>           bcd5be Time_now.nanoseconds_since_unix_epoch_1088+0xe (/tmp/clark.exe)
    -> 52.884us END   __vdso_clock_gettime
    -> 52.884us END   timespec_get
    4589/4589  108652.292099782:                                1 branches:uH:   call                             bcd5d7 Time_now.nanoseconds_since_unix_epoch_1088+0x27 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099783:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86310 Base.Int63.fun_4896+0x0 (/tmp/clark.exe)
    -> 52.887us END   time_now_nanoseconds_since_unix_epoch_or_zero
    -> 52.887us BEGIN caml_apply2
    4589/4589  108652.292099783:                                1 branches:uH:   return                           c8631f Base.Int63.fun_4896+0xf (/tmp/clark.exe) =>           bcd5dc Time_now.nanoseconds_since_unix_epoch_1088+0x2c (/tmp/clark.exe)
    4589/4589  108652.292099783:                                1 branches:uH:   return                           bcd5ea Time_now.nanoseconds_since_unix_epoch_1088+0x3a (/tmp/clark.exe) =>           ae9608 Core.Span_ns.since_unix_epoch_9948+0x18 (/tmp/clark.exe)
    4589/4589  108652.292099783:                                1 branches:uH:   return                           ae960c Core.Span_ns.since_unix_epoch_9948+0x1c (/tmp/clark.exe) =>           81f0d1 Async_kernel.Scheduler.run_cycle_7957+0x5a1 (/tmp/clark.exe)
    4589/4589  108652.292099783:                                1 branches:uH:   call                             81f0da Async_kernel.Scheduler.run_cycle_7957+0x5aa (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099785:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           ae5b40 Core.Span_ns.-_6237+0x0 (/tmp/clark.exe)
    -> 52.888us END   caml_apply2
    -> 52.888us BEGIN Base.Int63.fun_4896
    -> 52.889us END   Base.Int63.fun_4896
    -> 52.889us END   Time_now.nanoseconds_since_unix_epoch_1088
    -> 52.889us END   Core.Span_ns.since_unix_epoch_9948
    -> 52.889us BEGIN caml_apply2
    4589/4589  108652.292099785:                                1 branches:uH:   jmp                              ae5b5b Core.Span_ns.-_6237+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099786:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c862f0 Base.Int63.fun_4900+0x0 (/tmp/clark.exe)
    ->  52.89us END   caml_apply2
    ->  52.89us BEGIN Core.Span_ns.-_6237
    ->  52.89us END   Core.Span_ns.-_6237
    ->  52.89us BEGIN caml_apply2
    4589/4589  108652.292099786:                                1 branches:uH:   return                           c862f7 Base.Int63.fun_4900+0x7 (/tmp/clark.exe) =>           81f0df Async_kernel.Scheduler.run_cycle_7957+0x5af (/tmp/clark.exe)
    4589/4589  108652.292099786:                                1 branches:uH:   call                             81f123 Async_kernel.Scheduler.run_cycle_7957+0x5f3 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099809:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           ae5b10 Core.Span_ns.+_6234+0x0 (/tmp/clark.exe)
    -> 52.891us END   caml_apply2
    -> 52.891us BEGIN Base.Int63.fun_4900
    -> 52.902us END   Base.Int63.fun_4900
    -> 52.902us BEGIN caml_apply2
    4589/4589  108652.292099809:                                1 branches:uH:   jmp                              ae5b2b Core.Span_ns.+_6234+0x1b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099810:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86300 Base.Int63.fun_4898+0x0 (/tmp/clark.exe)
    -> 52.914us END   caml_apply2
    -> 52.914us BEGIN Core.Span_ns.+_6234
    -> 52.914us END   Core.Span_ns.+_6234
    -> 52.914us BEGIN caml_apply2
    4589/4589  108652.292099810:                                1 branches:uH:   return                           c86305 Base.Int63.fun_4898+0x5 (/tmp/clark.exe) =>           81f128 Async_kernel.Scheduler.run_cycle_7957+0x5f8 (/tmp/clark.exe)
    4589/4589  108652.292099810:                                1 branches:uH:   call                             81f1f1 Async_kernel.Scheduler.run_cycle_7957+0x6c1 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099811:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           be4a40 Base.Array0.iter_1696+0x0 (/tmp/clark.exe)
    -> 52.915us END   caml_apply2
    -> 52.915us BEGIN Base.Int63.fun_4898
    -> 52.915us END   Base.Int63.fun_4898
    -> 52.915us BEGIN caml_apply2
    4589/4589  108652.292099812:                                1 branches:uH:   return                           be4ae1 Base.Array0.iter_1696+0xa1 (/tmp/clark.exe) =>           81f1f6 Async_kernel.Scheduler.run_cycle_7957+0x6c6 (/tmp/clark.exe)
    -> 52.916us END   caml_apply2
    -> 52.916us BEGIN Base.Array0.iter_1696
    4589/4589  108652.292099812:                                1 branches:uH:   return                           81f485 Async_kernel.Scheduler.run_cycle_7957+0x955 (/tmp/clark.exe) =>           6f0f24 Async_unix.Raw_scheduler.one_iter_13456+0x254 (/tmp/clark.exe)
    4589/4589  108652.292099814:                                1 branches:uH:   call                             6f0f61 Async_unix.Raw_scheduler.one_iter_13456+0x291 (/tmp/clark.exe) =>           ae5020 Core.Span_ns.of_int_us_6033+0x0 (/tmp/clark.exe)
    -> 52.917us END   Base.Array0.iter_1696
    -> 52.917us END   Async_kernel.Scheduler.run_cycle_7957
    4589/4589  108652.292099815:                                1 branches:uH:   call                             ae5058 Core.Span_ns.of_int_us_6033+0x38 (/tmp/clark.exe) =>           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe)
    -> 52.919us BEGIN Core.Span_ns.of_int_us_6033
    4589/4589  108652.292099815:                                1 branches:uH:   return                           c658a0 Base.Int.of_int_2534+0x0 (/tmp/clark.exe) =>           ae505a Core.Span_ns.of_int_us_6033+0x3a (/tmp/clark.exe)
    4589/4589  108652.292099815:                                1 branches:uH:   jmp                              ae5067 Core.Span_ns.of_int_us_6033+0x47 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099816:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c862e0 Base.Int63.fun_4902+0x0 (/tmp/clark.exe)
    ->  52.92us BEGIN Base.Int.of_int_2534
    ->  52.92us END   Base.Int.of_int_2534
    ->  52.92us END   Core.Span_ns.of_int_us_6033
    ->  52.92us BEGIN caml_apply2
    4589/4589  108652.292099817:                                1 branches:uH:   return                           c862ef Base.Int63.fun_4902+0xf (/tmp/clark.exe) =>           6f0f63 Async_unix.Raw_scheduler.one_iter_13456+0x293 (/tmp/clark.exe)
    -> 52.921us END   caml_apply2
    -> 52.921us BEGIN Base.Int63.fun_4902
    4589/4589  108652.292099817:                                1 branches:uH:   call                             6f0f6f Async_unix.Raw_scheduler.one_iter_13456+0x29f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099818:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    -> 52.922us END   Base.Int63.fun_4902
    -> 52.922us BEGIN caml_apply2
    4589/4589  108652.292099818:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           6f0f74 Async_unix.Raw_scheduler.one_iter_13456+0x2a4 (/tmp/clark.exe)
    4589/4589  108652.292099819:                                1 branches:uH:   call                             6f0fcb Async_unix.Raw_scheduler.one_iter_13456+0x2fb (/tmp/clark.exe) =>           b02db0 Thread.fun_715+0x0 (/tmp/clark.exe)
    -> 52.923us END   caml_apply2
    -> 52.923us BEGIN Base.Int63.fun_4892
    -> 52.924us END   Base.Int63.fun_4892
    4589/4589  108652.292099819:                                1 branches:uH:   call                             b02db7 Thread.fun_715+0x7 (/tmp/clark.exe) =>           d44690 caml_thread_self+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099851:                                1 branches:uH:   return                           d4469f caml_thread_self+0xf (/tmp/clark.exe) =>           b02dbc Thread.fun_715+0xc (/tmp/clark.exe)
    -> 52.924us BEGIN Thread.fun_715
    ->  52.94us BEGIN caml_thread_self
    4589/4589  108652.292099851:                                1 branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (/tmp/clark.exe) =>           6f0fcd Async_unix.Raw_scheduler.one_iter_13456+0x2fd (/tmp/clark.exe)
    4589/4589  108652.292099855:                                1 branches:uH:   call                             6f0fd4 Async_unix.Raw_scheduler.one_iter_13456+0x304 (/tmp/clark.exe) =>           b02d90 Thread.fun_713+0x0 (/tmp/clark.exe)
    -> 52.956us END   caml_thread_self
    -> 52.956us END   Thread.fun_715
    4589/4589  108652.292099855:                                1 branches:uH:   call                             b02d97 Thread.fun_713+0x7 (/tmp/clark.exe) =>           d446b0 caml_thread_id+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099856:                                1 branches:uH:   return                           d446b3 caml_thread_id+0x3 (/tmp/clark.exe) =>           b02d9c Thread.fun_713+0xc (/tmp/clark.exe)
    ->  52.96us BEGIN Thread.fun_713
    ->  52.96us BEGIN caml_thread_id
    4589/4589  108652.292099856:                                1 branches:uH:   return                           b02da0 Thread.fun_713+0x10 (/tmp/clark.exe) =>           6f0fd6 Async_unix.Raw_scheduler.one_iter_13456+0x306 (/tmp/clark.exe)
    4589/4589  108652.292099856:                                1 branches:uH:   call                             6f0fe0 Async_unix.Raw_scheduler.one_iter_13456+0x310 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099857:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    -> 52.961us END   caml_thread_id
    -> 52.961us END   Thread.fun_713
    -> 52.961us BEGIN caml_apply2
    4589/4589  108652.292099858:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           6f0fe5 Async_unix.Raw_scheduler.one_iter_13456+0x315 (/tmp/clark.exe)
    -> 52.962us END   caml_apply2
    -> 52.962us BEGIN Core.Int.fun_13981
    4589/4589  108652.292099859:                                1 branches:uH:   return                           6f0ff4 Async_unix.Raw_scheduler.one_iter_13456+0x324 (/tmp/clark.exe) =>           6f1549 Async_unix.Raw_scheduler.loop_13465+0xd9 (/tmp/clark.exe)
    -> 52.963us END   Core.Int.fun_13981
    4589/4589  108652.292099885:                                1 branches:uH:   call                             6f14a0 Async_unix.Raw_scheduler.loop_13465+0x30 (/tmp/clark.exe) =>           820330 Async_kernel.Scheduler.check_invariants_8475+0x0 (/tmp/clark.exe)
    -> 52.964us END   Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292099885:                                1 branches:uH:   return                           820337 Async_kernel.Scheduler.check_invariants_8475+0x7 (/tmp/clark.exe) =>           6f14a2 Async_unix.Raw_scheduler.loop_13465+0x32 (/tmp/clark.exe)
    4589/4589  108652.292099896:                                1 branches:uH:   call                             6f14d5 Async_unix.Raw_scheduler.loop_13465+0x65 (/tmp/clark.exe) =>           7ffa60 Async_kernel.Scheduler1.uncaught_exn_7315+0x0 (/tmp/clark.exe)
    ->  52.99us BEGIN Async_kernel.Scheduler.check_invariants_8475
    -> 53.001us END   Async_kernel.Scheduler.check_invariants_8475
    4589/4589  108652.292099899:                                1 branches:uH:   return                           7ffae9 Async_kernel.Scheduler1.uncaught_exn_7315+0x89 (/tmp/clark.exe) =>           6f14d7 Async_unix.Raw_scheduler.loop_13465+0x67 (/tmp/clark.exe)
    -> 53.001us BEGIN Async_kernel.Scheduler1.uncaught_exn_7315
    4589/4589  108652.292099899:                                1 branches:uH:   call                             6f1544 Async_unix.Raw_scheduler.loop_13465+0xd4 (/tmp/clark.exe) =>           6f0cd0 Async_unix.Raw_scheduler.one_iter_13456+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099930:                                1 branches:uH:   call                             6f0d01 Async_unix.Raw_scheduler.one_iter_13456+0x31 (/tmp/clark.exe) =>           d0a360 Stdlib.Lazy.is_val_370+0x0 (/tmp/clark.exe)
    -> 53.004us END   Async_kernel.Scheduler1.uncaught_exn_7315
    -> 53.004us BEGIN Async_unix.Raw_scheduler.one_iter_13456
    4589/4589  108652.292099930:                                1 branches:uH:   call                             d0a367 Stdlib.Lazy.is_val_370+0x7 (/tmp/clark.exe) =>           d62bb0 caml_obj_tag+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099935:                                1 branches:uH:   call                             d62bd0 caml_obj_tag+0x20 (/tmp/clark.exe) =>           d538d0 caml_page_table_lookup+0x0 (/tmp/clark.exe)
    -> 53.035us BEGIN Stdlib.Lazy.is_val_370
    -> 53.037us BEGIN caml_obj_tag
    4589/4589  108652.292099955:                                1 branches:uH:   return                           d53942 caml_page_table_lookup+0x72 (/tmp/clark.exe) =>           d62bd5 caml_obj_tag+0x25 (/tmp/clark.exe)
    ->  53.04us BEGIN caml_page_table_lookup
    4589/4589  108652.292099955:                                1 branches:uH:   return                           d62beb caml_obj_tag+0x3b (/tmp/clark.exe) =>           d0a36c Stdlib.Lazy.is_val_370+0xc (/tmp/clark.exe)
    4589/4589  108652.292099955:                                1 branches:uH:   return                           d0a384 Stdlib.Lazy.is_val_370+0x24 (/tmp/clark.exe) =>           6f0d03 Async_unix.Raw_scheduler.one_iter_13456+0x33 (/tmp/clark.exe)
    4589/4589  108652.292099955:                                1 branches:uH:   call                             6f0dfb Async_unix.Raw_scheduler.one_iter_13456+0x12b (/tmp/clark.exe) =>           6eeeb0 Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099978:                                1 branches:uH:   call                             6eeecb Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1b (/tmp/clark.exe) =>           cc66e0 Base.Stack.is_empty_1236+0x0 (/tmp/clark.exe)
    ->  53.06us END   caml_page_table_lookup
    ->  53.06us END   caml_obj_tag
    ->  53.06us END   Stdlib.Lazy.is_val_370
    ->  53.06us BEGIN Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    4589/4589  108652.292099979:                                1 branches:uH:   return                           cc66f3 Base.Stack.is_empty_1236+0x13 (/tmp/clark.exe) =>           6eeecd Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x1d (/tmp/clark.exe)
    -> 53.083us BEGIN Base.Stack.is_empty_1236
    4589/4589  108652.292099979:                                1 branches:uH:   return                           6eeedc Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408+0x2c (/tmp/clark.exe) =>           6f0e00 Async_unix.Raw_scheduler.one_iter_13456+0x130 (/tmp/clark.exe)
    4589/4589  108652.292099979:                                1 branches:uH:   call                             6f0e05 Async_unix.Raw_scheduler.one_iter_13456+0x135 (/tmp/clark.exe) =>           6f07f0 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099979:                                1 branches:uH:   call                             6f0825 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x35 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099981:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    -> 53.084us END   Base.Stack.is_empty_1236
    -> 53.084us END   Async_unix.Raw_scheduler.sync_changed_fds_to_file_descr_watcher_12408
    -> 53.084us BEGIN Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    -> 53.085us BEGIN caml_apply2
    4589/4589  108652.292099981:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           6f082a Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x3a (/tmp/clark.exe)
    4589/4589  108652.292099981:                                1 branches:uH:   call                             6f0874 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x84 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292099984:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    -> 53.086us END   caml_apply2
    -> 53.086us BEGIN Core.Int.fun_13983
    -> 53.087us END   Core.Int.fun_13983
    -> 53.087us BEGIN caml_apply2
    4589/4589  108652.292099984:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           6f0879 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x89 (/tmp/clark.exe)
    4589/4589  108652.292099985:                                1 branches:uH:   call                             6f089b Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xab (/tmp/clark.exe) =>           81c840 Async_kernel.Scheduler.can_run_a_job_5765+0x0 (/tmp/clark.exe)
    -> 53.089us END   caml_apply2
    -> 53.089us BEGIN Base.Int63.fun_4892
    ->  53.09us END   Base.Int63.fun_4892
    4589/4589  108652.292099985:                                1 branches:uH:   call                             81c86d Async_kernel.Scheduler.can_run_a_job_5765+0x2d (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100163:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd940 Core.Int.fun_13983+0x0 (/tmp/clark.exe)
    ->  53.09us BEGIN Async_kernel.Scheduler.can_run_a_job_5765
    -> 53.179us BEGIN caml_apply2
    4589/4589  108652.292100163:                                1 branches:uH:   return                           9dd94f Core.Int.fun_13983+0xf (/tmp/clark.exe) =>           81c872 Async_kernel.Scheduler.can_run_a_job_5765+0x32 (/tmp/clark.exe)
    4589/4589  108652.292100164:                                1 branches:uH:   return                           81c88a Async_kernel.Scheduler.can_run_a_job_5765+0x4a (/tmp/clark.exe) =>           6f089d Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0xad (/tmp/clark.exe)
    -> 53.268us END   caml_apply2
    -> 53.268us BEGIN Core.Int.fun_13983
    -> 53.269us END   Core.Int.fun_13983
    4589/4589  108652.292100165:                                1 branches:uH:   call                             6f0926 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x136 (/tmp/clark.exe) =>           81c8a0 Async_kernel.Scheduler.has_upcoming_event_5918+0x0 (/tmp/clark.exe)
    -> 53.269us END   Async_kernel.Scheduler.can_run_a_job_5765
    4589/4589  108652.292100175:                                1 branches:uH:   call                             81c8bd Async_kernel.Scheduler.has_upcoming_event_5918+0x1d (/tmp/clark.exe) =>           8ad630 Timing_wheel.is_empty_19261+0x0 (/tmp/clark.exe)
    ->  53.27us BEGIN Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292100175:                                1 branches:uH:   jmp                              8ad657 Timing_wheel.is_empty_19261+0x27 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100177:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    ->  53.28us BEGIN Timing_wheel.is_empty_19261
    -> 53.281us END   Timing_wheel.is_empty_19261
    -> 53.281us BEGIN caml_apply2
    4589/4589  108652.292100177:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           81c8bf Async_kernel.Scheduler.has_upcoming_event_5918+0x1f (/tmp/clark.exe)
    4589/4589  108652.292100177:                                1 branches:uH:   return                           81c8ce Async_kernel.Scheduler.has_upcoming_event_5918+0x2e (/tmp/clark.exe) =>           6f0928 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x138 (/tmp/clark.exe)
    4589/4589  108652.292100182:                                1 branches:uH:   call                             6f094f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x15f (/tmp/clark.exe) =>           81c910 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x0 (/tmp/clark.exe)
    -> 53.282us END   caml_apply2
    -> 53.282us BEGIN Core.Int.fun_13981
    -> 53.287us END   Core.Int.fun_13981
    -> 53.287us END   Async_kernel.Scheduler.has_upcoming_event_5918
    4589/4589  108652.292100183:                                1 branches:uH:   jmp                              81c939 Async_kernel.Scheduler.next_upcoming_event_exn_5924+0x29 (/tmp/clark.exe) =>           8ae2b0 Timing_wheel.next_alarm_fires_at_exn_19321+0x0 (/tmp/clark.exe)
    -> 53.287us BEGIN Async_kernel.Scheduler.next_upcoming_event_exn_5924
    4589/4589  108652.292100184:                                1 branches:uH:   call                             8ae2d8 Timing_wheel.next_alarm_fires_at_exn_19321+0x28 (/tmp/clark.exe) =>           8a6540 Timing_wheel.min_elt.16860+0x0 (/tmp/clark.exe)
    -> 53.288us END   Async_kernel.Scheduler.next_upcoming_event_exn_5924
    -> 53.288us BEGIN Timing_wheel.next_alarm_fires_at_exn_19321
    4589/4589  108652.292100195:                                1 branches:uH:   call                             8a6579 Timing_wheel.min_elt.16860+0x39 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    -> 53.289us BEGIN Timing_wheel.min_elt.16860
    4589/4589  108652.292100197:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd950 Core.Int.fun_13981+0x0 (/tmp/clark.exe)
    ->   53.3us BEGIN caml_apply2
    4589/4589  108652.292100198:                                1 branches:uH:   return                           9dd95f Core.Int.fun_13981+0xf (/tmp/clark.exe) =>           8a657e Timing_wheel.min_elt.16860+0x3e (/tmp/clark.exe)
    -> 53.302us END   caml_apply2
    -> 53.302us BEGIN Core.Int.fun_13981
    4589/4589  108652.292100210:                                1 branches:uH:   call                             8a65c5 Timing_wheel.min_elt.16860+0x85 (/tmp/clark.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (/tmp/clark.exe)
    -> 53.303us END   Core.Int.fun_13981
    4589/4589  108652.292100211:                                1 branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (/tmp/clark.exe) =>           8a65c7 Timing_wheel.min_elt.16860+0x87 (/tmp/clark.exe)
    -> 53.315us BEGIN Tuple_pool.is_null_4272
    4589/4589  108652.292100211:                                1 branches:uH:   return                           8a6a45 Timing_wheel.min_elt.16860+0x505 (/tmp/clark.exe) =>           8ae2dd Timing_wheel.next_alarm_fires_at_exn_19321+0x2d (/tmp/clark.exe)
    4589/4589  108652.292100212:                                1 branches:uH:   call                             8ae2fa Timing_wheel.next_alarm_fires_at_exn_19321+0x4a (/tmp/clark.exe) =>           8bbf80 Tuple_pool.is_null_4272+0x0 (/tmp/clark.exe)
    -> 53.316us END   Tuple_pool.is_null_4272
    -> 53.316us END   Timing_wheel.min_elt.16860
    4589/4589  108652.292100213:                                1 branches:uH:   return                           8bbf90 Tuple_pool.is_null_4272+0x10 (/tmp/clark.exe) =>           8ae2fc Timing_wheel.next_alarm_fires_at_exn_19321+0x4c (/tmp/clark.exe)
    -> 53.317us BEGIN Tuple_pool.is_null_4272
    4589/4589  108652.292100213:                                1 branches:uH:   call                             8ae33a Timing_wheel.next_alarm_fires_at_exn_19321+0x8a (/tmp/clark.exe) =>           6c88c0 caml_apply3+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100214:                                1 branches:uH:   jmp                              6c88da caml_apply3+0x1a (/tmp/clark.exe) =>           8c3e90 Tuple_pool.get_8303+0x0 (/tmp/clark.exe)
    -> 53.318us END   Tuple_pool.is_null_4272
    -> 53.318us BEGIN caml_apply3
    4589/4589  108652.292100214:                                1 branches:uH:   jmp                              8c3ec4 Tuple_pool.get_8303+0x34 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100215:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c962a0 Base.Uniform_array.get_1544+0x0 (/tmp/clark.exe)
    -> 53.319us END   caml_apply3
    -> 53.319us BEGIN Tuple_pool.get_8303
    -> 53.319us END   Tuple_pool.get_8303
    -> 53.319us BEGIN caml_apply2
    4589/4589  108652.292100215:                                1 branches:uH:   return                           c962ba Base.Uniform_array.get_1544+0x1a (/tmp/clark.exe) =>           8ae33f Timing_wheel.next_alarm_fires_at_exn_19321+0x8f (/tmp/clark.exe)
    4589/4589  108652.292100215:                                1 branches:uH:   call                             8ae362 Timing_wheel.next_alarm_fires_at_exn_19321+0xb2 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100220:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    ->  53.32us END   caml_apply2
    ->  53.32us BEGIN Base.Uniform_array.get_1544
    -> 53.322us END   Base.Uniform_array.get_1544
    -> 53.322us BEGIN caml_apply2
    4589/4589  108652.292100221:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           8ae367 Timing_wheel.next_alarm_fires_at_exn_19321+0xb7 (/tmp/clark.exe)
    -> 53.325us END   caml_apply2
    -> 53.325us BEGIN Base.Int.fun_3468
    4589/4589  108652.292100223:                                1 branches:uH:   call                             8ae397 Timing_wheel.next_alarm_fires_at_exn_19321+0xe7 (/tmp/clark.exe) =>           c65880 Base.Int.succ_2528+0x0 (/tmp/clark.exe)
    -> 53.326us END   Base.Int.fun_3468
    4589/4589  108652.292100223:                                1 branches:uH:   return                           c65884 Base.Int.succ_2528+0x4 (/tmp/clark.exe) =>           8ae399 Timing_wheel.next_alarm_fires_at_exn_19321+0xe9 (/tmp/clark.exe)
    4589/4589  108652.292100223:                                1 branches:uH:   call                             8ae3bb Timing_wheel.next_alarm_fires_at_exn_19321+0x10b (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100224:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86320 Base.Int63.fun_4894+0x0 (/tmp/clark.exe)
    -> 53.328us BEGIN Base.Int.succ_2528
    -> 53.328us END   Base.Int.succ_2528
    -> 53.328us BEGIN caml_apply2
    4589/4589  108652.292100224:                                1 branches:uH:   return                           c8632f Base.Int63.fun_4894+0xf (/tmp/clark.exe) =>           8ae3c0 Timing_wheel.next_alarm_fires_at_exn_19321+0x110 (/tmp/clark.exe)
    4589/4589  108652.292100224:                                1 branches:uH:   call                             8ae3f4 Timing_wheel.next_alarm_fires_at_exn_19321+0x144 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100225:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86330 Base.Int63.fun_4892+0x0 (/tmp/clark.exe)
    -> 53.329us END   caml_apply2
    -> 53.329us BEGIN Base.Int63.fun_4894
    -> 53.329us END   Base.Int63.fun_4894
    -> 53.329us BEGIN caml_apply2
    4589/4589  108652.292100226:                                1 branches:uH:   return                           c8633f Base.Int63.fun_4892+0xf (/tmp/clark.exe) =>           8ae3f9 Timing_wheel.next_alarm_fires_at_exn_19321+0x149 (/tmp/clark.exe)
    ->  53.33us END   caml_apply2
    ->  53.33us BEGIN Base.Int63.fun_4892
    4589/4589  108652.292100226:                                1 branches:uH:   call                             8ae43e Timing_wheel.next_alarm_fires_at_exn_19321+0x18e (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100227:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65960 Base.Int.shift_left_2568+0x0 (/tmp/clark.exe)
    -> 53.331us END   Base.Int63.fun_4892
    -> 53.331us BEGIN caml_apply2
    4589/4589  108652.292100228:                                1 branches:uH:   return                           c65971 Base.Int.shift_left_2568+0x11 (/tmp/clark.exe) =>           8ae443 Timing_wheel.next_alarm_fires_at_exn_19321+0x193 (/tmp/clark.exe)
    -> 53.332us END   caml_apply2
    -> 53.332us BEGIN Base.Int.shift_left_2568
    4589/4589  108652.292100229:                                1 branches:uH:   jmp                              8ae44e Timing_wheel.next_alarm_fires_at_exn_19321+0x19e (/tmp/clark.exe) =>           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe)
    -> 53.333us END   Base.Int.shift_left_2568
    4589/4589  108652.292100230:                                1 branches:uH:   return                           af2030 Core.Time_ns.of_int63_ns_since_epoch_5150+0x0 (/tmp/clark.exe) =>           6f0951 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x161 (/tmp/clark.exe)
    -> 53.334us END   Timing_wheel.next_alarm_fires_at_exn_19321
    -> 53.334us BEGIN Core.Time_ns.of_int63_ns_since_epoch_5150
    4589/4589  108652.292100230:                                1 branches:uH:   call                             6f09dc Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1ec (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100233:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    -> 53.335us END   Core.Time_ns.of_int63_ns_since_epoch_5150
    -> 53.335us BEGIN caml_apply2
    4589/4589  108652.292100233:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           6f09e1 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x1f1 (/tmp/clark.exe)
    4589/4589  108652.292100233:                                1 branches:uH:   call                             6f0b3f Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x34f (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100235:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c86350 Base.Int63.fun_4888+0x0 (/tmp/clark.exe)
    -> 53.338us END   caml_apply2
    -> 53.338us BEGIN Base.Int.fun_3468
    -> 53.339us END   Base.Int.fun_3468
    -> 53.339us BEGIN caml_apply2
    4589/4589  108652.292100235:                                1 branches:uH:   return                           c8635f Base.Int63.fun_4888+0xf (/tmp/clark.exe) =>           6f0b44 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x354 (/tmp/clark.exe)
    4589/4589  108652.292100235:                                1 branches:uH:   jmp                              6f0cb3 Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444+0x4c3 (/tmp/clark.exe) =>           6efe20 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100257:                                1 branches:uH:   call                             6efe8a Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6a (/tmp/clark.exe) =>           6d4ff0 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x0 (/tmp/clark.exe)
    ->  53.34us END   caml_apply2
    ->  53.34us BEGIN Base.Int63.fun_4888
    -> 53.351us END   Base.Int63.fun_4888
    -> 53.351us END   Async_unix.Raw_scheduler.compute_timeout_and_check_file_descr_watcher_13444
    -> 53.351us BEGIN Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    4589/4589  108652.292100257:                                1 branches:uH:   return                           6d4ff5 Async_unix.Epoll_file_descr_watcher.pre_check_8138+0x5 (/tmp/clark.exe) =>           6efe8c Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0x6c (/tmp/clark.exe)
    4589/4589  108652.292100259:                                1 branches:uH:   call                             6efecd Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xad (/tmp/clark.exe) =>           7af180 Nano_mutex.unlock_exn_5263+0x0 (/tmp/clark.exe)
    -> 53.362us BEGIN Async_unix.Epoll_file_descr_watcher.pre_check_8138
    -> 53.364us END   Async_unix.Epoll_file_descr_watcher.pre_check_8138
    4589/4589  108652.292100264:                                1 branches:uH:   call                             7af1bd Nano_mutex.unlock_exn_5263+0x3d (/tmp/clark.exe) =>           b02db0 Thread.fun_715+0x0 (/tmp/clark.exe)
    -> 53.364us BEGIN Nano_mutex.unlock_exn_5263
    4589/4589  108652.292100264:                                1 branches:uH:   call                             b02db7 Thread.fun_715+0x7 (/tmp/clark.exe) =>           d44690 caml_thread_self+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100265:                                1 branches:uH:   return                           d4469f caml_thread_self+0xf (/tmp/clark.exe) =>           b02dbc Thread.fun_715+0xc (/tmp/clark.exe)
    -> 53.369us BEGIN Thread.fun_715
    -> 53.369us BEGIN caml_thread_self
    4589/4589  108652.292100265:                                1 branches:uH:   return                           b02dc0 Thread.fun_715+0x10 (/tmp/clark.exe) =>           7af1bf Nano_mutex.unlock_exn_5263+0x3f (/tmp/clark.exe)
    4589/4589  108652.292100266:                                1 branches:uH:   call                             7af1c6 Nano_mutex.unlock_exn_5263+0x46 (/tmp/clark.exe) =>           b02d90 Thread.fun_713+0x0 (/tmp/clark.exe)
    ->  53.37us END   caml_thread_self
    ->  53.37us END   Thread.fun_715
    4589/4589  108652.292100266:                                1 branches:uH:   call                             b02d97 Thread.fun_713+0x7 (/tmp/clark.exe) =>           d446b0 caml_thread_id+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100267:                                1 branches:uH:   return                           d446b3 caml_thread_id+0x3 (/tmp/clark.exe) =>           b02d9c Thread.fun_713+0xc (/tmp/clark.exe)
    -> 53.371us BEGIN Thread.fun_713
    -> 53.371us BEGIN caml_thread_id
    4589/4589  108652.292100267:                                1 branches:uH:   return                           b02da0 Thread.fun_713+0x10 (/tmp/clark.exe) =>           7af1c8 Nano_mutex.unlock_exn_5263+0x48 (/tmp/clark.exe)
    4589/4589  108652.292100267:                                1 branches:uH:   call                             7af1e9 Nano_mutex.unlock_exn_5263+0x69 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100268:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           9dd920 Core.Int.fun_13987+0x0 (/tmp/clark.exe)
    -> 53.372us END   caml_thread_id
    -> 53.372us END   Thread.fun_713
    -> 53.372us BEGIN caml_apply2
    4589/4589  108652.292100268:                                1 branches:uH:   return                           9dd92f Core.Int.fun_13987+0xf (/tmp/clark.exe) =>           7af1ee Nano_mutex.unlock_exn_5263+0x6e (/tmp/clark.exe)
    4589/4589  108652.292100268:                                1 branches:uH:   call                             7af212 Nano_mutex.unlock_exn_5263+0x92 (/tmp/clark.exe) =>           6c8840 caml_apply2+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100272:                                1 branches:uH:   jmp                              6c885a caml_apply2+0x1a (/tmp/clark.exe) =>           c65180 Base.Int.fun_3468+0x0 (/tmp/clark.exe)
    -> 53.373us END   caml_apply2
    -> 53.373us BEGIN Core.Int.fun_13987
    -> 53.375us END   Core.Int.fun_13987
    -> 53.375us BEGIN caml_apply2
    4589/4589  108652.292100273:                                1 branches:uH:   return                           c6518f Base.Int.fun_3468+0xf (/tmp/clark.exe) =>           7af217 Nano_mutex.unlock_exn_5263+0x97 (/tmp/clark.exe)
    -> 53.377us END   caml_apply2
    -> 53.377us BEGIN Base.Int.fun_3468
    4589/4589  108652.292100273:                                1 branches:uH:   call                             7af22c Nano_mutex.unlock_exn_5263+0xac (/tmp/clark.exe) =>           d53b20 caml_modify+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100273:                                1 branches:uH:   return                           d53b48 caml_modify+0x28 (/tmp/clark.exe) =>           7af231 Nano_mutex.unlock_exn_5263+0xb1 (/tmp/clark.exe)
    4589/4589  108652.292100282:                                1 branches:uH:   call                             7af247 Nano_mutex.unlock_exn_5263+0xc7 (/tmp/clark.exe) =>           c12c50 Base.Option.is_some_1124+0x0 (/tmp/clark.exe)
    -> 53.378us END   Base.Int.fun_3468
    -> 53.378us BEGIN caml_modify
    -> 53.387us END   caml_modify
    4589/4589  108652.292100282:                                1 branches:uH:   return                           c12c61 Base.Option.is_some_1124+0x11 (/tmp/clark.exe) =>           7af249 Nano_mutex.unlock_exn_5263+0xc9 (/tmp/clark.exe)
    4589/4589  108652.292100284:                                1 branches:uH:   jmp                              7af296 Nano_mutex.unlock_exn_5263+0x116 (/tmp/clark.exe) =>           c15330 Base.Or_error.ok_exn_2208+0x0 (/tmp/clark.exe)
    -> 53.387us BEGIN Base.Option.is_some_1124
    -> 53.389us END   Base.Option.is_some_1124
    4589/4589  108652.292100284:                                1 branches:uH:   return                           c15407 Base.Or_error.ok_exn_2208+0xd7 (/tmp/clark.exe) =>           6efecf Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xaf (/tmp/clark.exe)
    4589/4589  108652.292100285:                                1 branches:uH:   call                             6efee2 Async_unix.Raw_scheduler.check_file_descr_watcher_13399+0xc2 (/tmp/clark.exe) =>           b02d50 Thread.fun_709+0x0 (/tmp/clark.exe)
    -> 53.389us END   Nano_mutex.unlock_exn_5263
    -> 53.389us BEGIN Base.Or_error.ok_exn_2208
    ->  53.39us END   Base.Or_error.ok_exn_2208
    4589/4589  108652.292100285:                                1 branches:uH:   call                             b02d5e Thread.fun_709+0xe (/tmp/clark.exe) =>           d6d414 caml_c_call+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100286:                                1 branches:uH:   jmp                              d6d43c caml_c_call+0x28 (/tmp/clark.exe) =>           d44780 caml_thread_yield+0x0 (/tmp/clark.exe)
    ->  53.39us BEGIN Thread.fun_709
    ->  53.39us BEGIN caml_c_call
    4589/4589  108652.292100286:                                1 branches:uH:   call                             d44796 caml_thread_yield+0x16 (/tmp/clark.exe) =>           d4de40 caml_process_pending_signals_exn+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100286:                                1 branches:uH:   return                           d4df0e caml_process_pending_signals_exn+0xce (/tmp/clark.exe) =>           d4479b caml_thread_yield+0x1b (/tmp/clark.exe)
    4589/4589  108652.292100286:                                1 branches:uH:   call                             d447a5 caml_thread_yield+0x25 (/tmp/clark.exe) =>           d4dd10 caml_raise_async_if_exception+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100286:                                1 branches:uH:   return                           d4dd21 caml_raise_async_if_exception+0x11 (/tmp/clark.exe) =>           d447aa caml_thread_yield+0x2a (/tmp/clark.exe)
    4589/4589  108652.292100286:                                1 branches:uH:   call                             d447fa caml_thread_yield+0x7a (/tmp/clark.exe) =>           d53c20 caml_get_local_arenas+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100290:                                1 branches:uH:   return                           d53c3e caml_get_local_arenas+0x1e (/tmp/clark.exe) =>           d447ff caml_thread_yield+0x7f (/tmp/clark.exe)
    -> 53.391us END   caml_c_call
    -> 53.391us BEGIN caml_thread_yield
    -> 53.392us BEGIN caml_process_pending_signals_exn
    -> 53.393us END   caml_process_pending_signals_exn
    -> 53.393us BEGIN caml_raise_async_if_exception
    -> 53.394us END   caml_raise_async_if_exception
    -> 53.394us BEGIN caml_get_local_arenas
    4589/4589  108652.292100290:                                1 branches:uH:   call                             d44839 caml_thread_yield+0xb9 (/tmp/clark.exe) =>           d6c8d0 caml_memprof_leave_thread+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100290:                                1 branches:uH:   return                           d6c8db caml_memprof_leave_thread+0xb (/tmp/clark.exe) =>           d4483e caml_thread_yield+0xbe (/tmp/clark.exe)
    4589/4589  108652.292100290:                                1 branches:uH:   call                             d44845 caml_thread_yield+0xc5 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100292:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 53.395us END   caml_get_local_arenas
    -> 53.395us BEGIN caml_memprof_leave_thread
    -> 53.396us END   caml_memprof_leave_thread
    -> 53.396us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292100357:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d4484a caml_thread_yield+0xca (/tmp/clark.exe)
    -> 53.397us END   pthread_mutex_lock@plt
    -> 53.397us BEGIN pthread_mutex_lock
    4589/4589  108652.292100363:                                1 branches:uH:   call                             d44873 caml_thread_yield+0xf3 (/tmp/clark.exe) =>           d437a0 custom_condvar_signal+0x0 (/tmp/clark.exe)
    -> 53.462us END   pthread_mutex_lock
    4589/4589  108652.292100363:                                1 branches:uH:   call                             d437c9 custom_condvar_signal+0x29 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292100372:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    -> 53.468us BEGIN custom_condvar_signal
    -> 53.472us BEGIN syscall@plt
    4589/4589  108652.292100388:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 53.477us END   syscall@plt
    -> 53.477us BEGIN syscall
    4589/4589  108652.292101290:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    -> 53.493us BEGIN [syscall]
    4589/4589  108652.292101298:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d437ce custom_condvar_signal+0x2e (/tmp/clark.exe)
    -> 54.395us END   [syscall]
    4589/4589  108652.292101300:                                1 branches:uH:   return                           d437d4 custom_condvar_signal+0x34 (/tmp/clark.exe) =>           d44878 caml_thread_yield+0xf8 (/tmp/clark.exe)
    -> 54.403us END   syscall
    4589/4589  108652.292101300:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    4589/4589  108652.292101300:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292101305:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 54.405us END   custom_condvar_signal
    -> 54.405us BEGIN custom_condvar_wait
    -> 54.407us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292101305:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    4589/4589  108652.292101305:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292101313:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    ->  54.41us END   pthread_mutex_unlock@plt
    ->  54.41us BEGIN pthread_mutex_unlock
    -> 54.414us END   pthread_mutex_unlock
    -> 54.414us BEGIN syscall@plt
    4589/4589  108652.292101329:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 54.418us END   syscall@plt
    -> 54.418us BEGIN syscall
    4589/4589  108652.292113610:                                1 branches:uH:   tr strt                               0 [unknown] ([unknown]) =>     7ffff71e0e29 syscall+0x19 (/usr/lib64/libc-2.17.so)
    -> 54.434us BEGIN [syscall]
    4589/4589  108652.292113629:                                1 branches:uH:   return                     7ffff71e0e31 syscall+0x21 (/usr/lib64/libc-2.17.so) =>           d4378d custom_condvar_wait+0x3d (/tmp/clark.exe)
    -> 66.715us END   [syscall]
    4589/4589  108652.292113629:                                1 branches:uH:   call                             d43790 custom_condvar_wait+0x40 (/tmp/clark.exe) =>           6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292113656:                                1 branches:uH:   jmp                              6863e0 pthread_mutex_lock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c5d00 pthread_mutex_lock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 66.734us END   syscall
    -> 66.734us BEGIN pthread_mutex_lock@plt
    4589/4589  108652.292113713:                                1 branches:uH:   return                     7ffff79c5d7c pthread_mutex_lock+0x7c (/usr/lib64/libpthread-2.17.so) =>           d43795 custom_condvar_wait+0x45 (/tmp/clark.exe)
    -> 66.761us END   pthread_mutex_lock@plt
    -> 66.761us BEGIN pthread_mutex_lock
    4589/4589  108652.292113720:                                1 branches:uH:   return                           d4379f custom_condvar_wait+0x4f (/tmp/clark.exe) =>           d448a3 caml_thread_yield+0x123 (/tmp/clark.exe)
    -> 66.818us END   pthread_mutex_lock
    4589/4589  108652.292113733:                                1 branches:uH:   call                             d4489e caml_thread_yield+0x11e (/tmp/clark.exe) =>           d43750 custom_condvar_wait+0x0 (/tmp/clark.exe)
    -> 66.825us END   custom_condvar_wait
    4589/4589  108652.292113733:                                1 branches:uH:   call                             d43764 custom_condvar_wait+0x14 (/tmp/clark.exe) =>           6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292113742:                                1 branches:uH:   jmp                              6863d0 pthread_mutex_unlock@plt+0x0 (/tmp/clark.exe) =>     7ffff79c6ee0 pthread_mutex_unlock+0x0 (/usr/lib64/libpthread-2.17.so)
    -> 66.838us BEGIN custom_condvar_wait
    -> 66.842us BEGIN pthread_mutex_unlock@plt
    4589/4589  108652.292113743:                                1 branches:uH:   return                     7ffff79c6f14 pthread_mutex_unlock+0x34 (/usr/lib64/libpthread-2.17.so) =>           d43769 custom_condvar_wait+0x19 (/tmp/clark.exe)
    -> 66.847us END   pthread_mutex_unlock@plt
    -> 66.847us BEGIN pthread_mutex_unlock
    4589/4589  108652.292113743:                                1 branches:uH:   call                             d43788 custom_condvar_wait+0x38 (/tmp/clark.exe) =>           685cc0 syscall@plt+0x0 (/tmp/clark.exe)
    4589/4589  108652.292113750:                                1 branches:uH:   jmp                              685cc0 syscall@plt+0x0 (/tmp/clark.exe) =>     7ffff71e0e10 syscall+0x0 (/usr/lib64/libc-2.17.so)
    -> 66.848us END   pthread_mutex_unlock
    -> 66.848us BEGIN syscall@plt
    4589/4589  108652.292113766:                                1 branches:uH:   tr end  syscall            7ffff71e0e27 syscall+0x17 (/usr/lib64/libc-2.17.so) =>                0 [unknown] ([unknown])
    -> 66.855us END   syscall@plt
    -> 66.855us BEGIN syscall
    END
    -> 50.777us BEGIN Async_unix.Raw_scheduler.loop_13465 [inferred start time]
    -> 52.843us BEGIN Async_kernel.Job_queue.run_jobs_5243 [inferred start time]
    ->  52.78us BEGIN Async_kernel.Job_queue.run_jobs_5243 [inferred start time]
    -> 50.777us BEGIN Async_unix.Raw_scheduler.one_iter_13456 [inferred start time]
    -> 52.031us BEGIN Async_unix.Epoll_file_descr_watcher.post_check_9714 [inferred start time]
    -> 50.777us BEGIN Async_unix.Raw_scheduler.check_file_descr_watcher_13399 [inferred start time]
    -> 50.801us BEGIN Async_unix.Raw_fd.syscall_5838 [inferred start time]
    -> 50.801us BEGIN Async_unix.Interruptor.fun_5020 [inferred start time]
    -> 50.777us BEGIN Async_unix.Raw_fd.syscall_5838 [inferred start time]
    -> 47.739us BEGIN Async_unix.Epoll_file_descr_watcher.thread_safe_check_9694 [inferred start time]
    ->      0ns BEGIN Async_unix.Raw_scheduler.loop_13465 [inferred start time]
    ->      0ns BEGIN Async_unix.Raw_scheduler.one_iter_13456 [inferred start time]
    ->      0ns BEGIN Async_kernel.Scheduler.run_cycle_7957 [inferred start time]
    ->      0ns BEGIN Core.Span_ns.since_unix_epoch_9948 [inferred start time]
    ->      0ns BEGIN [unknown]
    ->      0ns END   [unknown]
    ->      0ns BEGIN Time_now.nanoseconds_since_unix_epoch_1088 [inferred start time]
    -> 66.871us BEGIN [syscall]
    -> 66.871us END   [syscall]
    -> 66.871us END   syscall
    -> 66.871us END   custom_condvar_wait
    -> 66.871us END   caml_thread_yield
    -> 66.871us END   Thread.fun_709
    -> 66.871us END   Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    -> 66.871us END   Async_unix.Raw_scheduler.one_iter_13456
    -> 66.871us END   Async_unix.Raw_scheduler.loop_13465
    -> 66.871us END   Async_unix.Raw_fd.syscall_5838
    -> 66.871us END   Async_unix.Interruptor.clear_4845
    -> 66.871us END   Async_unix.Raw_scheduler.check_file_descr_watcher_13399
    -> 66.871us END   Async_unix.Raw_scheduler.one_iter_13456
    -> 66.871us END   Async_unix.Raw_scheduler.loop_13465 |}]
;;
