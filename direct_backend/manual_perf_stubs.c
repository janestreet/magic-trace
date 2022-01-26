#include <stdlib.h>
#include <stdio.h>
#include <stdbool.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <poll.h>

#include <sys/syscall.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

#include <linux/perf_event.h>

#include <caml/mlvalues.h>
#include <caml/custom.h>
#include <caml/memory.h>
#include <caml/threads.h>

/*** INTEROP CODE ***/

/*$
open Magic_trace_lib_cinaps_helpers.Trace_decoding_interop ;;

gen_c_record_enum recording_config ;;
gen_c_record_enum trace_meta ;;
*/
enum recording_config_field {
	recording_config_field_pid /* int */,
	recording_config_field_data_size /* int */,
	recording_config_field_aux_size /* int */,
	recording_config_field_filter /* string option */,
	recording_config_field_pt_fd /* int */,
	recording_config_field_sb_fd /* int */,
	};

enum trace_meta_field {
	trace_meta_field_time_shift /* int */,
	trace_meta_field_time_mult /* int */,
	trace_meta_field_time_zero /* int */,
	trace_meta_field_max_nonturbo_ratio /* int */,
	};
/*$*/


/*** UTIL ***/

#define or_ret(val) \
  do { \
    int __res = (val); \
    if (__res != 0) return __res; \
  } while (0)

static int write_all(int fd, const char *buf, size_t amt) {
  size_t written = 0;
  while (written < amt) {
    ssize_t res = write(fd, buf + written, amt - written);
    if (res < 0) return res;
    written += res;
  }
  return 0;
}

static int sys_perf_event_open(struct perf_event_attr *attr, pid_t pid,
                               int cpu, int group_fd, unsigned long flags) {
  return syscall(SYS_perf_event_open, attr, pid, cpu, group_fd, flags);
}

static uint64_t round_power2_pages(uint64_t n) {
  uint64_t r = sysconf(_SC_PAGESIZE);
  while (r < n) r <<= 1;
  return r;
}

static bool pt_aux_buffer_has_wrapped(char *buf, size_t size) {
  // check the last 512-ish words of the buffer for zeros
  // cast to words to make it a bit faster.
  int upper = size / sizeof(uint64_t);
  int lower = upper - 512;
  if(lower < 0) lower = 0;

  uint64_t *word_buf = (uint64_t*)buf;
  for (int i = lower; i < upper; i++) {
    if (word_buf[i])
      return true;
  }

  return false;
}

static int dump_pt_aux_buffer(int fd, char *base,
                              uint64_t size, uint64_t head_) {
  bool has_wrapped = pt_aux_buffer_has_wrapped(base, size);
  // printf("ptdump %lu %lu %d\n", size, head_, has_wrapped); fflush(stdout);
  char *end  = base + size;
  char *head = base + (head_ & (size - 1));

  if (!has_wrapped) {
    or_ret(write_all(fd, base, head - base));
  } else {
    or_ret(write_all(fd, head, end - head));
    or_ret(write_all(fd, base, head - base));
  }

  return 0;
}

static int dump_perf_buffer(int fd, char *base,
                            uint64_t size, uint64_t head_, uint64_t tail_) {
  // printf("dumping %lu %lu %lu\n", size, head_, tail_); fflush(stdout);
  char *end  = base + size;
  char *head = base + (head_ & (size - 1));
  char *tail = base + (tail_ & (size - 1));

  if (tail <= head) {
    or_ret(write_all(fd, tail, head - tail));
  } else {
    or_ret(write_all(fd, tail, end - tail));
    or_ret(write_all(fd, base, head - base));
  }

  return 0;
}

// See [lib/pmc/src/msr_stubs.c:187] for an explanation
#define rmb() asm volatile("" ::: "memory")

/*** OPERATIONS ***/

struct tracing_state {
  bool failure_state;
  int intel_pt_type;
  int perf_fd;
  struct perf_event_mmap_page *header;
  char *base, *data, *aux;
  uint64_t base_mmap_size, aux_mmap_size;

  int pt_fd;
  int sb_fd;
};

static int read_int_file(const char *path, int *result) {
  FILE* intel_pt_type_f = fopen(path, "r");
  if (intel_pt_type_f == NULL) return -1;
  int res = fscanf(intel_pt_type_f, "%d", result);
  fclose(intel_pt_type_f);
  return (res != 1) ? -1 : 0;
}

