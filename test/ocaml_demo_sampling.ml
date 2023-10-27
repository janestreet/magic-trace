open! Core
open! Async

let%expect_test "A raise_notrace OCaml exception" =
  let%map () = Perf_script.run ~trace_scope:Userspace "ocaml_demo_sampling.perf" in
  [%expect
    {|
    (lines
     ("728783/728783 336962.964016127:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.964267497:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 50.274us BEGIN Stdlib.output_254
    -> 100.548us BEGIN caml_ml_output_bytes
    -> 150.822us BEGIN caml_putblock
    -> 201.096us BEGIN memmove@plt
    (lines
     ("728783/728783 336962.964517048:       1 cycles:u: "
      "\t          430a30 caml_putblock+0x0 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 251.37us END   memmove@plt
    -> 251.37us END   caml_putblock
    -> 251.37us END   caml_ml_output_bytes
    -> 251.37us END   Stdlib.output_254
    -> 251.37us END   Demo3.code_begin
    -> 251.37us BEGIN Demo3.code_begin
    -> 313.757us BEGIN Stdlib.input_299
    -> 376.145us BEGIN caml_ml_input
    -> 438.533us BEGIN memmove@plt
    (lines
     ("728783/728783 336962.964766536:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431bcd caml_ml_input+0x18d (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 500.921us END   memmove@plt
    -> 500.921us END   caml_ml_input
    -> 500.921us END   Stdlib.input_299
    -> 500.921us END   Demo3.code_begin
    -> 500.921us BEGIN Demo3.code_begin
    -> 563.293us BEGIN Stdlib.output_254
    -> 625.665us BEGIN caml_ml_output_bytes
    -> 688.037us BEGIN caml_putblock
    (lines
     ("728783/728783 336962.965016175:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431bcd caml_ml_input+0x18d (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.965264931:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 750.409us END   caml_putblock
    -> 750.409us END   caml_ml_output_bytes
    -> 750.409us END   Stdlib.output_254
    -> 750.409us END   Demo3.code_begin
    -> 750.409us BEGIN Demo3.code_begin
    -> 875.007us BEGIN Stdlib.input_299
    -> 999.606us BEGIN caml_ml_input
    ->  1.124ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.965514544:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.965764025:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.966013826:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  1.249ms END   memmove@plt
    ->  1.249ms END   caml_ml_input
    ->  1.249ms BEGIN caml_ml_input
    ->  1.623ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.966265372:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  1.998ms END   memmove@plt
    ->  1.998ms END   caml_ml_input
    ->  1.998ms END   Stdlib.input_299
    ->  1.998ms END   Demo3.code_begin
    ->  1.998ms BEGIN Demo3.code_begin
    ->  2.048ms BEGIN Stdlib.output_254
    ->  2.098ms BEGIN caml_ml_output_bytes
    ->  2.149ms BEGIN caml_putblock
    ->  2.199ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.966514974:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.966764709:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  2.249ms END   memmove@plt
    ->  2.249ms END   caml_putblock
    ->  2.249ms END   caml_ml_output_bytes
    ->  2.249ms END   Stdlib.output_254
    ->  2.249ms END   Demo3.code_begin
    ->  2.249ms BEGIN Demo3.code_begin
    ->  2.374ms BEGIN Stdlib.input_299
    ->  2.499ms BEGIN caml_ml_input
    ->  2.624ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.967014349:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  2.749ms END   memmove@plt
    ->  2.749ms END   caml_ml_input
    ->  2.749ms END   Stdlib.input_299
    ->  2.749ms END   Demo3.code_begin
    ->  2.749ms BEGIN Demo3.code_begin
    ->  2.799ms BEGIN Stdlib.output_254
    ->  2.848ms BEGIN caml_ml_output_bytes
    ->  2.898ms BEGIN caml_putblock
    ->  2.948ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.967266105:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.967515769:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.967765173:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.968014722:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.968265955:       1 cycles:u: "
      "\t          44198c caml_c_call+0x0 (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  2.998ms END   memmove@plt
    ->  2.998ms END   caml_putblock
    ->  2.998ms END   caml_ml_output_bytes
    ->  2.998ms END   Stdlib.output_254
    ->  2.998ms END   Demo3.code_begin
    ->  2.998ms BEGIN Demo3.code_begin
    ->  3.311ms BEGIN Stdlib.input_299
    ->  3.624ms BEGIN caml_ml_input
    ->  3.937ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.968515684:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->   4.25ms END   memmove@plt
    ->   4.25ms END   caml_ml_input
    ->   4.25ms END   Stdlib.input_299
    ->   4.25ms END   Demo3.code_begin
    ->   4.25ms BEGIN Demo3.code_begin
    ->  4.333ms BEGIN Stdlib.output_254
    ->  4.416ms BEGIN caml_c_call
    (lines
     ("728783/728783 336962.968765194:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.969014825:       1 cycles:u: "
      "\t          4269f0 caml_check_pending_actions+0x0 (/usr/local/demo4)"
      "\t          43056c check_pending+0xc (/usr/local/demo4)"
      "\t          431b16 caml_ml_input+0xd6 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->    4.5ms END   caml_c_call
    ->    4.5ms END   Stdlib.output_254
    ->    4.5ms END   Demo3.code_begin
    ->    4.5ms BEGIN Demo3.code_begin
    ->  4.624ms BEGIN Stdlib.input_299
    ->  4.749ms BEGIN caml_ml_input
    ->  4.874ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.969266373:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  4.999ms END   memmove@plt
    ->  4.999ms END   caml_ml_input
    ->  4.999ms BEGIN caml_ml_input
    ->  5.083ms BEGIN check_pending
    ->  5.166ms BEGIN caml_check_pending_actions
    (lines
     ("728783/728783 336962.969516038:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.969765549:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->   5.25ms END   caml_check_pending_actions
    ->   5.25ms END   check_pending
    ->   5.25ms END   caml_ml_input
    ->   5.25ms BEGIN caml_ml_input
    ->    5.5ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.970015619:       1 cycles:u: "
      "\t          426630 caml_leave_blocking_section+0x0 (/usr/local/demo4)"
      "\t          438192 caml_write_fd+0x32 (/usr/local/demo4)"
      "\t          430850 caml_flush_partial+0x20 (/usr/local/demo4)"
      "\t          430a96 caml_putblock+0x66 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  5.749ms END   memmove@plt
    ->  5.749ms END   caml_ml_input
    ->  5.749ms END   Stdlib.input_299
    ->  5.749ms END   Demo3.code_begin
    ->  5.749ms BEGIN Demo3.code_begin
    ->  5.799ms BEGIN Stdlib.output_254
    ->  5.849ms BEGIN caml_ml_output_bytes
    ->  5.899ms BEGIN caml_putblock
    ->  5.949ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.970266467:       1 cycles:u: "
      "\t          419f80 Stdlib.output_254+0x0 (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  5.999ms END   memmove@plt
    ->  5.999ms END   caml_putblock
    ->  5.999ms BEGIN caml_putblock
    ->  6.062ms BEGIN caml_flush_partial
    ->  6.125ms BEGIN caml_write_fd
    ->  6.188ms BEGIN caml_leave_blocking_section
    (lines
     ("728783/728783 336962.970515690:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->   6.25ms END   caml_leave_blocking_section
    ->   6.25ms END   caml_write_fd
    ->   6.25ms END   caml_flush_partial
    ->   6.25ms END   caml_putblock
    ->   6.25ms END   caml_ml_output_bytes
    ->   6.25ms END   Stdlib.output_254
    ->   6.25ms BEGIN Stdlib.output_254
    (lines
     ("728783/728783 336962.970767578:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->    6.5ms END   Stdlib.output_254
    ->    6.5ms END   Demo3.code_begin
    ->    6.5ms BEGIN Demo3.code_begin
    ->  6.563ms BEGIN Stdlib.input_299
    ->  6.626ms BEGIN caml_ml_input
    ->  6.688ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.971016839:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  6.751ms END   memmove@plt
    ->  6.751ms END   caml_ml_input
    ->  6.751ms END   Stdlib.input_299
    ->  6.751ms END   Demo3.code_begin
    ->  6.751ms BEGIN Demo3.code_begin
    ->  6.801ms BEGIN Stdlib.output_254
    ->  6.851ms BEGIN caml_ml_output_bytes
    ->  6.901ms BEGIN caml_putblock
    ->  6.951ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.971265907:       1 cycles:u: "
      "\t          430830 caml_flush_partial+0x0 (/usr/local/demo4)"
      "\t          430a96 caml_putblock+0x66 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  7.001ms END   memmove@plt
    ->  7.001ms END   caml_putblock
    ->  7.001ms END   caml_ml_output_bytes
    ->  7.001ms END   Stdlib.output_254
    ->  7.001ms END   Demo3.code_begin
    ->  7.001ms BEGIN Demo3.code_begin
    ->  7.063ms BEGIN Stdlib.input_299
    ->  7.125ms BEGIN caml_ml_input
    ->  7.188ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.971515155:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->   7.25ms END   memmove@plt
    ->   7.25ms END   caml_ml_input
    ->   7.25ms END   Stdlib.input_299
    ->   7.25ms END   Demo3.code_begin
    ->   7.25ms BEGIN Demo3.code_begin
    ->    7.3ms BEGIN Stdlib.output_254
    ->  7.349ms BEGIN caml_ml_output_bytes
    ->  7.399ms BEGIN caml_putblock
    ->  7.449ms BEGIN caml_flush_partial
    (lines
     ("728783/728783 336962.971764930:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  7.499ms END   caml_flush_partial
    ->  7.499ms END   caml_putblock
    ->  7.499ms END   caml_ml_output_bytes
    ->  7.499ms END   Stdlib.output_254
    ->  7.499ms END   Demo3.code_begin
    ->  7.499ms BEGIN Demo3.code_begin
    ->  7.561ms BEGIN Stdlib.input_299
    ->  7.624ms BEGIN caml_ml_input
    ->  7.686ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.972014538:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  7.749ms END   memmove@plt
    ->  7.749ms END   caml_ml_input
    ->  7.749ms END   Stdlib.input_299
    ->  7.749ms END   Demo3.code_begin
    ->  7.749ms BEGIN Demo3.code_begin
    ->  7.799ms BEGIN Stdlib.output_254
    ->  7.849ms BEGIN caml_ml_output_bytes
    ->  7.899ms BEGIN caml_putblock
    ->  7.948ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.972266075:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  7.998ms END   memmove@plt
    ->  7.998ms END   caml_putblock
    ->  7.998ms END   caml_ml_output_bytes
    ->  7.998ms END   Stdlib.output_254
    ->  7.998ms END   Demo3.code_begin
    ->  7.998ms BEGIN Demo3.code_begin
    ->  8.061ms BEGIN Stdlib.input_299
    ->  8.124ms BEGIN caml_ml_input
    ->  8.187ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.972515767:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->   8.25ms END   memmove@plt
    ->   8.25ms END   caml_ml_input
    ->   8.25ms END   Stdlib.input_299
    ->   8.25ms END   Demo3.code_begin
    ->   8.25ms BEGIN Demo3.code_begin
    ->    8.3ms BEGIN Stdlib.output_254
    ->   8.35ms BEGIN caml_ml_output_bytes
    ->    8.4ms BEGIN caml_putblock
    ->   8.45ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.972765110:       1 cycles:u: "
      "\t          44198c caml_c_call+0x0 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->    8.5ms END   memmove@plt
    ->    8.5ms END   caml_putblock
    ->    8.5ms END   caml_ml_output_bytes
    ->    8.5ms END   Stdlib.output_254
    ->    8.5ms END   Demo3.code_begin
    ->    8.5ms BEGIN Demo3.code_begin
    ->  8.562ms BEGIN Stdlib.input_299
    ->  8.624ms BEGIN caml_ml_input
    ->  8.687ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.973014704:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  8.749ms END   memmove@plt
    ->  8.749ms END   caml_ml_input
    ->  8.749ms BEGIN caml_c_call
    (lines
     ("728783/728783 336962.973266193:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.973515725:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.973765371:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  8.999ms END   caml_c_call
    ->  8.999ms BEGIN caml_ml_input
    ->  9.374ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.974015233:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.974266621:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  9.749ms END   memmove@plt
    ->  9.749ms END   caml_ml_input
    ->  9.749ms END   Stdlib.input_299
    ->  9.749ms END   Demo3.code_begin
    ->  9.749ms BEGIN Demo3.code_begin
    ->  9.849ms BEGIN Stdlib.output_254
    ->   9.95ms BEGIN caml_ml_output_bytes
    ->  10.05ms BEGIN caml_putblock
    ->  10.15ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.974516169:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.974765777:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->  10.25ms END   memmove@plt
    ->  10.25ms END   caml_putblock
    ->  10.25ms END   caml_ml_output_bytes
    ->  10.25ms END   Stdlib.output_254
    ->  10.25ms END   Demo3.code_begin
    ->  10.25ms BEGIN Demo3.code_begin
    -> 10.375ms BEGIN Stdlib.input_299
    ->   10.5ms BEGIN caml_ml_input
    -> 10.625ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.975015285:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  10.75ms END   memmove@plt
    ->  10.75ms END   caml_ml_input
    ->  10.75ms END   Stdlib.input_299
    ->  10.75ms END   Demo3.code_begin
    ->  10.75ms BEGIN Demo3.code_begin
    ->   10.8ms BEGIN Stdlib.output_254
    -> 10.849ms BEGIN caml_ml_output_bytes
    -> 10.899ms BEGIN caml_putblock
    -> 10.949ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.975266579:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.975516225:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.975765797:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 10.999ms END   memmove@plt
    -> 10.999ms END   caml_putblock
    -> 10.999ms END   caml_ml_output_bytes
    -> 10.999ms END   Stdlib.output_254
    -> 10.999ms END   Demo3.code_begin
    -> 10.999ms BEGIN Demo3.code_begin
    -> 11.187ms BEGIN Stdlib.input_299
    -> 11.374ms BEGIN caml_ml_input
    -> 11.562ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.976015170:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  11.75ms END   memmove@plt
    ->  11.75ms END   caml_ml_input
    ->  11.75ms END   Stdlib.input_299
    ->  11.75ms END   Demo3.code_begin
    ->  11.75ms BEGIN Demo3.code_begin
    ->   11.8ms BEGIN Stdlib.output_254
    -> 11.849ms BEGIN caml_ml_output_bytes
    -> 11.899ms BEGIN caml_putblock
    -> 11.949ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.976266634:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 11.999ms END   memmove@plt
    -> 11.999ms END   caml_putblock
    -> 11.999ms END   caml_ml_output_bytes
    -> 11.999ms END   Stdlib.output_254
    -> 11.999ms END   Demo3.code_begin
    -> 11.999ms BEGIN Demo3.code_begin
    -> 12.062ms BEGIN Stdlib.input_299
    -> 12.125ms BEGIN caml_ml_input
    -> 12.188ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.976516366:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 12.251ms END   memmove@plt
    -> 12.251ms END   caml_ml_input
    -> 12.251ms END   Stdlib.input_299
    -> 12.251ms END   Demo3.code_begin
    -> 12.251ms BEGIN Demo3.code_begin
    ->   12.3ms BEGIN Stdlib.output_254
    ->  12.35ms BEGIN caml_ml_output_bytes
    ->   12.4ms BEGIN caml_putblock
    ->  12.45ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.976765745:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.977015345:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    ->   12.5ms END   memmove@plt
    ->   12.5ms END   caml_putblock
    ->   12.5ms END   caml_ml_output_bytes
    ->   12.5ms END   Stdlib.output_254
    ->   12.5ms END   Demo3.code_begin
    ->   12.5ms BEGIN Demo3.code_begin
    -> 12.625ms BEGIN Stdlib.input_299
    ->  12.75ms BEGIN caml_ml_input
    -> 12.874ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.977266713:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 12.999ms END   memmove@plt
    -> 12.999ms END   caml_ml_input
    -> 12.999ms END   Stdlib.input_299
    -> 12.999ms END   Demo3.code_begin
    -> 12.999ms BEGIN Demo3.code_begin
    -> 13.049ms BEGIN Stdlib.output_254
    ->   13.1ms BEGIN caml_ml_output_bytes
    ->  13.15ms BEGIN caml_putblock
    ->   13.2ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.977516373:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.977765815:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.978015334:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.978266871:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 13.251ms END   memmove@plt
    -> 13.251ms END   caml_putblock
    -> 13.251ms END   caml_ml_output_bytes
    -> 13.251ms END   Stdlib.output_254
    -> 13.251ms END   Demo3.code_begin
    -> 13.251ms BEGIN Demo3.code_begin
    -> 13.501ms BEGIN Stdlib.input_299
    -> 13.751ms BEGIN caml_ml_input
    -> 14.001ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.978516114:       1 cycles:u: "
      "\t          44198c caml_c_call+0x0 (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 14.251ms END   memmove@plt
    -> 14.251ms END   caml_ml_input
    -> 14.251ms END   Stdlib.input_299
    -> 14.251ms END   Demo3.code_begin
    -> 14.251ms BEGIN Demo3.code_begin
    -> 14.301ms BEGIN Stdlib.output_254
    ->  14.35ms BEGIN caml_ml_output_bytes
    ->   14.4ms BEGIN caml_putblock
    ->  14.45ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.978765561:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->   14.5ms END   memmove@plt
    ->   14.5ms END   caml_putblock
    ->   14.5ms END   caml_ml_output_bytes
    ->   14.5ms BEGIN caml_c_call
    (lines
     ("728783/728783 336962.979015028:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.979266264:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.979515764:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.979765318:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.980014935:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    -> 14.749ms END   caml_c_call
    -> 14.749ms END   Stdlib.output_254
    -> 14.749ms END   Demo3.code_begin
    -> 14.749ms BEGIN Demo3.code_begin
    -> 15.062ms BEGIN Stdlib.input_299
    -> 15.374ms BEGIN caml_ml_input
    -> 15.686ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.980266435:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.980516240:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          430a62 caml_putblock+0x32 (/usr/local/demo4)"
      "\t          43169d caml_ml_output_bytes+0x9d (/usr/local/demo4)"
      "\t          419fca Stdlib.output_254+0x4a (/usr/local/demo4)"
      "\t          41854d Demo3.code_begin+0x9d (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.980765853:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431b55 caml_ml_input+0x115 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 15.999ms END   memmove@plt
    -> 15.999ms END   caml_ml_input
    -> 15.999ms END   Stdlib.input_299
    -> 15.999ms END   Demo3.code_begin
    -> 15.999ms BEGIN Demo3.code_begin
    -> 16.149ms BEGIN Stdlib.output_254
    -> 16.299ms BEGIN caml_ml_output_bytes
    -> 16.449ms BEGIN caml_putblock
    ->   16.6ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.981018045:       1 cycles:u: "
      "\t          426630 caml_leave_blocking_section+0x0 (/usr/local/demo4)"
      "\t          43812b caml_read_fd+0x2b (/usr/local/demo4)"
      "\t          431b05 caml_ml_input+0xc5 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    ->  16.75ms END   memmove@plt
    ->  16.75ms END   caml_putblock
    ->  16.75ms END   caml_ml_output_bytes
    ->  16.75ms END   Stdlib.output_254
    ->  16.75ms END   Demo3.code_begin
    ->  16.75ms BEGIN Demo3.code_begin
    -> 16.813ms BEGIN Stdlib.input_299
    -> 16.876ms BEGIN caml_ml_input
    -> 16.939ms BEGIN memmove@plt
    (lines
     ("728783/728783 336962.981269574:       1 cycles:u: "
      "\t          426630 caml_leave_blocking_section+0x0 (/usr/local/demo4)"
      "\t          43812b caml_read_fd+0x2b (/usr/local/demo4)"
      "\t          431b05 caml_ml_input+0xc5 (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    (lines
     ("728783/728783 336962.981519067:       1 cycles:u: "
      "\t          417ab0 memmove@plt+0x0 (/usr/local/demo4)"
      "\t          431bcd caml_ml_input+0x18d (/usr/local/demo4)"
      "\t          41a24a Stdlib.input_299+0x4a (/usr/local/demo4)"
      "\t          418536 Demo3.code_begin+0x86 (/usr/local/demo4)"))
    -> 17.002ms END   memmove@plt
    -> 17.002ms END   caml_ml_input
    -> 17.002ms BEGIN caml_ml_input
    -> 17.169ms BEGIN caml_read_fd
    -> 17.336ms BEGIN caml_leave_blocking_section
    INPUT TRACE STREAM ENDED, any lines printed below this were deferred
    ->      0ns BEGIN Demo3.code_begin
    -> 17.503ms END   caml_leave_blocking_section
    -> 17.503ms END   caml_read_fd
    -> 17.503ms END   caml_ml_input
    -> 17.503ms BEGIN caml_ml_input
    -> 17.503ms BEGIN memmove@plt
    -> 17.503ms END   memmove@plt
    -> 17.503ms END   caml_ml_input
    -> 17.503ms END   Stdlib.input_299
    -> 17.503ms END   Demo3.code_begin |}]
;;
