#include <time.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/syscall.h>

#include <asm/perf_regs.h>
#include <linux/perf_event.h>

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

#include "perf_utils.h"

static uint64_t rdtsc(void) {
  uint32_t hi, lo;
  __asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));
  return ((uint64_t)lo) | (((uint64_t)hi) << 32);
}

CAMLprim value magic_clock_gettime_perf_ns(void) {
  /*
   * It should be stated that despite any appearances to the contrary, I have no idea what
   * I'm doing here.
   *
   * We need to get the "current time in [perf] units" to line up events with absolute
   * time. Here, we create a fake software event with bogus information, just so we can
   * get a reference to the [perf_event_mmap_page] containing the time_{zero,shift,mult}
   * fields we need to scale [rdtsc] by.
   *
   * I *think* creating a [PERF_TYPE_SOFTWARE] event handle should have no side-effects,
   * but I'm not 100% sure on that.
   */
  struct perf_event_attr attr = {0};
  attr.size = sizeof(attr);
  attr.type = PERF_TYPE_SOFTWARE;

  int fd = sys_perf_event_open(&attr, getpid(), -1, -1, PERF_FLAG_FD_CLOEXEC);
  if (fd < 0) {
    goto error_perf_event_open;
  }

  size_t mmap_size =
      sysconf(_SC_PAGESIZE) * (1 + 1); // one metadata page plus one page buffer
  volatile struct perf_event_mmap_page *perf_mmap =
      mmap(NULL, mmap_size, PROT_READ, MAP_SHARED, fd, 0);
  if (mmap == MAP_FAILED) {
    goto error_mmap;
  }

  uint64_t timestamp = perf_time_of_tsc(perf_mmap, rdtsc());

  munmap(mmap, mmap_size);
  close(fd);
  return Val_long(timestamp);
error_mmap:
  close(fd);
error_perf_event_open:
  uerror("failed to get perf time", Nothing);
}
