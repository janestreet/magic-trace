#ifndef _PERF_UTILS_H
#define _PERF_UTILS_H

static int sys_perf_event_open(struct perf_event_attr *attr, pid_t pid, int cpu,
                               int group_fd, unsigned long flags) {
  return syscall(SYS_perf_event_open, attr, pid, cpu, group_fd, flags);
}

static uint64_t
perf_time_of_tsc(volatile struct perf_event_mmap_page *perf_mmap,
                 uint64_t tsc) {
  uint64_t quot = tsc >> perf_mmap->time_shift;
  uint64_t rem = tsc & (((uint64_t)1 << perf_mmap->time_shift) - 1);
  return perf_mmap->time_zero + quot * perf_mmap->time_mult +
    ((rem * perf_mmap->time_mult) >> perf_mmap->time_shift);
}

#endif