static int init_tracing_state(struct tracing_state *s) {
  if(read_int_file("/sys/bus/event_source/devices/intel_pt/type", &s->intel_pt_type))
    return -1;

  s->failure_state = false;
  s->perf_fd = -1;
  s->base = s->data = s->aux = NULL;
  s->base_mmap_size = s->aux_mmap_size = 0;

  return 0;
}

static int destroy_tracing_state(struct tracing_state *s) {
  if (!s) return 0;

  if (s->perf_fd != -1) {
    close(s->perf_fd);
    s->perf_fd = -1;
  }

  if (s->aux) munmap(s->aux, s->aux_mmap_size);
  if (s->base) munmap(s->base, s->base_mmap_size);

  close(s->pt_fd);
  close(s->sb_fd);

  s->aux = s->base = NULL;

  return 0;
}


static int dump_tracing_data(struct tracing_state *s) {
  if (ioctl(s->perf_fd, PERF_EVENT_IOC_DISABLE) == -1) return -1;

  struct perf_event_mmap_page *hdr = s->header;

  uint64_t data_head = hdr->data_head, data_tail = hdr->data_tail;
  // perf_event_open documentation dictates that after reading the head field of a
  // circular buffer an rmb() should be issued
  rmb();


  or_ret(dump_perf_buffer(s->sb_fd, s->data, hdr->data_size,
                          data_head, data_tail));
  hdr->data_tail = data_head;

  uint64_t aux_head = hdr->aux_head;
  rmb();

  or_ret(dump_pt_aux_buffer(s->pt_fd, s->aux, hdr->aux_size, aux_head));
  hdr->aux_tail = aux_head;

  return 0;
}

static int dump_tracing_data_withfailure(struct tracing_state *s) {
  if (!s || s->failure_state || s->perf_fd == -1) {
    errno = EINVAL;
    return -1;
  }

  int ret = dump_tracing_data(s);
  if (ret != 0) s->failure_state = true;
  return ret;
}

