#include <time.h>
#include <unistd.h>

#include <sys/mman.h>
#include <sys/syscall.h>

#include <asm/perf_regs.h>
#include <linux/perf_event.h>

#include <caml/mlvalues.h>
#include <caml/unixsupport.h>

static uint64_t rdtsc(void) {
  uint32_t hi, lo;
  __asm__ __volatile__("rdtsc" : "=a"(lo), "=d"(hi));
  return ((uint64_t)lo) | (((uint64_t)hi) << 32);
}

static int sys_perf_event_open(struct perf_event_attr *attr, pid_t pid, int cpu,
                               int group_fd, unsigned long flags) {
  return syscall(SYS_perf_event_open, attr, pid, cpu, group_fd, flags);
}

CAMLprim value magic_clock_gettime_perf_ns() {
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

  uint64_t tsc = rdtsc();
  uint64_t quot = tsc >> perf_mmap->time_shift;
  uint64_t rem = tsc & (((uint64_t)1 << perf_mmap->time_shift) - 1);
  uint64_t timestamp = perf_mmap->time_zero + quot * perf_mmap->time_mult +
                       ((rem * perf_mmap->time_mult) >> perf_mmap->time_shift);

  munmap(mmap, mmap_size);
  close(fd);
  return Val_long(timestamp);
error_mmap:
  close(fd);
error_perf_event_open:
  uerror("failed to get perf time", Nothing);
}

CAMLprim value magic_clock_gettime_realtime_ns() {
  struct timespec ts;
  clock_gettime(CLOCK_REALTIME, &ts);
  return Val_long(((int64_t)ts.tv_sec * 1000 * 1000 * 1000) + ts.tv_nsec);
}
