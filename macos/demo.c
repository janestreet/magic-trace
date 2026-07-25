#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#if defined(__clang__) || defined(__GNUC__)
#define NOINLINE __attribute__((noinline))
#else
#define NOINLINE
#endif

static NOINLINE uint64_t scramble(uint64_t value) {
  value ^= value >> 12;
  value ^= value << 25;
  value ^= value >> 27;
  return value * UINT64_C(2685821657736338717);
}

static NOINLINE uint64_t work_a(uint64_t value) {
  for (int index = 0; index < 50000; ++index)
    value = scramble(value + (uint64_t)index);
  return value;
}

static NOINLINE uint64_t work_b(uint64_t value) {
  for (int index = 0; index < 30000; ++index)
    value = scramble(value ^ (uint64_t)index);
  return value;
}

static double monotonic_seconds(void) {
  struct timespec time;
  clock_gettime(CLOCK_MONOTONIC, &time);
  return (double)time.tv_sec + ((double)time.tv_nsec / 1000000000.0);
}

int main(int argc, char **argv) {
  uint64_t value = UINT64_C(0x123456789abcdef);

  if (argc > 1 && strcmp(argv[1], "--iterations") == 0) {
    if (argc != 3) {
      fprintf(stderr, "usage: %s --iterations COUNT\n", argv[0]);
      return 2;
    }

    char *end = NULL;
    const unsigned long long iterations = strtoull(argv[2], &end, 10);
    if (end == argv[2] || *end != '\0' || iterations == 0) {
      fprintf(stderr, "invalid iteration count: %s\n", argv[2]);
      return 2;
    }

    const double start = monotonic_seconds();
    for (unsigned long long iteration = 0; iteration < iterations; ++iteration) {
      value = work_a(value);
      value = work_b(value);
    }
    const double elapsed = monotonic_seconds() - start;
    printf("%.9f %llu\n", elapsed, (unsigned long long)value);
    return 0;
  }

  const double duration = argc > 1 ? strtod(argv[1], NULL) : 4.0;
  const double end = monotonic_seconds() + duration;

  while (monotonic_seconds() < end) {
    value = work_a(value);
    value = work_b(value);
  }

  printf("%llu\n", (unsigned long long)value);
  return 0;
}
