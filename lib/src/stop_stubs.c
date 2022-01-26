#include <caml/mlvalues.h>

CAMLprim value magic_trace_stop_indicator (value a1 __attribute__((unused)), value a2 __attribute__((unused))) {
  return Val_unit;
}
