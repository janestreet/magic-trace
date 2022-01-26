#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>

typedef struct { uint64_t state;  uint64_t inc; } pcg32_random_t;

uint32_t pcg32_random_r(pcg32_random_t* rng)
{
    uint64_t oldstate = rng->state;
    // Advance internal state
    rng->state = oldstate * 6364136223846793005ULL + (rng->inc|1);
    // Calculate output function (XSH RR), uses old state for max ILP
    uint32_t xorshifted = ((oldstate >> 18u) ^ oldstate) >> 27u;
    uint32_t rot = oldstate >> 59u;
    return (xorshifted >> rot) | (xorshifted << ((-rot) & 31));
}

void pcg32_srandom_r(pcg32_random_t* rng, uint64_t initstate, uint64_t initseq)
{
    rng->state = 0U;
    rng->inc = (initseq << 1u) | 1u;
    pcg32_random_r(rng);
    rng->state += initstate;
    pcg32_random_r(rng);
}

// static __inline__ uint64_t rdtsc(void)
// {
//   unsigned hi, lo;
//   __asm__ __volatile__ ("rdtsc" : "=a"(lo), "=d"(hi));
//   return ( (uint64_t)lo)|( ((uint64_t)hi)<<32 );
// }

int my_do_work(pcg32_random_t *rng) {
  int res = 1;
  int i;
  for(i = 0; i < 70; i++) {
    int r = 0;
    int j;
    // for(j = 0; j < 3; j++) {
      r = (r + pcg32_random_r(rng)) % 2;
    // }
    if(r == 0) {
      res += 1;
    } else {
      int r2 = pcg32_random_r(rng) % 4;
      if(r2 == 0) {
        res -= 10;
      } else {
        res += r2;
      }
    }
  }
  return res;
}

int sim_busy_loop(pcg32_random_t *rng) {
  int res = 1;
  for(int i = 0; i < 100; i++) {
    int r = pcg32_random_r(rng) % 2;
    if(r == 0) {
      res += 1;
    } else {
      res -= 10;
    }
  }
  return res;
}

int
main(int argc, char **argv) {
  // setup
  pcg32_random_t rng;
  pcg32_srandom_r(&rng, 42u, 54u);
  // pcg32_srandom_r(&rng, time(NULL) ^ (intptr_t)&printf, 54u);

  int res = 0;
  for(int i = 0; i < 10; i++) {
    sim_busy_loop(&rng);

    res += my_do_work(&rng);
  }

  // pid_t ppid = getppid();
  // kill(ppid, SIGUSR2);
  // fprintf(stderr, "ppid: %i\n", ppid);
  // sleep(1);

  printf("%i\n", res);

  return 0;
}
