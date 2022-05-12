open! Core

let%expect_test "an mcall/gogo pair from a small go program" =
  Perf_script.run ~trace_mode:Userspace "simple_gogo.perf";
  [%expect
    {|
    3109264/3109264 3363099.849998148:   tr strt                             0 [unknown] =>           404bf2 runtime.chanrecv+0x372
    3109264/3109264 3363099.849998187:   call                           404de7 runtime.chanrecv+0x567 =>           4307e0 runtime.gopark+0x0
    3109264/3109264 3363099.849998187:   call                           4308b1 runtime.gopark+0xd1 =>           455260 runtime.mcall+0x0
    3109264/3109264 3363099.849998225:   call                           4552a0 runtime.mcall+0x40 =>           436e60 runtime.park_m+0x0
    ->     39ns BEGIN runtime.gopark
    ->     58ns BEGIN runtime.mcall
    3109264/3109264 3363099.849998235:   call                           436eb4 runtime.park_m+0x54 =>           432360 runtime.casgstatus+0x0
    ->     77ns BEGIN runtime.park_m
    3109264/3109264 3363099.849998261:   return                         43262b runtime.casgstatus+0x2cb =>           436eb9 runtime.park_m+0x59
    ->     87ns BEGIN runtime.casgstatus
    3109264/3109264 3363099.849998718:   call                           436f05 runtime.park_m+0xa5 =>           405180 runtime.chanparkcommit+0x0
    ->    113ns END   runtime.casgstatus
    3109264/3109264 3363099.849998831:   call                           4051ab runtime.chanparkcommit+0x2b =>           4094e0 runtime.unlock2+0x0
    ->    570ns BEGIN runtime.chanparkcommit
    3109264/3109264 3363099.849998854:   return                         409548 runtime.unlock2+0x68 =>           4051b0 runtime.chanparkcommit+0x30
    ->    683ns BEGIN runtime.unlock2
    3109264/3109264 3363099.849998854:   return                         4051be runtime.chanparkcommit+0x3e =>           436f07 runtime.park_m+0xa7
    3109264/3109264 3363099.849998866:   call                           436fa8 runtime.park_m+0x148 =>           436820 runtime.schedule+0x0
    ->    706ns END   runtime.unlock2
    ->    706ns END   runtime.chanparkcommit
    3109264/3109264 3363099.850068993:   call                           436872 runtime.schedule+0x52 =>           435140 runtime.execute+0x0
    ->    718ns BEGIN runtime.schedule
    3109264/3109264 3363099.850069069:   call                           4351c0 runtime.execute+0x80 =>           432360 runtime.casgstatus+0x0
    -> 70.845us BEGIN runtime.execute
    3109264/3109264 3363099.850069114:   return                         43262b runtime.casgstatus+0x2cb =>           4351c5 runtime.execute+0x85
    -> 70.921us BEGIN runtime.casgstatus
    3109264/3109264 3363099.850069116:   call                           435269 runtime.execute+0x129 =>           455240 runtime.gogo.abi0+0x0
    -> 70.966us END   runtime.casgstatus
    3109264/3109264 3363099.850069116:   jmp                            45524c runtime.gogo.abi0+0xc =>           454460 gogo+0x0
    3109264/3109264 3363099.850069118:   jmp                            45449e gogo+0x3e =>           4308b6 runtime.gopark+0xd6
    -> 70.968us BEGIN runtime.gogo.abi0
    -> 70.969us END   runtime.gogo.abi0
    -> 70.969us BEGIN gogo
    3109264/3109264 3363099.850069130:   return                         4308c0 runtime.gopark+0xe0 =>           404dec runtime.chanrecv+0x56c
    ->  70.97us END   gogo
    ->  70.97us END   runtime.execute
    ->  70.97us END   runtime.schedule
    ->  70.97us END   runtime.park_m
    ->  70.97us END   runtime.mcall
    3109264/3109264 3363099.850069207:   call                           404ea0 runtime.chanrecv+0x620 =>           430ce0 runtime.releaseSudog+0x0
    -> 70.982us END   runtime.gopark
    3109264/3109264 3363099.850069390:   return                         430e4e runtime.releaseSudog+0x16e =>           404ea5 runtime.chanrecv+0x625
    -> 71.059us BEGIN runtime.releaseSudog
    3109264/3109264 3363099.850069411:   return                         404ebe runtime.chanrecv+0x63e =>           404858 runtime.chanrecv1+0x18
    -> 71.242us END   runtime.releaseSudog
    3109264/3109264 3363099.850069422:   return                         404861 runtime.chanrecv1+0x21 =>           413f76 runtime.gcenable+0xb6
    -> 71.263us END   runtime.chanrecv
    END
    ->      0ns BEGIN runtime.gcenable [inferred start time]
    ->      0ns BEGIN runtime.chanrecv1 [inferred start time]
    ->      0ns BEGIN runtime.chanrecv
    -> 71.274us END   runtime.chanrecv1
    -> 71.274us END   runtime.gcenable |}]
;;
