#include "perf_dlfilter.h"
#include <string.h>

struct perf_dlfilter_fns perf_dlfilter_fns = {0};

int start(void **data, void *ctx);
int stop(void *data, void *ctx);
int filter_event(void *data, const struct perf_dlfilter_sample *sample,
                 void *ctx);
int filter_event_early(void *data, const struct perf_dlfilter_sample *sample,
                       void *ctx) {
  const struct perf_dlfilter_al *resolved_ip =
      perf_dlfilter_fns.resolve_ip(ctx);
  const struct perf_dlfilter_al *resolved_addr =
      perf_dlfilter_fns.resolve_addr(ctx);
  if (!resolved_ip || !resolved_ip->sym || !resolved_addr ||
      !resolved_addr->sym ||
      strcmp(resolved_ip->sym, resolved_addr->sym) == 0) {
    return 1;
  }
  return 0;
}
