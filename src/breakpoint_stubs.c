#include <assert.h>
#include <errno.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>

#include <asm/perf_regs.h>
#include <linux/hw_breakpoint.h>
#include <linux/perf_event.h>

#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/mlvalues.h>

#include "perf_utils.h"

// See [lib/pmc/src/msr_stubs.c:187] for an explanation
#define rmb() asm volatile("" ::: "memory")

struct breakpoint_state {
  int fd;
  size_t mmap_size;
  volatile struct perf_event_mmap_page *mmap;
};

#define Breakpoint_state_val(v)                                                \
  (*((struct breakpoint_state **)Data_custom_val(v)))

static void destroy_breakpoint_state(struct breakpoint_state *s) {
  if (s->mmap && s->mmap != MAP_FAILED)
    munmap((void *)s->mmap, s->mmap_size);
  if (s->fd > 0)
    close(s->fd);
  free(s);
}

static void finalize_breakpoint_state(value v) {
  struct breakpoint_state *s = Breakpoint_state_val(v);
  if (s)
    destroy_breakpoint_state(s);
  Breakpoint_state_val(v) = NULL;
}

CAMLprim value magic_breakpoint_destroy_stub(value v) {
  finalize_breakpoint_state(v);
  return Val_unit;
}

static struct custom_operations breakpoint_state_ops = {
    .identifier = "com.janestreet.magic-trace.breakpoint_state",
    .finalize = finalize_breakpoint_state,
    .compare = custom_compare_default,
    .compare_ext = custom_compare_ext_default,
    .hash = custom_hash_default,
    .serialize = custom_serialize_default,
    .deserialize = custom_deserialize_default,
    .fixed_length = custom_fixed_length_default};

CAMLprim value magic_breakpoint_fd_stub(value state) {
  return Val_long(Breakpoint_state_val(state)->fd);
}

CAMLprim value magic_breakpoint_create_stub(value pid, value addr,
                                            value single_hit) {
  CAMLparam3(pid, addr, single_hit);
  CAMLlocal2(wrap, v);
  struct perf_event_attr attr;

  memset(&attr, 0, sizeof(attr));
  attr.size = sizeof(attr);
  attr.type = PERF_TYPE_BREAKPOINT;
  attr.bp_type = HW_BREAKPOINT_X;
  attr.bp_addr = Int64_val(addr);
  attr.bp_len = sizeof(long);
  attr.sample_period = 1;
  attr.sample_type = PERF_SAMPLE_TIME | PERF_SAMPLE_IP | PERF_SAMPLE_REGS_USER |
                     PERF_SAMPLE_TID;
  attr.exclude_hv = 1;
  attr.exclude_kernel = 1;
  attr.disabled = Bool_val(single_hit);
  attr.wakeup_events = 1;
  attr.precise_ip = 2;
  // first and second argument register
  attr.sample_regs_user = (1ul << PERF_REG_X86_DI) | (1ul << PERF_REG_X86_SI);
  // calloc returns zeroed memory so we don't try to free garbage in error cases
  struct breakpoint_state *s = calloc(1, sizeof(*s));

  s->fd =
      sys_perf_event_open(&attr, Long_val(pid), -1, -1, PERF_FLAG_FD_CLOEXEC);

  if (s->fd < 0)
    goto failed;

  s->mmap_size =
      sysconf(_SC_PAGESIZE) * (1 + 1); // one metadata page plus one page buffer
  // The PROT_READ and PROT_WRITE is how we tell perf we'll be updating
  // data_tail
  s->mmap =
      mmap(NULL, s->mmap_size, PROT_READ | PROT_WRITE, MAP_SHARED, s->fd, 0);
  if (s->mmap == MAP_FAILED)
    goto failed;

  // Makes it so the breakpoint only triggers once before being disabled
  if (Bool_val(single_hit)) {
    if (ioctl(s->fd, PERF_EVENT_IOC_REFRESH, 1) < 0)
      goto failed;
  }

  v = caml_alloc_custom(&breakpoint_state_ops, sizeof(s), 0, 1);
  Breakpoint_state_val(v) = s;

  wrap = caml_alloc(1, 0); // Ok constructor of result
  Field(wrap, 0) = v;

  CAMLreturn(wrap);
failed:
  destroy_breakpoint_state(s);
  assert(errno > 0);
  wrap = caml_alloc(1, 1); // Error constructor of result
  Field(wrap, 0) = Val_long(errno);
  CAMLreturn(wrap);
}

struct my_sample {
  struct perf_event_header header;
  uint64_t ip;
  uint32_t pid, tid;
  uint64_t time;
  uint64_t abi;
  uint64_t regs[2];
};

CAMLprim value magic_breakpoint_next_stub(value state) {
  CAMLparam1(state);
  CAMLlocal2(res, info);
  struct breakpoint_state *s = Breakpoint_state_val(state);
  if (!s)
    CAMLreturn(Val_none);

  char *cur = (char *)s->mmap + s->mmap->data_offset +
              (s->mmap->data_tail % s->mmap->data_size);
  char *events_end = (char *)s->mmap + s->mmap->data_offset +
                     (s->mmap->data_head % s->mmap->data_size);
  rmb();

  while (cur < events_end) {
    struct perf_event_header *ev = (struct perf_event_header *)cur;
    if (ev->type == PERF_RECORD_SAMPLE) {
      struct my_sample *samp = (struct my_sample *)ev;
      // These may be nonsense but nothing should go wrong if they are.
      // We untag and retag unconditionally so that if it is garbage the
      // value passed to OCaml is a garbage integer and never a garbage pointer.
      uint64_t tsc = Long_val(samp->regs[1]);
      uint64_t val = Long_val(samp->regs[0]);

      uint64_t timestamp = tsc != 0 ? perf_time_of_tsc(s->mmap, tsc) : 0;

      /* Keep in sync with Breakpoint.Hit.t */
      info = caml_alloc_tuple(5);
      Field(info, 0) = Val_long(samp->time);
      Field(info, 1) = Val_long(timestamp);
      Field(info, 2) = Val_long(val);
      Field(info, 3) = Val_long(samp->tid);
      Field(info, 4) = Val_long(samp->ip);
      res = caml_alloc_some(info);
      // Needs to be updated after we read the sample because the kernel uses
      // this value to not overwrite data until we've read it.
      s->mmap->data_tail += ev->size;
      CAMLreturn(res);
    } else {
      s->mmap->data_tail += ev->size;
    }
    cur += ev->size;
  }
  CAMLreturn(Val_none);
}
