#include <sys/ptrace.h>

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

CAMLprim value magic_ptrace_traceme(void) {
  return Val_bool(!ptrace(PTRACE_TRACEME, 0, NULL, NULL));
}

CAMLprim value magic_ptrace_detach(value v_pid) {
  ptrace(PTRACE_DETACH, Long_val(v_pid), NULL, NULL);
  return Val_unit;
}
