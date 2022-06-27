open! Core
open! Async

let%expect_test "an mcall/gogo pair from a small go program" =
  let%map () = Perf_script.run ~trace_scope:Userspace "simple_gogo.perf" in
  [%expect
    {|
    3109264/3109264 3363099.849998148:                            1   branches:uH:   tr strt                             0 [unknown] (foo.so) =>           404bf2 runtime.chanrecv+0x372 (foo.so)
    3109264/3109264 3363099.849998187:                            1   branches:uH:   call                           404de7 runtime.chanrecv+0x567 (foo.so) =>           4307e0 runtime.gopark+0x0 (foo.so)
    3109264/3109264 3363099.849998187:                            1   branches:uH:   call                           4308b1 runtime.gopark+0xd1 (foo.so) =>           455260 runtime.mcall+0x0 (foo.so)
    3109264/3109264 3363099.849998225:                            1   branches:uH:   call                           4552a0 runtime.mcall+0x40 (foo.so) =>           436e60 runtime.park_m+0x0 (foo.so)
    ->     39ns BEGIN runtime.gopark
    ->     58ns BEGIN runtime.mcall
    3109264/3109264 3363099.849998235:                            1   branches:uH:   call                           436eb4 runtime.park_m+0x54 (foo.so) =>           432360 runtime.casgstatus+0x0 (foo.so)
    ->     77ns BEGIN runtime.park_m
    3109264/3109264 3363099.849998261:                            1   branches:uH:   return                         43262b runtime.casgstatus+0x2cb (foo.so) =>           436eb9 runtime.park_m+0x59 (foo.so)
    ->     87ns BEGIN runtime.casgstatus
    3109264/3109264 3363099.849998718:                            1   branches:uH:   call                           436f05 runtime.park_m+0xa5 (foo.so) =>           405180 runtime.chanparkcommit+0x0 (foo.so)
    ->    113ns END   runtime.casgstatus
    3109264/3109264 3363099.849998831:                            1   branches:uH:   call                           4051ab runtime.chanparkcommit+0x2b (foo.so) =>           4094e0 runtime.unlock2+0x0 (foo.so)
    ->    570ns BEGIN runtime.chanparkcommit
    3109264/3109264 3363099.849998854:                            1   branches:uH:   return                         409548 runtime.unlock2+0x68 (foo.so) =>           4051b0 runtime.chanparkcommit+0x30 (foo.so)
    ->    683ns BEGIN runtime.unlock2
    3109264/3109264 3363099.849998854:                            1   branches:uH:   return                         4051be runtime.chanparkcommit+0x3e (foo.so) =>           436f07 runtime.park_m+0xa7 (foo.so)
    3109264/3109264 3363099.849998866:                            1   branches:uH:   call                           436fa8 runtime.park_m+0x148 (foo.so) =>           436820 runtime.schedule+0x0 (foo.so)
    ->    706ns END   runtime.unlock2
    ->    706ns END   runtime.chanparkcommit
    3109264/3109264 3363099.850068993:                            1   branches:uH:   call                           436872 runtime.schedule+0x52 (foo.so) =>           435140 runtime.execute+0x0 (foo.so)
    ->    718ns BEGIN runtime.schedule
    3109264/3109264 3363099.850069069:                            1   branches:uH:   call                           4351c0 runtime.execute+0x80 (foo.so) =>           432360 runtime.casgstatus+0x0 (foo.so)
    -> 70.845us BEGIN runtime.execute
    3109264/3109264 3363099.850069114:                            1   branches:uH:   return                         43262b runtime.casgstatus+0x2cb (foo.so) =>           4351c5 runtime.execute+0x85 (foo.so)
    -> 70.921us BEGIN runtime.casgstatus
    3109264/3109264 3363099.850069116:                            1   branches:uH:   call                           435269 runtime.execute+0x129 (foo.so) =>           455240 runtime.gogo.abi0+0x0 (foo.so)
    -> 70.966us END   runtime.casgstatus
    3109264/3109264 3363099.850069116:                            1   branches:uH:   jmp                            45524c runtime.gogo.abi0+0xc (foo.so) =>           454460 gogo+0x0 (foo.so)
    3109264/3109264 3363099.850069118:                            1   branches:uH:   jmp                            45449e gogo+0x3e (foo.so) =>           4308b6 runtime.gopark+0xd6 (foo.so)
    -> 70.968us BEGIN runtime.gogo.abi0
    -> 70.969us END   runtime.gogo.abi0
    -> 70.969us BEGIN gogo
    3109264/3109264 3363099.850069130:                            1   branches:uH:   return                         4308c0 runtime.gopark+0xe0 (foo.so) =>           404dec runtime.chanrecv+0x56c (foo.so)
    ->  70.97us END   gogo
    ->  70.97us END   runtime.execute
    ->  70.97us END   runtime.schedule
    ->  70.97us END   runtime.park_m
    ->  70.97us END   runtime.mcall
    ->  70.97us END   runtime.gopark
    ->  70.97us BEGIN runtime.gopark
    3109264/3109264 3363099.850069207:                            1   branches:uH:   call                           404ea0 runtime.chanrecv+0x620 (foo.so) =>           430ce0 runtime.releaseSudog+0x0 (foo.so)
    -> 70.982us END   runtime.gopark
    3109264/3109264 3363099.850069390:                            1   branches:uH:   return                         430e4e runtime.releaseSudog+0x16e (foo.so) =>           404ea5 runtime.chanrecv+0x625 (foo.so)
    -> 71.059us BEGIN runtime.releaseSudog
    3109264/3109264 3363099.850069411:                            1   branches:uH:   return                         404ebe runtime.chanrecv+0x63e (foo.so) =>           404858 runtime.chanrecv1+0x18 (foo.so)
    -> 71.242us END   runtime.releaseSudog
    3109264/3109264 3363099.850069422:                            1   branches:uH:   return                         404861 runtime.chanrecv1+0x21 (foo.so) =>           413f76 runtime.gcenable+0xb6 (foo.so)
    -> 71.263us END   runtime.chanrecv
    END
    ->      0ns BEGIN runtime.gcenable [inferred start time]
    ->      0ns BEGIN runtime.chanrecv1 [inferred start time]
    ->      0ns BEGIN runtime.chanrecv
    -> 71.274us END   runtime.chanrecv1
    -> 71.274us END   runtime.gcenable |}]
;;
