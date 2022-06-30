#include <stdio.h>
#include <string.h>
#include <caml/alloc.h>
#include <caml/callback.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>
#include "perf_dlfilter.h"

struct perf_dlfilter_fns perf_dlfilter_fns = {0};

// Just need to pass some args to ocaml, not important what they are here
char *argv[2] = {"dlfilter.so", NULL};

int start(void **data, void *ctx) {
  caml_startup(argv);
  caml_callback(*caml_named_value("initialize"), Val_unit);
  return 0;
}
int stop(void *data, void *ctx) {
  caml_callback(*caml_named_value("finally"), Val_unit);
}
int filter_event(void *data, const struct perf_dlfilter_sample *sample,
                 void *ctx);
int filter_event_early(void *data, const struct perf_dlfilter_sample *sample,
                       void *ctx) {
  CAMLparam0();

  const struct perf_dlfilter_al *resolved_ip =
    perf_dlfilter_fns.resolve_ip(ctx);
  const struct perf_dlfilter_al *resolved_addr =
    perf_dlfilter_fns.resolve_addr(ctx);

  /* if (getenv("__MAGIC_TRACE_FILTER_SAME_FUNCTION_JUMPS")) { */
  /*   if (resolved_ip && resolved_ip->sym && sample->addr_correlates_sym && resolved_addr && resolved_addr->sym && strcmp(resolved_ip->sym, resolved_addr->sym) == 0) { */
  /*     return 1; */
  /*   } */
  /* } */

  CAMLlocal1(caml_sample);
  /* value caml_sample; */
  caml_sample = caml_alloc(12, 0);
  CAMLlocal4(ip, time, addr, period);
  /* value ip, time, addr, period; */
  ip = caml_copy_int64(sample->ip);
  time = caml_copy_int64(sample->time);
  addr = caml_copy_int64(sample->addr);
  period = caml_copy_int64(sample->period);
  Store_field(caml_sample, 0, ip);
  Store_field(caml_sample, 1, Val_int(sample->pid));
  Store_field(caml_sample, 2, Val_int(sample->tid));
  Store_field(caml_sample, 3, time);
  Store_field(caml_sample, 4, addr);
  Store_field(caml_sample, 5, period);
  Store_field(caml_sample, 6, Val_int(sample->cpu));
  Store_field(caml_sample, 7, Val_int(sample->flags));
  Store_field(caml_sample, 8, Val_int(sample->raw_size));
  if (!sample->event) {
    Store_field(caml_sample, 9, Val_none);
  }
  else {
    CAMLlocal2(event, event_opt);
    /* value event, event_opt; */
    event = caml_copy_string_of_os(sample->event);
    event_opt = caml_alloc_some(event);
    Store_field(caml_sample, 9, event_opt);
  }

  if (!resolved_ip) {
    Store_field(caml_sample, 10, Val_none);
  }
  else {
    CAMLlocal1(caml_resolved_ip);
    /* value caml_resolved_ip, caml_resolved_ip_opt; */
    caml_resolved_ip = caml_alloc(3, 0);
    Store_field(caml_resolved_ip, 0, Val_int(resolved_ip->symoff));
    if (!resolved_ip->sym) {
      Store_field(caml_resolved_ip, 1, Val_none);
    }
    else {
      CAMLlocal2(sym_opt, sym);
      /* value sym_opt, sym; */
      sym = caml_copy_string_of_os(resolved_ip->sym);
      sym_opt = caml_alloc_some(sym);
      Store_field(caml_resolved_ip, 1, sym_opt);
    }
    if (!resolved_ip->dso) {
      Store_field(caml_resolved_ip, 2, Val_none);
    }
    else {
      CAMLlocal2(dso_opt, dso);
      /* value dso_opt, dso; */
      dso = caml_copy_string_of_os(resolved_ip->dso);
      dso_opt = caml_alloc_some(dso);
      Store_field(caml_resolved_ip, 2, dso_opt);
    }
    CAMLlocal1(caml_resolved_ip_opt);
    caml_resolved_ip_opt = caml_alloc_some(caml_resolved_ip);
    Store_field(caml_sample, 10, caml_resolved_ip_opt);
  }

  if (!resolved_addr && !sample->addr_correlates_sym || 1) {
    Store_field(caml_sample, 11, Val_none);
  }
  else {
    CAMLlocal2(caml_resolved_addr, caml_resolved_addr_opt);
    /* value caml_resolved_addr, caml_resolved_addr_opt; */
    caml_resolved_addr = caml_alloc(3, 0);
    Store_field(caml_resolved_addr, 0, Val_int(resolved_addr->symoff));
    if (!resolved_addr->sym) {
      Store_field(caml_resolved_addr, 1, Val_none);
    }
    else {
      CAMLlocal2(sym_opt, sym);
      /* value sym_opt, sym; */
      sym = caml_copy_string(resolved_addr->sym);
      sym_opt = caml_alloc_some(sym);
      Store_field(caml_resolved_addr, 1, sym_opt);
    }
    if (!resolved_addr->dso) {
      Store_field(caml_resolved_addr, 2, Val_none);
    }
    else {
      CAMLlocal2(dso_opt, dso);
      /* value dso_opt, dso; */
      dso = caml_copy_string(resolved_addr->dso);
      dso_opt = caml_alloc_some(dso);
      Store_field(caml_resolved_addr, 2, dso_opt);
    }
    caml_resolved_addr_opt = caml_alloc_some(caml_resolved_addr);
    Store_field(caml_sample, 11, caml_resolved_addr_opt);
  }

  /* printf("about to write\n"); */
  caml_callback(*caml_named_value("process_sample"), caml_sample);

  // We always filter so that perf script doesn't actually output
  CAMLreturnT(int, 1);
  /* return 1; */

  /* if (!resolved_ip || !resolved_ip->sym || !resolved_addr || */
  /*     !resolved_addr->sym || */
  /*     strcmp(resolved_ip->sym, resolved_addr->sym) == 0) { */
  /*   return 1; */
  /* } */
  /* return 0; */
}
