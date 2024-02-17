open! Core
open! Async

let%expect_test "A page fault during demo.c" =
  let%map () = Perf_script.run ~trace_scope:Userspace_and_kernel "page_fault.perf" in
  [%expect
    {|
    1439745/1439745 2472089.651284813:                            1   branches:uH:   jmp                      7f59488f90f7 call_destructors+0x67 (foo.so) =>     7f5948676e18 _fini+0x0 (foo.so)
     instruction trace error type 1 time 2472089.651285037 cpu -1 pid 1439745 tid 1439745 ip 0x7f5948676e18 code 7: Overflow packet (foo.so)
    ->    224ns BEGIN [decode error: Overflow packet (foo.so)]
    ->          END   [decode error: Overflow packet (foo.so)]
    ->      0ns BEGIN _fini [inferred start time]
    ->    224ns END   _fini
    1439745/1439745 2472089.651285037:                            1   branches:uH:   tr strt                             0 [unknown] (foo.so) => ffffffffae200ab0 asm_exc_page_fault+0x0 (foo.so)
    1439745/1439745 2472089.651285037:                            1   branches:uH:   call                 ffffffffae200ab3 asm_exc_page_fault+0x3 (foo.so) => ffffffffae201310 error_entry+0x0 (foo.so)
    1439745/1439745 2472089.651285124:                            1   branches:uH:   call                 ffffffffae20137a error_entry+0x6a (foo.so) => ffffffffae121a30 sync_regs+0x0 (foo.so)
    ->    225ns BEGIN asm_exc_page_fault
    ->    268ns BEGIN error_entry
    1439745/1439745 2472089.651285217:                            1   branches:uH:   return               ffffffffae121a51 sync_regs+0x21 (foo.so) => ffffffffae20137f error_entry+0x6f (foo.so)
    ->    311ns BEGIN sync_regs
    1439745/1439745 2472089.651285217:                            1   branches:uH:   return               ffffffffae201384 error_entry+0x74 (foo.so) => ffffffffae200ab8 asm_exc_page_fault+0x8 (foo.so)
    1439745/1439745 2472089.651285217:                            1   branches:uH:   call                 ffffffffae200ac9 asm_exc_page_fault+0x19 (foo.so) => ffffffffae124750 exc_page_fault+0x0 (foo.so)
    1439745/1439745 2472089.651285217:                            1   branches:uH:   call                 ffffffffae124780 exc_page_fault+0x30 (foo.so) => ffffffffae124c20 irqentry_enter+0x0 (foo.so)
    1439745/1439745 2472089.651285219:                            1   branches:uH:   call                 ffffffffae124c3b irqentry_enter+0x1b (foo.so) => ffffffffae124c10 irqentry_enter_from_user_mode+0x0 (foo.so)
    ->    404ns END   sync_regs
    ->    404ns END   error_entry
    ->    404ns BEGIN exc_page_fault
    ->    405ns BEGIN irqentry_enter
    1439745/1439745 2472089.651285219:                            1   branches:uH:   return               ffffffffae124c10 irqentry_enter_from_user_mode+0x0 (foo.so) => ffffffffae124c40 irqentry_enter+0x20 (foo.so)
    1439745/1439745 2472089.651285219:                            1   branches:uH:   return               ffffffffae124c42 irqentry_enter+0x22 (foo.so) => ffffffffae124785 exc_page_fault+0x35 (foo.so)
    1439745/1439745 2472089.651285219:                            1   branches:uH:   call                 ffffffffae1247bd exc_page_fault+0x6d (foo.so) => ffffffffad677f70 do_user_addr_fault+0x0 (foo.so)
    1439745/1439745 2472089.651285239:                            1   branches:uH:   call                 ffffffffad67809c do_user_addr_fault+0x12c (foo.so) => ffffffffad6f5a40 down_read_trylock+0x0 (foo.so)
    ->    406ns BEGIN irqentry_enter_from_user_mode
    ->    416ns END   irqentry_enter_from_user_mode
    ->    416ns END   irqentry_enter
    ->    416ns BEGIN do_user_addr_fault
    1439745/1439745 2472089.651285247:                            1   branches:uH:   return               ffffffffad6f5a7f down_read_trylock+0x3f (foo.so) => ffffffffad6780a1 do_user_addr_fault+0x131 (foo.so)
    ->    426ns BEGIN down_read_trylock
    1439745/1439745 2472089.651285247:                            1   branches:uH:   call                 ffffffffad6780b4 do_user_addr_fault+0x144 (foo.so) => ffffffffad885d90 find_vma+0x0 (foo.so)
    1439745/1439745 2472089.651285247:                            1   branches:uH:   call                 ffffffffad885da1 find_vma+0x11 (foo.so) => ffffffffad871280 vmacache_find+0x0 (foo.so)
    1439745/1439745 2472089.651285276:                            1   branches:uH:   return               ffffffffad8712f3 vmacache_find+0x73 (foo.so) => ffffffffad885da6 find_vma+0x16 (foo.so)
    ->    434ns END   down_read_trylock
    ->    434ns BEGIN find_vma
    ->    448ns BEGIN vmacache_find
    1439745/1439745 2472089.651285290:                            1   branches:uH:   call                 ffffffffad885deb find_vma+0x5b (foo.so) => ffffffffad871240 vmacache_update+0x0 (foo.so)
    ->    463ns END   vmacache_find
    1439745/1439745 2472089.651285291:                            1   branches:uH:   return               ffffffffad871271 vmacache_update+0x31 (foo.so) => ffffffffad885df0 find_vma+0x60 (foo.so)
    ->    477ns BEGIN vmacache_update
    1439745/1439745 2472089.651285292:                            1   branches:uH:   return               ffffffffad885db1 find_vma+0x21 (foo.so) => ffffffffad6780b9 do_user_addr_fault+0x149 (foo.so)
    ->    478ns END   vmacache_update
    1439745/1439745 2472089.651285293:                            1   branches:uH:   call                 ffffffffad678127 do_user_addr_fault+0x1b7 (foo.so) => ffffffffad881480 handle_mm_fault+0x0 (foo.so)
    ->    479ns END   find_vma
    1439745/1439745 2472089.651285293:                            1   branches:uH:   call                 ffffffffad8814bf handle_mm_fault+0x3f (foo.so) => ffffffffad8e5c60 mem_cgroup_from_task+0x0 (foo.so)
    1439745/1439745 2472089.651285298:                            1   branches:uH:   return               ffffffffad8e5c75 mem_cgroup_from_task+0x15 (foo.so) => ffffffffad8814c4 handle_mm_fault+0x44 (foo.so)
    ->    480ns BEGIN handle_mm_fault
    ->    482ns BEGIN mem_cgroup_from_task
    1439745/1439745 2472089.651285298:                            1   branches:uH:   call                 ffffffffad8814e7 handle_mm_fault+0x67 (foo.so) => ffffffffad8eaf20 __count_memcg_events+0x0 (foo.so)
    1439745/1439745 2472089.651285298:                            1   branches:uH:   call                 ffffffffad8eaf47 __count_memcg_events+0x27 (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285307:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8eaf4c __count_memcg_events+0x2c (foo.so)
    ->    485ns END   mem_cgroup_from_task
    ->    485ns BEGIN __count_memcg_events
    ->    489ns BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285308:                            1   branches:uH:   return               ffffffffad8eaf7a __count_memcg_events+0x5a (foo.so) => ffffffffad8814ec handle_mm_fault+0x6c (foo.so)
    ->    494ns END   cgroup_rstat_updated
    1439745/1439745 2472089.651285308:                            1   branches:uH:   call                 ffffffffad8816d8 handle_mm_fault+0x258 (foo.so) => ffffffffad878f40 arch_local_irq_enable+0x0 (foo.so)
    1439745/1439745 2472089.651285309:                            1   branches:uH:   return               ffffffffad878f47 arch_local_irq_enable+0x7 (foo.so) => ffffffffad8816dd handle_mm_fault+0x25d (foo.so)
    ->    495ns END   __count_memcg_events
    ->    495ns BEGIN arch_local_irq_enable
    1439745/1439745 2472089.651285309:                            1   branches:uH:   call                 ffffffffad8814f9 handle_mm_fault+0x79 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285310:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad8814fe handle_mm_fault+0x7e (foo.so)
    ->    496ns END   arch_local_irq_enable
    ->    496ns BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285310:                            1   branches:uH:   call                 ffffffffad88154a handle_mm_fault+0xca (foo.so) => ffffffffad87ff50 __handle_mm_fault+0x0 (foo.so)
    1439745/1439745 2472089.651285317:                            1   branches:uH:   call                 ffffffffad88000d __handle_mm_fault+0xbd (foo.so) => ffffffffad878ff0 pgd_none+0x0 (foo.so)
    ->    497ns END   rcu_read_unlock_strict
    ->    497ns BEGIN __handle_mm_fault
    1439745/1439745 2472089.651285318:                            1   branches:uH:   return               ffffffffad879000 pgd_none+0x10 (foo.so) => ffffffffad880012 __handle_mm_fault+0xc2 (foo.so)
    ->    504ns BEGIN pgd_none
    1439745/1439745 2472089.651285318:                            1   branches:uH:   call                 ffffffffad880020 __handle_mm_fault+0xd0 (foo.so) => ffffffffad879320 p4d_offset+0x0 (foo.so)
    1439745/1439745 2472089.651285319:                            1   branches:uH:   return               ffffffffad879361 p4d_offset+0x41 (foo.so) => ffffffffad880025 __handle_mm_fault+0xd5 (foo.so)
    ->    505ns END   pgd_none
    ->    505ns BEGIN p4d_offset
    1439745/1439745 2472089.651285319:                            1   branches:uH:   call                 ffffffffad88011f __handle_mm_fault+0x1cf (foo.so) => ffffffffad878f30 pud_val+0x0 (foo.so)
    1439745/1439745 2472089.651285320:                            1   branches:uH:   return               ffffffffad878f37 pud_val+0x7 (foo.so) => ffffffffad880124 __handle_mm_fault+0x1d4 (foo.so)
    ->    506ns END   p4d_offset
    ->    506ns BEGIN pud_val
    1439745/1439745 2472089.651285320:                            1   branches:uH:   call                 ffffffffad880132 __handle_mm_fault+0x1e2 (foo.so) => ffffffffad878f30 pud_val+0x0 (foo.so)
    1439745/1439745 2472089.651285321:                            1   branches:uH:   return               ffffffffad878f37 pud_val+0x7 (foo.so) => ffffffffad880137 __handle_mm_fault+0x1e7 (foo.so)
    ->    507ns END   pud_val
    ->    507ns BEGIN pud_val
    1439745/1439745 2472089.651285322:                            1   branches:uH:   call                 ffffffffad8801cc __handle_mm_fault+0x27c (foo.so) => ffffffffad878f30 pud_val+0x0 (foo.so)
    ->    508ns END   pud_val
    1439745/1439745 2472089.651285322:                            1   branches:uH:   return               ffffffffad878f37 pud_val+0x7 (foo.so) => ffffffffad8801d1 __handle_mm_fault+0x281 (foo.so)
    1439745/1439745 2472089.651285323:                            1   branches:uH:   call                 ffffffffad88021c __handle_mm_fault+0x2cc (foo.so) => ffffffffad878f30 pud_val+0x0 (foo.so)
    ->    509ns BEGIN pud_val
    ->    510ns END   pud_val
    1439745/1439745 2472089.651285323:                            1   branches:uH:   return               ffffffffad878f37 pud_val+0x7 (foo.so) => ffffffffad880221 __handle_mm_fault+0x2d1 (foo.so)
    1439745/1439745 2472089.651285323:                            1   branches:uH:   call                 ffffffffad880233 __handle_mm_fault+0x2e3 (foo.so) => ffffffffad878f30 pud_val+0x0 (foo.so)
    1439745/1439745 2472089.651285324:                            1   branches:uH:   return               ffffffffad878f37 pud_val+0x7 (foo.so) => ffffffffad880238 __handle_mm_fault+0x2e8 (foo.so)
    ->    510ns BEGIN pud_val
    ->    510ns END   pud_val
    ->    510ns BEGIN pud_val
    1439745/1439745 2472089.651285324:                            1   branches:uH:   call                 ffffffffad8802b8 __handle_mm_fault+0x368 (foo.so) => ffffffffad878f20 pmd_val+0x0 (foo.so)
    1439745/1439745 2472089.651285326:                            1   branches:uH:   return               ffffffffad878f27 pmd_val+0x7 (foo.so) => ffffffffad8802bd __handle_mm_fault+0x36d (foo.so)
    ->    511ns END   pud_val
    ->    511ns BEGIN pmd_val
    1439745/1439745 2472089.651285326:                            1   branches:uH:   call                 ffffffffad8802d7 __handle_mm_fault+0x387 (foo.so) => ffffffffad878f20 pmd_val+0x0 (foo.so)
    1439745/1439745 2472089.651285327:                            1   branches:uH:   return               ffffffffad878f27 pmd_val+0x7 (foo.so) => ffffffffad8802dc __handle_mm_fault+0x38c (foo.so)
    ->    513ns END   pmd_val
    ->    513ns BEGIN pmd_val
    1439745/1439745 2472089.651285327:                            1   branches:uH:   call                 ffffffffad8805a1 __handle_mm_fault+0x651 (foo.so) => ffffffffad878f20 pmd_val+0x0 (foo.so)
    1439745/1439745 2472089.651285328:                            1   branches:uH:   return               ffffffffad878f27 pmd_val+0x7 (foo.so) => ffffffffad8805a6 __handle_mm_fault+0x656 (foo.so)
    ->    514ns END   pmd_val
    ->    514ns BEGIN pmd_val
    1439745/1439745 2472089.651285328:                            1   branches:uH:   call                 ffffffffad880790 __handle_mm_fault+0x840 (foo.so) => ffffffffad878f20 pmd_val+0x0 (foo.so)
    1439745/1439745 2472089.651285329:                            1   branches:uH:   return               ffffffffad878f27 pmd_val+0x7 (foo.so) => ffffffffad880795 __handle_mm_fault+0x845 (foo.so)
    ->    515ns END   pmd_val
    ->    515ns BEGIN pmd_val
    1439745/1439745 2472089.651285329:                            1   branches:uH:   call                 ffffffffad880807 __handle_mm_fault+0x8b7 (foo.so) => ffffffffad878fb0 pmd_page_vaddr+0x0 (foo.so)
    1439745/1439745 2472089.651285329:                            1   branches:uH:   call                 ffffffffad878fb4 pmd_page_vaddr+0x4 (foo.so) => ffffffffad878f20 pmd_val+0x0 (foo.so)
    1439745/1439745 2472089.651285331:                            1   branches:uH:   return               ffffffffad878f27 pmd_val+0x7 (foo.so) => ffffffffad878fb9 pmd_page_vaddr+0x9 (foo.so)
    ->    516ns END   pmd_val
    ->    516ns BEGIN pmd_page_vaddr
    ->    517ns BEGIN pmd_val
    1439745/1439745 2472089.651285331:                            1   branches:uH:   return               ffffffffad878fed pmd_page_vaddr+0x3d (foo.so) => ffffffffad88080c __handle_mm_fault+0x8bc (foo.so)
    1439745/1439745 2472089.651285339:                            1   branches:uH:   call                 ffffffffad880c1e __handle_mm_fault+0xcce (foo.so) => ffffffffad83bac0 filemap_map_pages+0x0 (foo.so)
    ->    518ns END   pmd_val
    ->    518ns END   pmd_page_vaddr
    1439745/1439745 2472089.651285339:                            1   branches:uH:   call                 ffffffffad83bb47 filemap_map_pages+0x87 (foo.so) => ffffffffadb56bd0 xas_find+0x0 (foo.so)
    1439745/1439745 2472089.651285351:                            1   branches:uH:   call                 ffffffffadb56d2c xas_find+0x15c (foo.so) => ffffffffadb56920 xas_load+0x0 (foo.so)
    ->    526ns BEGIN filemap_map_pages
    ->    532ns BEGIN xas_find
    1439745/1439745 2472089.651285351:                            1   branches:uH:   call                 ffffffffadb56920 xas_load+0x0 (foo.so) => ffffffffadb55f90 xas_start+0x0 (foo.so)
    1439745/1439745 2472089.651285357:                            1   branches:uH:   return               ffffffffadb55fd7 xas_start+0x47 (foo.so) => ffffffffadb56925 xas_load+0x5 (foo.so)
    ->    538ns BEGIN xas_load
    ->    541ns BEGIN xas_start
    1439745/1439745 2472089.651285366:                            1   branches:uH:   return               ffffffffadb5698d xas_load+0x6d (foo.so) => ffffffffadb56d31 xas_find+0x161 (foo.so)
    ->    544ns END   xas_start
    1439745/1439745 2472089.651285366:                            1   branches:uH:   return               ffffffffadb56c95 xas_find+0xc5 (foo.so) => ffffffffad83bb4c filemap_map_pages+0x8c (foo.so)
    1439745/1439745 2472089.651285366:                            1   branches:uH:   call                 ffffffffad83bb5a filemap_map_pages+0x9a (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    1439745/1439745 2472089.651285438:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83bb5f filemap_map_pages+0x9f (foo.so)
    ->    553ns END   xas_load
    ->    553ns END   xas_find
    ->    553ns BEGIN next_uptodate_page
    1439745/1439745 2472089.651285439:                            1   branches:uH:   call                 ffffffffad83be42 filemap_map_pages+0x382 (foo.so) => ffffffffae1335d0 _raw_spin_lock+0x0 (foo.so)
    ->    625ns END   next_uptodate_page
    1439745/1439745 2472089.651285446:                            1   branches:uH:   return               ffffffffae1335e2 _raw_spin_lock+0x12 (foo.so) => ffffffffad83be47 filemap_map_pages+0x387 (foo.so)
    ->    626ns BEGIN _raw_spin_lock
    1439745/1439745 2472089.651285446:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285448:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->    633ns END   _raw_spin_lock
    ->    633ns BEGIN PageHuge
    1439745/1439745 2472089.651285448:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285448:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285450:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->    635ns END   PageHuge
    ->    635ns BEGIN do_set_pte
    ->    636ns BEGIN pfn_pte
    1439745/1439745 2472089.651285451:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    ->    637ns END   pfn_pte
    1439745/1439745 2472089.651285451:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    1439745/1439745 2472089.651285451:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285451:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285454:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->    638ns BEGIN add_mm_counter_fast
    ->    639ns END   add_mm_counter_fast
    ->    639ns BEGIN page_add_file_rmap
    ->    640ns BEGIN lock_page_memcg
    1439745/1439745 2472089.651285454:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285461:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->    641ns END   lock_page_memcg
    ->    641ns BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285461:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285462:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->    648ns BEGIN __mod_lruvec_state
    ->    648ns BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285462:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285462:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285465:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->    649ns END   __mod_node_page_state
    ->    649ns END   __mod_lruvec_state
    ->    649ns BEGIN __mod_memcg_lruvec_state
    ->    650ns BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285466:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->    652ns END   cgroup_rstat_updated
    1439745/1439745 2472089.651285466:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285466:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    1439745/1439745 2472089.651285466:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285467:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->    653ns END   __mod_memcg_lruvec_state
    ->    653ns END   __mod_lruvec_page_state
    ->    653ns BEGIN rcu_read_unlock_strict
    ->    653ns END   rcu_read_unlock_strict
    ->    653ns END   page_add_file_rmap
    ->    653ns BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285467:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    1439745/1439745 2472089.651285467:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285468:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    ->    654ns END   unlock_page_memcg
    ->    654ns BEGIN rcu_read_unlock_strict
    ->    654ns END   rcu_read_unlock_strict
    ->    654ns BEGIN native_set_pte
    1439745/1439745 2472089.651285468:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    1439745/1439745 2472089.651285468:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285473:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->    655ns END   native_set_pte
    ->    655ns END   do_set_pte
    ->    655ns BEGIN unlock_page
    1439745/1439745 2472089.651285474:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->    660ns END   unlock_page
    1439745/1439745 2472089.651285525:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->    661ns BEGIN next_uptodate_page
    1439745/1439745 2472089.651285525:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285526:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->    712ns END   next_uptodate_page
    ->    712ns BEGIN PageHuge
    1439745/1439745 2472089.651285526:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285526:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285529:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->    713ns END   PageHuge
    ->    713ns BEGIN do_set_pte
    ->    714ns BEGIN pfn_pte
    1439745/1439745 2472089.651285529:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    1439745/1439745 2472089.651285530:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->    716ns END   pfn_pte
    ->    716ns BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651285530:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285530:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285533:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->    717ns END   add_mm_counter_fast
    ->    717ns BEGIN page_add_file_rmap
    ->    718ns BEGIN lock_page_memcg
    1439745/1439745 2472089.651285533:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285539:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->    720ns END   lock_page_memcg
    ->    720ns BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285539:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285540:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->    726ns BEGIN __mod_lruvec_state
    ->    726ns BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285540:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285540:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285542:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->    727ns END   __mod_node_page_state
    ->    727ns END   __mod_lruvec_state
    ->    727ns BEGIN __mod_memcg_lruvec_state
    ->    728ns BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285547:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->    729ns END   cgroup_rstat_updated
    1439745/1439745 2472089.651285547:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285548:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    ->    734ns END   __mod_memcg_lruvec_state
    ->    734ns END   __mod_lruvec_page_state
    ->    734ns BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285548:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285549:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->    735ns END   rcu_read_unlock_strict
    ->    735ns END   page_add_file_rmap
    ->    735ns BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285549:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    1439745/1439745 2472089.651285549:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285550:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    ->    736ns END   unlock_page_memcg
    ->    736ns BEGIN rcu_read_unlock_strict
    ->    736ns END   rcu_read_unlock_strict
    ->    736ns BEGIN native_set_pte
    1439745/1439745 2472089.651285551:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    ->    737ns END   native_set_pte
    1439745/1439745 2472089.651285551:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285558:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->    738ns END   do_set_pte
    ->    738ns BEGIN unlock_page
    1439745/1439745 2472089.651285559:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->    745ns END   unlock_page
    1439745/1439745 2472089.651285606:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->    746ns BEGIN next_uptodate_page
    1439745/1439745 2472089.651285606:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285607:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->    793ns END   next_uptodate_page
    ->    793ns BEGIN PageHuge
    1439745/1439745 2472089.651285607:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285607:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285610:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->    794ns END   PageHuge
    ->    794ns BEGIN do_set_pte
    ->    795ns BEGIN pfn_pte
    1439745/1439745 2472089.651285610:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    1439745/1439745 2472089.651285611:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->    797ns END   pfn_pte
    ->    797ns BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651285611:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285611:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285613:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->    798ns END   add_mm_counter_fast
    ->    798ns BEGIN page_add_file_rmap
    ->    799ns BEGIN lock_page_memcg
    1439745/1439745 2472089.651285613:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285619:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->    800ns END   lock_page_memcg
    ->    800ns BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285619:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285621:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->    806ns BEGIN __mod_lruvec_state
    ->    807ns BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285621:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285621:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285623:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->    808ns END   __mod_node_page_state
    ->    808ns END   __mod_lruvec_state
    ->    808ns BEGIN __mod_memcg_lruvec_state
    ->    809ns BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285624:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->    810ns END   cgroup_rstat_updated
    1439745/1439745 2472089.651285624:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285624:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    1439745/1439745 2472089.651285624:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285625:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->    811ns END   __mod_memcg_lruvec_state
    ->    811ns END   __mod_lruvec_page_state
    ->    811ns BEGIN rcu_read_unlock_strict
    ->    811ns END   rcu_read_unlock_strict
    ->    811ns END   page_add_file_rmap
    ->    811ns BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285626:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    ->    812ns END   unlock_page_memcg
    ->    812ns BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285626:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285626:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    1439745/1439745 2472089.651285626:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    1439745/1439745 2472089.651285626:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285631:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->    813ns END   rcu_read_unlock_strict
    ->    813ns BEGIN native_set_pte
    ->    815ns END   native_set_pte
    ->    815ns END   do_set_pte
    ->    815ns BEGIN unlock_page
    1439745/1439745 2472089.651285632:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->    818ns END   unlock_page
    1439745/1439745 2472089.651285685:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->    819ns BEGIN next_uptodate_page
    1439745/1439745 2472089.651285685:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285686:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->    872ns END   next_uptodate_page
    ->    872ns BEGIN PageHuge
    1439745/1439745 2472089.651285686:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285686:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285688:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->    873ns END   PageHuge
    ->    873ns BEGIN do_set_pte
    ->    874ns BEGIN pfn_pte
    1439745/1439745 2472089.651285689:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    ->    875ns END   pfn_pte
    1439745/1439745 2472089.651285690:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->    876ns BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651285690:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285690:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285692:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->    877ns END   add_mm_counter_fast
    ->    877ns BEGIN page_add_file_rmap
    ->    878ns BEGIN lock_page_memcg
    1439745/1439745 2472089.651285692:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285699:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->    879ns END   lock_page_memcg
    ->    879ns BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285699:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285700:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->    886ns BEGIN __mod_lruvec_state
    ->    886ns BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285700:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285700:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285702:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->    887ns END   __mod_node_page_state
    ->    887ns END   __mod_lruvec_state
    ->    887ns BEGIN __mod_memcg_lruvec_state
    ->    888ns BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285703:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->    889ns END   cgroup_rstat_updated
    1439745/1439745 2472089.651285703:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285703:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    1439745/1439745 2472089.651285703:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285704:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->    890ns END   __mod_memcg_lruvec_state
    ->    890ns END   __mod_lruvec_page_state
    ->    890ns BEGIN rcu_read_unlock_strict
    ->    890ns END   rcu_read_unlock_strict
    ->    890ns END   page_add_file_rmap
    ->    890ns BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285705:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    ->    891ns END   unlock_page_memcg
    ->    891ns BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285705:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285705:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    1439745/1439745 2472089.651285705:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    1439745/1439745 2472089.651285705:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285710:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->    892ns END   rcu_read_unlock_strict
    ->    892ns BEGIN native_set_pte
    ->    894ns END   native_set_pte
    ->    894ns END   do_set_pte
    ->    894ns BEGIN unlock_page
    1439745/1439745 2472089.651285711:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->    897ns END   unlock_page
    1439745/1439745 2472089.651285763:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->    898ns BEGIN next_uptodate_page
    1439745/1439745 2472089.651285763:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285765:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->    950ns END   next_uptodate_page
    ->    950ns BEGIN PageHuge
    1439745/1439745 2472089.651285765:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285765:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285767:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->    952ns END   PageHuge
    ->    952ns BEGIN do_set_pte
    ->    953ns BEGIN pfn_pte
    1439745/1439745 2472089.651285767:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    1439745/1439745 2472089.651285768:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->    954ns END   pfn_pte
    ->    954ns BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651285768:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285768:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285770:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->    955ns END   add_mm_counter_fast
    ->    955ns BEGIN page_add_file_rmap
    ->    956ns BEGIN lock_page_memcg
    1439745/1439745 2472089.651285771:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    ->    957ns END   lock_page_memcg
    1439745/1439745 2472089.651285777:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->    958ns BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285777:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285884:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->    964ns BEGIN __mod_lruvec_state
    ->  1.017us BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285884:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285884:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285890:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->  1.071us END   __mod_node_page_state
    ->  1.071us END   __mod_lruvec_state
    ->  1.071us BEGIN __mod_memcg_lruvec_state
    ->  1.074us BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285891:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->  1.077us END   cgroup_rstat_updated
    1439745/1439745 2472089.651285891:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285891:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    1439745/1439745 2472089.651285891:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285893:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->  1.078us END   __mod_memcg_lruvec_state
    ->  1.078us END   __mod_lruvec_page_state
    ->  1.078us BEGIN rcu_read_unlock_strict
    ->  1.079us END   rcu_read_unlock_strict
    ->  1.079us END   page_add_file_rmap
    ->  1.079us BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285895:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    ->   1.08us END   unlock_page_memcg
    ->   1.08us BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285895:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285895:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    1439745/1439745 2472089.651285896:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    ->  1.082us END   rcu_read_unlock_strict
    ->  1.082us BEGIN native_set_pte
    ->  1.083us END   native_set_pte
    1439745/1439745 2472089.651285896:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285917:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->  1.083us END   do_set_pte
    ->  1.083us BEGIN unlock_page
    1439745/1439745 2472089.651285918:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->  1.104us END   unlock_page
    1439745/1439745 2472089.651285942:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->  1.105us BEGIN next_uptodate_page
    1439745/1439745 2472089.651285942:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651285943:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->  1.129us END   next_uptodate_page
    ->  1.129us BEGIN PageHuge
    1439745/1439745 2472089.651285943:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285943:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285945:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->   1.13us END   PageHuge
    ->   1.13us BEGIN do_set_pte
    ->  1.131us BEGIN pfn_pte
    1439745/1439745 2472089.651285945:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    1439745/1439745 2472089.651285946:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->  1.132us END   pfn_pte
    ->  1.132us BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651285946:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651285946:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285948:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->  1.133us END   add_mm_counter_fast
    ->  1.133us BEGIN page_add_file_rmap
    ->  1.134us BEGIN lock_page_memcg
    1439745/1439745 2472089.651285949:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    ->  1.135us END   lock_page_memcg
    1439745/1439745 2472089.651285955:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->  1.136us BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651285955:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651285957:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->  1.142us BEGIN __mod_lruvec_state
    ->  1.143us BEGIN __mod_node_page_state
    1439745/1439745 2472089.651285957:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651285957:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651285958:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->  1.144us END   __mod_node_page_state
    ->  1.144us END   __mod_lruvec_state
    ->  1.144us BEGIN __mod_memcg_lruvec_state
    ->  1.144us BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651285959:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->  1.145us END   cgroup_rstat_updated
    1439745/1439745 2472089.651285959:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651285960:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    ->  1.146us END   __mod_memcg_lruvec_state
    ->  1.146us END   __mod_lruvec_page_state
    ->  1.146us BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651285960:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651285961:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->  1.147us END   rcu_read_unlock_strict
    ->  1.147us END   page_add_file_rmap
    ->  1.147us BEGIN unlock_page_memcg
    1439745/1439745 2472089.651285961:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    1439745/1439745 2472089.651285961:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651285961:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    1439745/1439745 2472089.651285962:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    ->  1.148us END   unlock_page_memcg
    ->  1.148us BEGIN rcu_read_unlock_strict
    ->  1.148us END   rcu_read_unlock_strict
    ->  1.148us BEGIN native_set_pte
    ->  1.149us END   native_set_pte
    1439745/1439745 2472089.651285962:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651285967:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->  1.149us END   do_set_pte
    ->  1.149us BEGIN unlock_page
    1439745/1439745 2472089.651285968:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    ->  1.154us END   unlock_page
    1439745/1439745 2472089.651286019:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->  1.155us BEGIN next_uptodate_page
    1439745/1439745 2472089.651286019:                            1   branches:uH:   call                 ffffffffad83be9d filemap_map_pages+0x3dd (foo.so) => ffffffffad8b49c0 PageHuge+0x0 (foo.so)
    1439745/1439745 2472089.651286020:                            1   branches:uH:   return               ffffffffad8b49ef PageHuge+0x2f (foo.so) => ffffffffad83bea2 filemap_map_pages+0x3e2 (foo.so)
    ->  1.206us END   next_uptodate_page
    ->  1.206us BEGIN PageHuge
    1439745/1439745 2472089.651286020:                            1   branches:uH:   call                 ffffffffad83bf1b filemap_map_pages+0x45b (foo.so) => ffffffffad87d430 do_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651286020:                            1   branches:uH:   call                 ffffffffad87d465 do_set_pte+0x35 (foo.so) => ffffffffad8796a0 pfn_pte+0x0 (foo.so)
    1439745/1439745 2472089.651286023:                            1   branches:uH:   return               ffffffffad8796d5 pfn_pte+0x35 (foo.so) => ffffffffad87d46a do_set_pte+0x3a (foo.so)
    ->  1.207us END   PageHuge
    ->  1.207us BEGIN do_set_pte
    ->  1.208us BEGIN pfn_pte
    1439745/1439745 2472089.651286023:                            1   branches:uH:   call                 ffffffffad87d4b9 do_set_pte+0x89 (foo.so) => ffffffffad879450 add_mm_counter_fast+0x0 (foo.so)
    1439745/1439745 2472089.651286025:                            1   branches:uH:   return               ffffffffad879471 add_mm_counter_fast+0x21 (foo.so) => ffffffffad87d4be do_set_pte+0x8e (foo.so)
    ->   1.21us END   pfn_pte
    ->   1.21us BEGIN add_mm_counter_fast
    1439745/1439745 2472089.651286025:                            1   branches:uH:   call                 ffffffffad87d4c3 do_set_pte+0x93 (foo.so) => ffffffffad892300 page_add_file_rmap+0x0 (foo.so)
    1439745/1439745 2472089.651286025:                            1   branches:uH:   call                 ffffffffad89230e page_add_file_rmap+0xe (foo.so) => ffffffffad8e6ae0 lock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651286027:                            1   branches:uH:   return               ffffffffad8e6b56 lock_page_memcg+0x76 (foo.so) => ffffffffad892313 page_add_file_rmap+0x13 (foo.so)
    ->  1.212us END   add_mm_counter_fast
    ->  1.212us BEGIN page_add_file_rmap
    ->  1.213us BEGIN lock_page_memcg
    1439745/1439745 2472089.651286027:                            1   branches:uH:   call                 ffffffffad89238b page_add_file_rmap+0x8b (foo.so) => ffffffffad8eae80 __mod_lruvec_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651286034:                            1   branches:uH:   call                 ffffffffad8eaedb __mod_lruvec_page_state+0x5b (foo.so) => ffffffffad8eae40 __mod_lruvec_state+0x0 (foo.so)
    ->  1.214us END   lock_page_memcg
    ->  1.214us BEGIN __mod_lruvec_page_state
    1439745/1439745 2472089.651286034:                            1   branches:uH:   call                 ffffffffad8eae5d __mod_lruvec_state+0x1d (foo.so) => ffffffffad860e50 __mod_node_page_state+0x0 (foo.so)
    1439745/1439745 2472089.651286035:                            1   branches:uH:   return               ffffffffad860e9c __mod_node_page_state+0x4c (foo.so) => ffffffffad8eae62 __mod_lruvec_state+0x22 (foo.so)
    ->  1.221us BEGIN __mod_lruvec_state
    ->  1.221us BEGIN __mod_node_page_state
    1439745/1439745 2472089.651286035:                            1   branches:uH:   jmp                  ffffffffad8eae72 __mod_lruvec_state+0x32 (foo.so) => ffffffffad8ea010 __mod_memcg_lruvec_state+0x0 (foo.so)
    1439745/1439745 2472089.651286035:                            1   branches:uH:   call                 ffffffffad8ea04c __mod_memcg_lruvec_state+0x3c (foo.so) => ffffffffad75a340 cgroup_rstat_updated+0x0 (foo.so)
    1439745/1439745 2472089.651286037:                            1   branches:uH:   return               ffffffffad75a36e cgroup_rstat_updated+0x2e (foo.so) => ffffffffad8ea051 __mod_memcg_lruvec_state+0x41 (foo.so)
    ->  1.222us END   __mod_node_page_state
    ->  1.222us END   __mod_lruvec_state
    ->  1.222us BEGIN __mod_memcg_lruvec_state
    ->  1.223us BEGIN cgroup_rstat_updated
    1439745/1439745 2472089.651286038:                            1   branches:uH:   return               ffffffffad8ea081 __mod_memcg_lruvec_state+0x71 (foo.so) => ffffffffad8eaee0 __mod_lruvec_page_state+0x60 (foo.so)
    ->  1.224us END   cgroup_rstat_updated
    1439745/1439745 2472089.651286038:                            1   branches:uH:   jmp                  ffffffffad8eaee5 __mod_lruvec_page_state+0x65 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    1439745/1439745 2472089.651286038:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad892390 page_add_file_rmap+0x90 (foo.so)
    1439745/1439745 2472089.651286038:                            1   branches:uH:   jmp                  ffffffffad892396 page_add_file_rmap+0x96 (foo.so) => ffffffffad8e6270 unlock_page_memcg+0x0 (foo.so)
    1439745/1439745 2472089.651286039:                            1   branches:uH:   jmp                  ffffffffad8e62ad unlock_page_memcg+0x3d (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->  1.225us END   __mod_memcg_lruvec_state
    ->  1.225us END   __mod_lruvec_page_state
    ->  1.225us BEGIN rcu_read_unlock_strict
    ->  1.225us END   rcu_read_unlock_strict
    ->  1.225us END   page_add_file_rmap
    ->  1.225us BEGIN unlock_page_memcg
    1439745/1439745 2472089.651286040:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad87d4c8 do_set_pte+0x98 (foo.so)
    ->  1.226us END   unlock_page_memcg
    ->  1.226us BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651286040:                            1   branches:uH:   call                 ffffffffad87d4d0 do_set_pte+0xa0 (foo.so) => ffffffffad670640 native_set_pte+0x0 (foo.so)
    1439745/1439745 2472089.651286040:                            1   branches:uH:   return               ffffffffad670643 native_set_pte+0x3 (foo.so) => ffffffffad87d4d5 do_set_pte+0xa5 (foo.so)
    1439745/1439745 2472089.651286040:                            1   branches:uH:   return               ffffffffad87d4e1 do_set_pte+0xb1 (foo.so) => ffffffffad83bf20 filemap_map_pages+0x460 (foo.so)
    1439745/1439745 2472089.651286040:                            1   branches:uH:   call                 ffffffffad83bf23 filemap_map_pages+0x463 (foo.so) => ffffffffad839530 unlock_page+0x0 (foo.so)
    1439745/1439745 2472089.651286046:                            1   branches:uH:   return               ffffffffad839549 unlock_page+0x19 (foo.so) => ffffffffad83bf28 filemap_map_pages+0x468 (foo.so)
    ->  1.227us END   rcu_read_unlock_strict
    ->  1.227us BEGIN native_set_pte
    ->   1.23us END   native_set_pte
    ->   1.23us END   do_set_pte
    ->   1.23us BEGIN unlock_page
    1439745/1439745 2472089.651286046:                            1   branches:uH:   call                 ffffffffad83be6c filemap_map_pages+0x3ac (foo.so) => ffffffffadb56bd0 xas_find+0x0 (foo.so)
    1439745/1439745 2472089.651286049:                            1   branches:uH:   return               ffffffffadb56cc9 xas_find+0xf9 (foo.so) => ffffffffad83be71 filemap_map_pages+0x3b1 (foo.so)
    ->  1.233us END   unlock_page
    ->  1.233us BEGIN xas_find
    1439745/1439745 2472089.651286049:                            1   branches:uH:   call                 ffffffffad83be7f filemap_map_pages+0x3bf (foo.so) => ffffffffad83a190 next_uptodate_page+0x0 (foo.so)
    1439745/1439745 2472089.651286050:                            1   branches:uH:   return               ffffffffad83a325 next_uptodate_page+0x195 (foo.so) => ffffffffad83be84 filemap_map_pages+0x3c4 (foo.so)
    ->  1.236us END   xas_find
    ->  1.236us BEGIN next_uptodate_page
    1439745/1439745 2472089.651286051:                            1   branches:uH:   call                 ffffffffad83bbf3 filemap_map_pages+0x133 (foo.so) => ffffffffad717230 rcu_read_unlock_strict+0x0 (foo.so)
    ->  1.237us END   next_uptodate_page
    1439745/1439745 2472089.651286052:                            1   branches:uH:   return               ffffffffad717235 rcu_read_unlock_strict+0x5 (foo.so) => ffffffffad83bbf8 filemap_map_pages+0x138 (foo.so)
    ->  1.238us BEGIN rcu_read_unlock_strict
    1439745/1439745 2472089.651286053:                            1   branches:uH:   return               ffffffffad83bc2d filemap_map_pages+0x16d (foo.so) => ffffffffad880c20 __handle_mm_fault+0xcd0 (foo.so)
    ->  1.239us END   rcu_read_unlock_strict
    1439745/1439745 2472089.651286053:                            1   branches:uH:   return               ffffffffad880368 __handle_mm_fault+0x418 (foo.so) => ffffffffad88154f handle_mm_fault+0xcf (foo.so)
    1439745/1439745 2472089.651286055:                            1   branches:uH:   return               ffffffffad881599 handle_mm_fault+0x119 (foo.so) => ffffffffad67812c do_user_addr_fault+0x1bc (foo.so)
    ->   1.24us END   filemap_map_pages
    ->   1.24us END   __handle_mm_fault
    1439745/1439745 2472089.651286055:                            1   branches:uH:   call                 ffffffffad678144 do_user_addr_fault+0x1d4 (foo.so) => ffffffffad6f5fd0 up_read+0x0 (foo.so)
    1439745/1439745 2472089.651286060:                            1   branches:uH:   return               ffffffffad6f5fef up_read+0x1f (foo.so) => ffffffffad678149 do_user_addr_fault+0x1d9 (foo.so)
    ->  1.242us END   handle_mm_fault
    ->  1.242us BEGIN up_read
    1439745/1439745 2472089.651286061:                            1   branches:uH:   return               ffffffffad677fdb do_user_addr_fault+0x6b (foo.so) => ffffffffae1247c2 exc_page_fault+0x72 (foo.so)
    ->  1.247us END   up_read
    1439745/1439745 2472089.651286061:                            1   branches:uH:   jmp                  ffffffffae1247d6 exc_page_fault+0x86 (foo.so) => ffffffffae124c60 irqentry_exit+0x0 (foo.so)
    1439745/1439745 2472089.651286062:                            1   branches:uH:   jmp                  ffffffffae124c82 irqentry_exit+0x22 (foo.so) => ffffffffae124c50 irqentry_exit_to_user_mode+0x0 (foo.so)
    ->  1.248us END   do_user_addr_fault
    ->  1.248us END   exc_page_fault
    ->  1.248us BEGIN irqentry_exit
    1439745/1439745 2472089.651286062:                            1   branches:uH:   call                 ffffffffae124c50 irqentry_exit_to_user_mode+0x0 (foo.so) => ffffffffad721f00 exit_to_user_mode_prepare+0x0 (foo.so)
    1439745/1439745 2472089.651286071:                            1   branches:uH:   return               ffffffffad721f58 exit_to_user_mode_prepare+0x58 (foo.so) => ffffffffae124c55 irqentry_exit_to_user_mode+0x5 (foo.so)
    ->  1.249us END   irqentry_exit
    ->  1.249us BEGIN irqentry_exit_to_user_mode
    ->  1.253us BEGIN exit_to_user_mode_prepare
    1439745/1439745 2472089.651286071:                            1   branches:uH:   return               ffffffffae124c5e irqentry_exit_to_user_mode+0xe (foo.so) => ffffffffae200ace asm_exc_page_fault+0x1e (foo.so)
    1439745/1439745 2472089.651286071:                            1   branches:uH:   jmp                  ffffffffae200ace asm_exc_page_fault+0x1e (foo.so) => ffffffffae2013f0 error_return+0x0 (foo.so)
    1439745/1439745 2472089.651286072:                            1   branches:uH:   jmp                  ffffffffae2013fe error_return+0xe (foo.so) => ffffffffae200ff0 __irqentry_text_end+0x0 (foo.so)
    ->  1.258us END   exit_to_user_mode_prepare
    ->  1.258us END   irqentry_exit_to_user_mode
    ->  1.258us END   asm_exc_page_fault
    ->  1.258us BEGIN error_return
    1439745/1439745 2472089.651286072:                            1   branches:uH:   jmp                  ffffffffae201073 __irqentry_text_end+0x83 (foo.so) => ffffffffae2010a0 native_iret+0x0 (foo.so)
    1439745/1439745 2472089.651286160:                            1   branches:uH:   iret                 ffffffffae2010a7 native_irq_return_iret+0x0 (foo.so) =>     7f5948676e18 _fini+0x0 (foo.so)
    ->  1.259us END   error_return
    ->  1.259us BEGIN __irqentry_text_end
    ->  1.303us END   __irqentry_text_end
    ->  1.303us BEGIN native_iret
    1439745/1439745 2472089.651286186:                            1   branches:uH:   return                   7f5948676e24 _fini+0xc (foo.so) =>     7f5948832e75 _dl_catch_exception+0xe5 (foo.so)
    ->  1.347us END   native_iret
    INPUT TRACE STREAM ENDED, any lines printed below this were deferred
    ->    224ns BEGIN _dl_catch_exception [inferred start time]
    ->    224ns BEGIN _fini [inferred start time]
    ->  1.373us END   _fini
    ->  1.373us END   _dl_catch_exception
    Warning: perf reported an error decoding the trace: 'Overflow packet (foo.so)' @ IP 0x7f5948676e18.
    ! |}]
;;