static int start_tracing(struct tracing_state *s, value config, value trace_meta) {
  if (!s || s->failure_state || s->perf_fd != -1) {
    errno = EINVAL;
    goto failed_tracing;
  }

  s->pt_fd = Long_val(Field(config, recording_config_field_pt_fd));
  s->sb_fd = Long_val(Field(config, recording_config_field_sb_fd));

  int max_nonturbo_ratio;
  if(read_int_file("/sys/bus/event_source/devices/intel_pt/max_nonturbo_ratio", &max_nonturbo_ratio))
    goto failed_tracing;

  int pid = Int_val(Field(config, recording_config_field_pid));
  uint64_t data_size_raw = Long_val(Field(config, recording_config_field_data_size));
  uint64_t aux_size_raw = Long_val(Field(config, recording_config_field_aux_size));
  value filter_v = Field(config, recording_config_field_filter);
  // Current libraries are too old for option constructors, but can manually substitute
  // https://github.com/ocaml/ocaml/commit/973eeb1867f41ef2669ad4cbfa9c2e76ddef1749#diff-3fac38e5f784aae1fec51339ed6c17636608cdbcb35e2a99ca181a371fd0e894R376
  char *filter = Is_block(filter_v) ? strdup(String_val(Field(filter_v, 0))) : NULL;

  // https://github.com/intel/libipt/blob/master/doc/howto_tracing.md
  struct perf_event_attr attr;
  memset(&attr, 0, sizeof(attr));

  attr.type = s->intel_pt_type;
  attr.exclude_kernel = 1;
  attr.exclude_hv = 1;
  attr.sample_period = attr.sample_freq = 1;
  attr.sample_type = PERF_SAMPLE_IP | PERF_SAMPLE_TID | PERF_SAMPLE_TIME;
  attr.sample_id_all = attr.mmap = attr.mmap2 = attr.context_switch = 1;

  // These config bits were determined by running this command:
  // grep -H . /sys/bus/event_source/devices/intel_pt/format/*
  // It's reasonably complex to parse these dynamically, and they seem consistent
  // so for now we'll just hard-code the following bits:
  // cyc (bit 1)=1 - enable high-resolution cycle counts
  // cyc_thresh (bits 19-22)=1 - set them to the maximum possible frequency
  // tsc (bit 10)=1 - enable time stamp counter packets for calibration
  attr.config = (1 << 19) | (1 << 1) | (1 << 10);

  attr.comm = attr.comm_exec = 1;
  attr.task = 1;
  attr.context_switch = 1;

  // Track a specific pid, on any cpu. There should only be one active at any time so
  // grouping is unnecessary.
  s->perf_fd = sys_perf_event_open(&attr, pid, -1, -1, PERF_FLAG_FD_CLOEXEC);
  if (s->perf_fd == -1) goto failed_open;

  uint64_t data_size = round_power2_pages(data_size_raw);
  uint64_t aux_size = round_power2_pages(aux_size_raw);
  uint64_t base_mmap_size = data_size + sysconf(_SC_PAGESIZE);
  s->base = mmap(NULL, base_mmap_size, PROT_WRITE,
                 MAP_SHARED, s->perf_fd, 0);
  if (s->base == MAP_FAILED) goto failed_base;
  s->base_mmap_size = base_mmap_size;

  s->header = (struct perf_event_mmap_page *)s->base;
  s->data = s->base + s->header->data_offset;
  s->header->data_tail = 0;

  s->header->aux_offset = s->header->data_offset + s->header->data_size;
  s->header->aux_size = aux_size;

  s->aux = mmap(NULL, s->header->aux_size, PROT_READ,
                MAP_SHARED, s->perf_fd, s->header->aux_offset);
  if (s->aux == MAP_FAILED) goto failed_aux;
  s->aux_mmap_size = aux_size;

  if (filter) {
    if (ioctl(s->perf_fd, PERF_EVENT_IOC_SET_FILTER, filter) == -1) goto failed_ioctl;
    free(filter);
  }

  Store_field(trace_meta, trace_meta_field_time_shift, Val_long(s->header->time_shift));
  Store_field(trace_meta, trace_meta_field_time_mult, Val_long(s->header->time_mult));
  Store_field(trace_meta, trace_meta_field_time_zero, Val_long(s->header->time_zero));
  Store_field(trace_meta, trace_meta_field_max_nonturbo_ratio, Val_long(max_nonturbo_ratio));

  return 0;

  // error states
 failed_ioctl:
 failed_aux:
  munmap(s->base, base_mmap_size);
 failed_base:
  close(s->perf_fd);
  s->perf_fd = -1;
 failed_open:
  s->failure_state = true;
  if(filter) free(filter);
 failed_tracing:
  return -1;
}

/*** OCAML HOOKS ***/

#define Tracing_state_val(v) (*((struct tracing_state **) Data_custom_val(v)))

static void finalize_tracing_state(value v) {
  destroy_tracing_state(Tracing_state_val(v));
}

static struct custom_operations tracing_state_ops =
  { .identifier = "com.janestreet.magic-trace.tracing_state"
  , .finalize = finalize_tracing_state
  , .compare = custom_compare_default
  , .compare_ext = custom_compare_ext_default
  , .hash = custom_hash_default
  , .serialize = custom_serialize_default
  , .deserialize = custom_deserialize_default
  , .fixed_length = custom_fixed_length_default
  };

CAMLprim value magic_recording_create_state_stub(value unit __attribute__((unused)) ) {
  CAMLparam0 ();
  CAMLlocal1 (v);

  struct tracing_state *s = malloc(sizeof(*s));
  v = caml_alloc_custom(&tracing_state_ops, sizeof(s), 0, 1);
  Tracing_state_val(v) = s;

  CAMLreturn (v);
}

static value attach_to_process(value state, value config, value trace_meta) {
  struct tracing_state *s = Tracing_state_val(state);
  if(init_tracing_state(s)) return -1;
  if(start_tracing(s, config, trace_meta)) return -1;
  return 0;
}

CAMLprim value magic_recording_attach_stub(value state, value config, value trace_meta) {
  int result = attach_to_process(state, config, trace_meta);
  return Val_int(result ? errno : 0);
}

CAMLprim value magic_recording_take_snapshot_stub(value v) {
  int result = dump_tracing_data_withfailure(Tracing_state_val(v));
  return Val_int(result ? errno : 0);
}

CAMLprim value magic_recording_destroy_stub(value v) {
  destroy_tracing_state(Tracing_state_val(v));
  Tracing_state_val(v) = NULL;
  return Val_unit;
}




