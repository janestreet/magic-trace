open! Core

let%expect_test "golang exit sequence" =
  Perf_script.run ~trace_mode:Userspace "golang_exit.perf";
  [%expect
    {|
    3268985/3268994 3444853.363323631:   call                           439440 runtime.execute+0x80 =>           4365e0 runtime.casgstatus+0x0
    3268985/3268994 3444853.363323637:   return                         4368ab runtime.casgstatus+0x2cb =>           439445 runtime.execute+0x85
    ->      1ns BEGIN runtime.casgstatus
    3268985/3268994 3444853.363323641:   call                           4394e9 runtime.execute+0x129 =>           45e100 runtime.gogo.abi0+0x0
    ->      7ns END   runtime.casgstatus
    3268985/3268994 3444853.363323642:   jmp                            45e10c runtime.gogo.abi0+0xc =>           45d320 gogo+0x0
    ->     11ns BEGIN runtime.gogo.abi0
    3268985/3268994 3444853.363323643:   jmp                            45d35e gogo+0x3e =>           434b36 runtime.gopark+0xd6
    ->     12ns END   runtime.gogo.abi0
    ->     12ns BEGIN gogo
    ->      0ns BEGIN runtime.execute [inferred start time]
    ->     13ns END   gogo
    ->     13ns END   runtime.execute
    3268985/3268994 3444853.363323644:   return                         434b40 runtime.gopark+0xe0 =>           4061cc runtime.chanrecv+0x56c
    ->     13ns BEGIN runtime.gopark
    3268985/3268994 3444853.363323648:   call                           406280 runtime.chanrecv+0x620 =>           434f60 runtime.releaseSudog+0x0
    ->     14ns END   runtime.gopark
    3268985/3268994 3444853.363323652:   return                         4350ce runtime.releaseSudog+0x16e =>           406285 runtime.chanrecv+0x625
    ->     18ns BEGIN runtime.releaseSudog
    3268985/3268994 3444853.363323653:   return                         40629e runtime.chanrecv+0x63e =>           405c38 runtime.chanrecv1+0x18
    ->     22ns END   runtime.releaseSudog
    3268985/3268994 3444853.363323654:   return                         405c41 runtime.chanrecv1+0x21 =>           507a72 main.(*sequencer).GetExitCode+0x92
    ->     23ns END   runtime.chanrecv
    3268985/3268994 3444853.363323655:   return                         507a80 main.(*sequencer).GetExitCode+0xa0 =>           508f0f main.main+0x14f
    ->     24ns END   runtime.chanrecv1
    3268985/3268994 3444853.363323656:   call                           508f0f main.main+0x14f =>           49d300 os.Exit+0x0
    ->     25ns END   main.(*sequencer).GetExitCode
    3268985/3268994 3444853.363323657:   call                           49d320 os.Exit+0x20 =>           495f40 internal/testlog.PanicOnExit0+0x0
    ->     26ns BEGIN os.Exit
    3268985/3268994 3444853.363323659:   call                           495fd9 internal/testlog.PanicOnExit0+0x99 =>           496020 internal/testlog.PanicOnExit0.func1+0x0
    ->     27ns BEGIN internal/testlog.PanicOnExit0
    3268985/3268994 3444853.363323660:   call                           496041 internal/testlog.PanicOnExit0.func1+0x21 =>           465d20 sync.(*Mutex).Unlock+0x0
    ->     29ns BEGIN internal/testlog.PanicOnExit0.func1
    3268985/3268994 3444853.363323662:   return                         465d52 sync.(*Mutex).Unlock+0x32 =>           496046 internal/testlog.PanicOnExit0.func1+0x26
    ->     30ns BEGIN sync.(*Mutex).Unlock
    3268985/3268994 3444853.363323663:   return                         49604f internal/testlog.PanicOnExit0.func1+0x2f =>           495fdb internal/testlog.PanicOnExit0+0x9b
    ->     32ns END   sync.(*Mutex).Unlock
    3268985/3268994 3444853.363323664:   return                         495fe9 internal/testlog.PanicOnExit0+0xa9 =>           49d325 os.Exit+0x25
    ->     33ns END   internal/testlog.PanicOnExit0.func1
    3268985/3268994 3444853.363323665:   call                           49d329 os.Exit+0x29 =>           45bc20 os.runtime_beforeExit+0x0
    ->     34ns END   internal/testlog.PanicOnExit0
    3268985/3268994 3444853.363323666:   return                         45bc20 os.runtime_beforeExit+0x0 =>           49d32e os.Exit+0x2e
    ->     35ns BEGIN os.runtime_beforeExit
    3268985/3268994 3444853.363323667:   call                           49d333 os.Exit+0x33 =>           45c300 syscall.Exit+0x0
    ->     36ns END   os.runtime_beforeExit
    3268985/3268994 3444853.363323668:   call                           45c311 syscall.Exit+0x11 =>           4619e0 runtime.exit.abi0+0x0
    ->     37ns BEGIN syscall.Exit
    3268985/3268994 3444853.363323669:   tr end  syscall                4619e9 runtime.exit.abi0+0x9 =>                0 [unknown]
    ->     38ns BEGIN runtime.exit.abi0
    END
    ->     13ns BEGIN main.main [inferred start time]
    ->     13ns BEGIN main.(*sequencer).GetExitCode [inferred start time]
    ->     13ns BEGIN runtime.chanrecv1 [inferred start time]
    ->     13ns BEGIN runtime.chanrecv [inferred start time]
    ->     39ns BEGIN [syscall]
    ->     39ns END   [syscall]
    ->     39ns END   runtime.exit.abi0
    ->     39ns END   syscall.Exit
    ->     39ns END   os.Exit
    ->     39ns END   main.main |}]
;;
