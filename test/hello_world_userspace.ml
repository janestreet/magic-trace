open! Core

let%expect_test "C hello world, userspace only, musl-gcc -static" =
  Perf_script.run ~trace_mode:Userspace "hello_world_userspace.perf";
  [%expect
    {|
    1342964/1342964 2419667.643226389:   tr strt                             0 [unknown] =>           401032 _start+0x0
    1342964/1342964 2419667.643226725:   tr end                         401032 _start+0x0 =>                0 [unknown]
    1342964/1342964 2419667.643235265:   tr strt                             0 [unknown] =>           401032 _start+0x0
    ->    336ns BEGIN [untraced]
    1342964/1342964 2419667.643235265:   call                           401043 _start+0x11 =>           401048 _start_c+0x0
    1342964/1342964 2419667.643235265:   jmp                            401066 _start_c+0x1e =>           401329 __libc_start_main+0x0
    1342964/1342964 2419667.643235265:   call                           401346 __libc_start_main+0x1d =>           401155 __init_libc+0x0
    1342964/1342964 2419667.643236396:   call                           401223 __init_libc+0xce =>           401507 __init_tls+0x0
    ->  8.876us END   [untraced]
    ->  8.876us BEGIN _start_c
    ->  9.253us END   _start_c
    ->  9.253us BEGIN __libc_start_main
    ->   9.63us BEGIN __init_libc
    1342964/1342964 2419667.643236766:   tr end                         401525 __init_tls+0x1e =>                0 [unknown]
    -> 10.007us BEGIN __init_tls
    1342964/1342964 2419667.643237608:   tr strt                             0 [unknown] =>           401525 __init_tls+0x1e
    -> 10.377us BEGIN [untraced]
    1342964/1342964 2419667.643237790:   call                           40166f __init_tls+0x168 =>           40148e __copy_tls+0x0
    -> 11.219us END   [untraced]
    1342964/1342964 2419667.643237800:   return                         401506 __copy_tls+0x78 =>           401674 __init_tls+0x16d
    -> 11.401us BEGIN __copy_tls
    1342964/1342964 2419667.643237800:   call                           401677 __init_tls+0x170 =>           401423 __init_tp+0x0
    1342964/1342964 2419667.643237800:   call                           40142a __init_tp+0x7 =>           401b1f __set_thread_area+0x0
    1342964/1342964 2419667.643237813:   tr end  syscall                401b2c __set_thread_area+0xd =>                0 [unknown]
    -> 11.411us END   __copy_tls
    -> 11.411us BEGIN __init_tp
    -> 11.417us BEGIN __set_thread_area
    1342964/1342964 2419667.643238308:   tr strt                             0 [unknown] =>           401b2e __set_thread_area+0xf
    -> 11.424us BEGIN [syscall]
    1342964/1342964 2419667.643238310:   return                         401b2e __set_thread_area+0xf =>           40142f __init_tp+0xc
    -> 11.919us END   [syscall]
    1342964/1342964 2419667.643238326:   tr end  syscall                401456 __init_tp+0x33 =>                0 [unknown]
    -> 11.921us END   __set_thread_area
    1342964/1342964 2419667.643238684:   tr strt                             0 [unknown] =>           401458 __init_tp+0x35
    -> 11.937us BEGIN [syscall]
    1342964/1342964 2419667.643238686:   return                         40148d __init_tp+0x6a =>           40167c __init_tls+0x175
    -> 12.295us END   [syscall]
    1342964/1342964 2419667.643238693:   return                         401682 __init_tls+0x17b =>           401228 __init_libc+0xd3
    -> 12.297us END   __init_tp
    1342964/1342964 2419667.643238693:   call                           401230 __init_libc+0xdb =>           401b44 __init_ssp+0x0
    1342964/1342964 2419667.643238695:   call                           401b5c __init_ssp+0x18 =>           401aed memcpy+0x0
    -> 12.304us END   __init_tls
    -> 12.304us BEGIN __init_ssp
    1342964/1342964 2419667.643238828:   return                         401b1e memcpy+0x31 =>           401b61 __init_ssp+0x1d
    -> 12.306us BEGIN memcpy
    1342964/1342964 2419667.643238832:   return                         401b7e __init_ssp+0x3a =>           401235 __init_libc+0xe0
    -> 12.439us END   memcpy
    1342964/1342964 2419667.643238839:   return                         4012da __init_libc+0x185 =>           40134b __libc_start_main+0x22
    -> 12.443us END   __init_ssp
    1342964/1342964 2419667.643238843:   jmp                            401363 __libc_start_main+0x3a =>           4012fb libc_start_main_stage2+0x0
    ->  12.45us END   __init_libc
    1342964/1342964 2419667.643238843:   call                           401313 libc_start_main_stage2+0x18 =>           4012db __libc_start_init+0x0
    1342964/1342964 2419667.643238843:   call                           4012dc __libc_start_init+0x1 =>           401000 [unknown]
    1342964/1342964 2419667.643238856:   return                         401002 [unknown] =>           4012e1 __libc_start_init+0x6
    -> 12.454us END   __libc_start_main
    -> 12.454us BEGIN libc_start_main_stage2
    -> 12.458us BEGIN __libc_start_init
    -> 12.462us BEGIN [unknown]
    1342964/1342964 2419667.643239005:   tr end                         4012f1 __libc_start_init+0x16 =>                0 [unknown]
    -> 12.467us END   [unknown]
    1342964/1342964 2419667.643239993:   tr strt                             0 [unknown] =>           4012f1 __libc_start_init+0x16
    -> 12.616us BEGIN [untraced]
    1342964/1342964 2419667.643240109:   call                           4012f1 __libc_start_init+0x16 =>           401130 frame_dummy+0x0
    -> 13.604us END   [untraced]
    1342964/1342964 2419667.643240109:   jmp                            401134 frame_dummy+0x4 =>           4010a0 register_tm_clones+0x0
    1342964/1342964 2419667.643240127:   return                         4010d8 register_tm_clones+0x38 =>           4012f3 __libc_start_init+0x18
    ->  13.72us BEGIN frame_dummy
    -> 13.729us END   frame_dummy
    -> 13.729us BEGIN register_tm_clones
    1342964/1342964 2419667.643240139:   return                         4012fa __libc_start_init+0x1f =>           401318 libc_start_main_stage2+0x1d
    -> 13.738us END   register_tm_clones
    1342964/1342964 2419667.643240142:   call                           401320 libc_start_main_stage2+0x25 =>           401139 main+0x0
    ->  13.75us END   __libc_start_init
    1342964/1342964 2419667.643240142:   call                           401147 main+0xe =>           401389 puts+0x0
    1342964/1342964 2419667.643240256:   call                           4013b7 puts+0x2e =>           4018f9 fputs+0x0
    -> 13.753us BEGIN main
    ->  13.81us BEGIN puts
    1342964/1342964 2419667.643240256:   call                           401908 fputs+0xf =>           401a70 strlen+0x0
    1342964/1342964 2419667.643241194:   tr end                         401aa2 strlen+0x32 =>                0 [unknown]
    -> 13.867us BEGIN fputs
    -> 14.336us BEGIN strlen
    1342964/1342964 2419667.643241746:   tr strt                             0 [unknown] =>           401aa2 strlen+0x32
    -> 14.805us BEGIN [untraced]
    1342964/1342964 2419667.643241887:   return                         401aec strlen+0x7c =>           40190d fputs+0x14
    -> 15.357us END   [untraced]
    1342964/1342964 2419667.643241887:   call                           401920 fputs+0x27 =>           4019e6 fwrite+0x0
    1342964/1342964 2419667.643241888:   call                           401a2f fwrite+0x49 =>           401938 __fwritex+0x0
    -> 15.498us END   strlen
    -> 15.498us BEGIN fwrite
    1342964/1342964 2419667.643241888:   call                           401977 __fwritex+0x3f =>           4018ad __towrite+0x0
    1342964/1342964 2419667.643242024:   return                         4018f3 __towrite+0x46 =>           40197c __fwritex+0x44
    -> 15.499us BEGIN __fwritex
    -> 15.567us BEGIN __towrite
    1342964/1342964 2419667.643242054:   call                           4019b3 __fwritex+0x7b =>           401aed memcpy+0x0
    -> 15.635us END   __towrite
    1342964/1342964 2419667.643242215:   return                         401b1e memcpy+0x31 =>           4019b8 __fwritex+0x80
    -> 15.665us BEGIN memcpy
    1342964/1342964 2419667.643242217:   return                         4019e5 __fwritex+0xad =>           401a34 fwrite+0x4e
    -> 15.826us END   memcpy
    1342964/1342964 2419667.643242218:   return                         401a62 fwrite+0x7c =>           401925 fputs+0x2c
    -> 15.828us END   __fwritex
    1342964/1342964 2419667.643242219:   return                         401937 fputs+0x3e =>           4013bc puts+0x33
    -> 15.829us END   fwrite
    1342964/1342964 2419667.643242219:   call                           4013fc puts+0x73 =>           401783 __overflow+0x0
    1342964/1342964 2419667.643242223:   call                           4017e7 __overflow+0x64 =>           401837 __stdout_write+0x0
    ->  15.83us END   fputs
    ->  15.83us BEGIN __overflow
    1342964/1342964 2419667.643242235:   tr end  syscall                401873 __stdout_write+0x3c =>                0 [unknown]
    -> 15.834us BEGIN __stdout_write
    1342964/1342964 2419667.643244717:   tr strt                             0 [unknown] =>           401875 __stdout_write+0x3e
    -> 15.846us BEGIN [syscall]
    1342964/1342964 2419667.643244718:   call                           40188e __stdout_write+0x57 =>           401c52 __stdio_write+0x0
    -> 18.328us END   [syscall]
    1342964/1342964 2419667.643244738:   tr end  syscall                401cb1 __stdio_write+0x5f =>                0 [unknown]
    -> 18.329us BEGIN __stdio_write
    1342964/1342964 2419667.643253111:   tr strt                             0 [unknown] =>           401cb3 __stdio_write+0x61
    -> 18.349us BEGIN [syscall]
    1342964/1342964 2419667.643253111:   call                           401cb6 __stdio_write+0x64 =>           401b90 __syscall_ret+0x0
    1342964/1342964 2419667.643253117:   return                         401b9c __syscall_ret+0xc =>           401cbb __stdio_write+0x69
    -> 26.722us END   [syscall]
    -> 26.722us BEGIN __syscall_ret
    1342964/1342964 2419667.643253137:   return                         401d51 __stdio_write+0xff =>           401893 __stdout_write+0x5c
    -> 26.728us END   __syscall_ret
    1342964/1342964 2419667.643253157:   return                         4018ac __stdout_write+0x75 =>           4017ea __overflow+0x67
    -> 26.748us END   __stdio_write
    1342964/1342964 2419667.643253169:   return                         40180e __overflow+0x8b =>           401401 puts+0x78
    -> 26.768us END   __stdout_write
    1342964/1342964 2419667.643253187:   return                         401422 puts+0x99 =>           40114c main+0x13
    ->  26.78us END   __overflow
    1342964/1342964 2419667.643253197:   return                         401152 main+0x19 =>           401322 libc_start_main_stage2+0x27
    -> 26.798us END   puts
    1342964/1342964 2419667.643253197:   call                           401324 libc_start_main_stage2+0x29 =>           401010 exit+0x0
    1342964/1342964 2419667.643253197:   call                           401018 exit+0x8 =>           401365 __funcs_on_exit+0x0
    1342964/1342964 2419667.643253215:   return                         401365 __funcs_on_exit+0x0 =>           40101d exit+0xd
    -> 26.808us END   main
    -> 26.808us BEGIN exit
    -> 26.817us BEGIN __funcs_on_exit
    1342964/1342964 2419667.643253215:   call                           40101d exit+0xd =>           401366 __libc_exit_fini+0x0
    1342964/1342964 2419667.643253224:   call                           40137d __libc_exit_fini+0x17 =>           4010e0 __do_global_dtors_aux+0x0
    -> 26.826us END   __funcs_on_exit
    -> 26.826us BEGIN __libc_exit_fini
    1342964/1342964 2419667.643253235:   call                           401108 __do_global_dtors_aux+0x28 =>           401070 deregister_tm_clones+0x0
    -> 26.835us BEGIN __do_global_dtors_aux
    1342964/1342964 2419667.643253260:   return                         401098 deregister_tm_clones+0x28 =>           40110d __do_global_dtors_aux+0x2d
    -> 26.846us BEGIN deregister_tm_clones
    1342964/1342964 2419667.643253264:   return                         401115 __do_global_dtors_aux+0x35 =>           40137f __libc_exit_fini+0x19
    -> 26.871us END   deregister_tm_clones
    1342964/1342964 2419667.643253269:   jmp                            401384 __libc_exit_fini+0x1e =>           401e6e __errno_location+0xe
    -> 26.875us END   __do_global_dtors_aux
    1342964/1342964 2419667.643253280:   return                         401e70 __errno_location+0x10 =>           401022 exit+0x12
    ->  26.88us END   __libc_exit_fini
    ->  26.88us BEGIN __errno_location
    1342964/1342964 2419667.643253280:   call                           401024 exit+0x14 =>           401c11 __stdio_exit_needed+0x0
    1342964/1342964 2419667.643253280:   call                           401c12 __stdio_exit_needed+0x1 =>           401d52 __ofl_lock+0x0
    1342964/1342964 2419667.643253280:   call                           401d5a __ofl_lock+0x8 =>           401d74 __lock+0x0
    1342964/1342964 2419667.643253300:   return                         401e25 __lock+0xb1 =>           401d5f __ofl_lock+0xd
    -> 26.891us END   __errno_location
    -> 26.891us BEGIN __stdio_exit_needed
    -> 26.897us BEGIN __ofl_lock
    -> 26.904us BEGIN __lock
    1342964/1342964 2419667.643253304:   return                         401d67 __ofl_lock+0x15 =>           401c17 __stdio_exit_needed+0x6
    -> 26.911us END   __lock
    1342964/1342964 2419667.643253307:   call                           401c34 __stdio_exit_needed+0x23 =>           401bc3 close_file+0x0
    -> 26.915us END   __ofl_lock
    1342964/1342964 2419667.643253320:   return                         401c10 close_file+0x4d =>           401c39 __stdio_exit_needed+0x28
    -> 26.918us BEGIN close_file
    1342964/1342964 2419667.643253320:   call                           401c40 __stdio_exit_needed+0x2f =>           401bc3 close_file+0x0
    1342964/1342964 2419667.643253372:   return                         401c0f close_file+0x4c =>           401c45 __stdio_exit_needed+0x34
    -> 26.931us END   close_file
    -> 26.931us BEGIN close_file
    1342964/1342964 2419667.643253372:   jmp                            401c4d __stdio_exit_needed+0x3c =>           401bc3 close_file+0x0
    1342964/1342964 2419667.643253376:   return                         401c10 close_file+0x4d =>           401029 exit+0x19
    -> 26.983us END   close_file
    -> 26.983us END   __stdio_exit_needed
    -> 26.983us BEGIN close_file
    1342964/1342964 2419667.643253376:   call                           40102d exit+0x1d =>           401683 _Exit+0x0
    1342964/1342964 2419667.643253389:   tr end  syscall                40168b _Exit+0x8 =>                0 [unknown]
    -> 26.987us END   close_file
    -> 26.987us BEGIN _Exit
    END
    ->      0ns BEGIN _start
    ->     27us BEGIN [syscall]
    ->     27us END   [syscall]
    ->     27us END   _Exit
    ->     27us END   exit
    ->     27us END   libc_start_main_stage2
    ->     27us END   _start |}]
;;
