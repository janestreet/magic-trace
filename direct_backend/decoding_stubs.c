#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <stdbool.h>
#include <assert.h>

#include <sys/mman.h>
#include <linux/perf_event.h>

#include <intel-pt.h>
#include <libipt-sb.h>
#include <pevent.h>

#include <caml/mlvalues.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/memory.h>
#include <caml/callback.h>
#include <caml/alloc.h>

/*** INTEROP CODE ***/

/*$
open Magic_trace_lib_cinaps_helpers.Trace_decoding_interop ;;

gen_c_enum event_kinds ;;
gen_c_enum decode_result ;;
gen_c_record_enum event_packet ;;
gen_c_record_enum add_section_packet ;;
gen_c_record_enum decoding_config ;;
gen_c_record_enum mmap ;;
gen_c_record_enum trace_meta ;;
gen_c_record_enum setup_info ;;
*/
enum event_kind {
  event_kind_none = -1,
	event_kind_other = 0,
	event_kind_call = 1,
	event_kind_ret = 2,
	event_kind_start_trace = 3,
	event_kind_end_trace = 4,
	event_kind_end_trace_syscall = 5,
	event_kind_install_handler = 6,
	event_kind_raise_exception = 7,
	event_kind_decode_error = 8,
	event_kind_jump = 9,
	};

enum decode_result {
  decode_result_none = -1,
	decode_result_end_of_trace = 0,
	decode_result_event = 1,
	decode_result_add_section = 2,
	};

enum event_field {
	event_field_pid /* int */,
	event_field_tid /* int */,
	event_field_kind /* Event_kind.t */,
	event_field_addr /* int */,
	event_field_time /* int */,
	event_field_isid /* int */,
	event_field_symbol_begin /* int */,
	event_field_symbol_end /* int */,
	};

enum add_section_field {
	add_section_field_filename /* string */,
	add_section_field_offset /* int */,
	add_section_field_size /* int */,
	add_section_field_vaddr /* int */,
	add_section_field_isid /* int */,
	};

enum config_field {
	config_field_sideband_filename /* string */,
	config_field_pt_data_fd /* int */,
	config_field_setup_info /* Manual_perf.Setup_info.t */,
	};

enum mmap_field {
	mmap_field_vaddr /* int */,
	mmap_field_length /* int */,
	mmap_field_offset /* int */,
	mmap_field_filename /* string */,
	};

enum trace_meta_field {
	trace_meta_field_time_shift /* int */,
	trace_meta_field_time_mult /* int */,
	trace_meta_field_time_zero /* int */,
	trace_meta_field_max_nonturbo_ratio /* int */,
	};

enum setup_info_field {
	setup_info_field_initial_maps /* Mmap.t list */,
	setup_info_field_trace_meta /* Trace_meta.t */,
	setup_info_field_pid /* int */,
	};
/*$*/


unsigned char TODO_ASM_INSTALL[] = { 0 };

/*** MAIN ***/

struct pending_section {
  char *filename;
  uint64_t offset;
  uint64_t size;
  uint64_t vaddr;
  uint64_t isid;

  struct pending_section *next;
};

struct decoding_state {
  // passed
  int pt_fd;

  // internal to the decoding state
  uint8_t *pt_mmap;
  size_t pt_length;
  uint64_t tsc;

  struct pt_insn_decoder *decoder;
  struct pt_image_section_cache *iscache;
  struct pt_sb_session *session;

  struct pev_config pev_config;

  enum event_kind pending_event_kind;
  bool last_was_syscall;

  bool pt_synced;
  int saved_status;

  struct pending_section *pending_section_head;

  // These values are only used temporarily during decode calls
  value *event;
  value *add_section;
  enum decode_result pending_decode_result;
};

static void destroy_decoding_state(struct decoding_state *s) {
  if (!s) return;

  if (s->pt_mmap) munmap(s->pt_mmap, s->pt_length);
  if (s->decoder) pt_insn_free_decoder(s->decoder);
  if (s->iscache) pt_iscache_free(s->iscache);
  if (s->session) pt_sb_free(s->session);
  free(s);
}

/*** EVENT HANDLERS ***/

static void commit_event(struct decoding_state *s) {
  uint64_t timestamp_ns;
  // This only fails if we call it wrong
  assert(pev_time_from_tsc(&timestamp_ns, s->tsc, &(s->pev_config)) == 0);
  Store_field(*s->event, event_field_time, Val_long(timestamp_ns));
  s->pending_decode_result = decode_result_event;
}

static int handle_event(struct decoding_state *s, const struct pt_event *event) {
  int error = 0;
  if (event->has_tsc) {
    s->tsc = event->tsc;
  }

  enum event_kind kind = event_kind_none;
  uint64_t ip = 0;
  switch (event->type) {
  case ptev_enabled:
    kind = event_kind_start_trace;
    ip = event->variant.enabled.ip;
    break;
  case ptev_disabled:
    kind = s->last_was_syscall ? event_kind_end_trace_syscall : event_kind_end_trace;
    ip = event->variant.disabled.ip;
    break;
  case ptev_async_disabled:
    kind = event_kind_end_trace;
    ip = event->variant.async_disabled.ip;
    break;
  default:
    break;
  }
  if(kind != event_kind_none) {
    Store_field(*s->event, event_field_kind, Val_int(kind));
    if(ip) Store_field(*s->event, event_field_addr, Val_int(ip));
    Store_field(*s->event, event_field_isid, Val_int(0));
    commit_event(s);
  }


  struct pt_image *image = NULL;
  error = pt_sb_event(s->session, &image, event, sizeof(*event), stdout,
    0);
    // ptsbp_verbose | ptsbp_filename | ptsbp_file_offset | ptsbp_tsc);
  if (error < 0) return error;

  if (image) {
    return pt_insn_set_image(s->decoder, image);
  } else {
    return 0;
  }
}

static void handle_instruction(struct decoding_state *s, const struct pt_insn *insn) {
  uint64_t ip = insn->ip;
  uint64_t prev_sym_start = Long_val(Field(*s->event, event_field_symbol_begin));
  uint64_t prev_sym_end = Long_val(Field(*s->event, event_field_symbol_end));

  if(s->pending_event_kind != event_kind_none) {
    Store_field(*s->event, event_field_kind, Val_int(s->pending_event_kind));
    Store_field(*s->event, event_field_addr, Val_int(ip));
    Store_field(*s->event, event_field_isid, Val_int(insn->isid));
    commit_event(s);
    s->pending_event_kind = event_kind_none;
  }

  enum event_kind kind = event_kind_none;
  switch (insn->iclass) {
  case ptic_call:
    kind = event_kind_call;
    break;
  case ptic_return:
    kind = event_kind_ret;
    break;
  case ptic_jump: case ptic_cond_jump: case ptic_far_jump:
    // do not report a jump as an event if we remain in the address space of the current
    // symbol
    if (prev_sym_start <= ip && ip < prev_sym_end)
      break;
    kind = event_kind_jump;
    break;
  case ptic_far_return: // sysreturn
  case ptic_far_call: // syscall
  case ptic_other:
    /* TODO: handle checking exception handlers */
    // fallthrough
  default:
    break;
  }
  s->last_was_syscall = (insn->iclass == ptic_far_call);
  s->pending_event_kind = kind;
}


/*** LIBIPT BOILERPLATE ***/
// https://github.com/intel/libipt/blob/master/doc/howto_libipt.md

static void pop_pending_section(struct decoding_state *s) {
  if(s->pending_section_head != NULL) {
    struct pending_section *popped = s->pending_section_head;
    s->pending_section_head = popped->next;

    Store_field(*s->add_section, add_section_field_filename, caml_copy_string(popped->filename));
    Store_field(*s->add_section, add_section_field_offset, Val_long(popped->offset));
    Store_field(*s->add_section, add_section_field_size, Val_long(popped->size));
    Store_field(*s->add_section, add_section_field_vaddr, Val_long(popped->vaddr));
    Store_field(*s->add_section, add_section_field_isid, Val_int(popped->isid));
    s->pending_decode_result = decode_result_add_section;

    free(popped->filename);
    free(popped);
  }
}

static int handle_events(struct decoding_state *s, int status) {
  while (status & pts_event_pending) {
    struct pt_event event;

    status = pt_insn_event(s->decoder, &event, sizeof(event));
    if (status < 0) break;

    handle_event(s, &event);
    if (s->pending_decode_result != decode_result_none) break;
  }

  return status;
}

// Turn this to true to enable debug printing for decoding issues
static const bool debug_decoding = false;

static int decode_until_event(struct decoding_state *s) {
  uint64_t offset;
  int status = s->saved_status;

  pop_pending_section(s);
  if (s->pending_decode_result != decode_result_none) return 0;

  if(!s->pt_synced) {
    status = pt_insn_sync_forward(s->decoder);
    if(debug_decoding) {
      pt_insn_get_offset(s->decoder, &offset);
      printf("1 %d %lx\n", status, offset); fflush(stdout);
    }
    if (status == -pte_eos) {
      s->pending_decode_result = decode_result_end_of_trace;
      return 0;
    }
    if (status < 0) return status;
    s->pt_synced = true;
  }

  for (;;) {
    struct pt_insn insn;
    status = handle_events(s, status);
    if(debug_decoding) {
      printf("2 %s %d\n", pt_errstr(-status), s->pending_decode_result); fflush(stdout);
    }
    if (status < 0) goto decode_error;
    if (s->pending_decode_result != decode_result_none) break;
    pop_pending_section(s);
    if (s->pending_decode_result != decode_result_none) break;

    status = pt_insn_next(s->decoder, &insn, sizeof(insn));
    if(debug_decoding) {
      printf("3 %s %d\n", pt_errstr(-status), s->pending_decode_result); fflush(stdout);
    }
    if (insn.iclass != ptic_error) {
      handle_instruction(s, &insn);
    }
    if (status < 0) goto decode_error;
    if (s->pending_decode_result != decode_result_none) break;
  }

  s->saved_status = status;
  return status;

decode_error:
  if(debug_decoding) {
    pt_insn_get_offset(s->decoder, &offset);
    printf("error %s at %lx\n", pt_errstr(-status), offset); fflush(stdout);
  }
  Store_field(*s->event, event_field_kind, Val_int(event_kind_decode_error));
  commit_event(s);
  s->pt_synced = false;
  s->saved_status = 0;
  return 0;
}


static void do_add_section_callback(void *s_void, const char *filename, uint64_t offset,
                             uint64_t size, uint64_t vaddr, int isid) {
  if (filename[0] != '/') return;
  struct decoding_state *s = s_void;

  struct pending_section *section = malloc(sizeof(*section));
  section->filename = strdup(filename);
  section->offset = offset;
  section->size = size;
  section->vaddr = vaddr;
  section->isid = isid;
  section->next = s->pending_section_head;
  s->pending_section_head = section;
}

static int add_initial_images(struct decoding_state *s, value mmap_list, uint32_t pid) {
  CAMLparam1(mmap_list);
  CAMLlocal3(list, cur, filename_val);

  int error = 0;
  struct pt_sb_context *context;
  error = pt_sb_get_context_by_pid(&context, s->session, pid);
  if(error < 0) CAMLreturn(error);

  for (list = mmap_list; Is_block(list); list = Field(list, 1)) {
    cur = Field(list, 0);
    filename_val = Field(cur, mmap_field_filename);
    const char *filename = String_val(filename_val);
    uint64_t
      vaddr  = Long_val(Field(cur, mmap_field_vaddr)),
      size   = Long_val(Field(cur, mmap_field_length)),
      offset = Long_val(Field(cur, mmap_field_offset));
    if (filename[0] != '/') continue;

    error = pt_sb_ctx_mmap(s->session, context, filename, offset, size, vaddr);
    if (error < 0) break;
  }

  CAMLreturn(error);
}

static int setup_decoding(struct decoding_state *s, value setup_info, value sb_filename) {
  CAMLparam2(setup_info, sb_filename);
  int error;

  // mmap
  off_t pt_length = lseek(s->pt_fd, 0, SEEK_END);
  if (pt_length == -1) CAMLreturn (-1);
  s->pt_length = pt_length;
  s->pt_mmap = mmap(NULL, pt_length, PROT_READ, MAP_SHARED, s->pt_fd, 0);

  if (s->pt_mmap == MAP_FAILED) CAMLreturn (-1);

  value trace_meta = Field(setup_info, setup_info_field_trace_meta);

  // instruction decoder
  struct pt_config config;

  memset(&config, 0, sizeof(config));
  config.size = sizeof(config);
  config.begin = s->pt_mmap;
  config.end = s->pt_mmap + s->pt_length;
  config.flags.variant.insn.enable_tick_events = 1;

  config.nom_freq = Long_val(Field(trace_meta, trace_meta_field_max_nonturbo_ratio));

  s->decoder = pt_insn_alloc_decoder(&config);
  if (!s->decoder) CAMLreturn (-pte_bad_config);

  // image cache
  s->iscache = pt_iscache_alloc(NULL);
  if (!s->iscache) CAMLreturn (-1);
  pt_iscache_set_file_hook(s->iscache, do_add_section_callback, s);

  // pevent sideband
  s->session = pt_sb_alloc(s->iscache);
  if (!s->session) CAMLreturn(-1);

  struct pt_sb_pevent_config pevent;
  memset(&pevent, 0, sizeof(pevent));
  pevent.primary = 1;
  pevent.size = sizeof(pevent);
  pevent.kernel_start = UINT64_MAX;
  pevent.filename = String_val(sb_filename);
  pevent.begin = pevent.end = 0;
  pevent.sample_type = s->pev_config.sample_type =
    PERF_SAMPLE_IP | PERF_SAMPLE_TID | PERF_SAMPLE_TIME;

  pevent.time_shift = s->pev_config.time_shift =
    Long_val(Field(trace_meta, trace_meta_field_time_shift));
  pevent.time_mult = s->pev_config.time_mult =
    Long_val(Field(trace_meta, trace_meta_field_time_mult));
  pevent.time_zero = s->pev_config.time_zero =
    Long_val(Field(trace_meta, trace_meta_field_time_zero));

  // Use these for debugging with libipt tooling
  // printf("--cpu 6/85/7 --cpuid-0x15.ebx %u --cpuid-0x15.eax %u --nom-freq %u --mtc-freq %u\n",
  //     config.cpuid_0x15_ebx, config.cpuid_0x15_eax, config.nom_freq, config.mtc_freq);
  // printf("--pevent:sample-type %lu --pevent:time-shift %u --pevent:time-mult %u --pevent:time-zero %lu --pevent:primary %s\n",
  //   pevent.sample_type, pevent.time_shift, pevent.time_mult, pevent.time_zero, pevent.filename);

  error = pt_sb_alloc_pevent_decoder(s->session, &pevent);
  if (error < 0) CAMLreturn (error);

  error = pt_sb_init_decoders(s->session);
  if (error < 0) CAMLreturn (error);

  intnat pid = Long_val(Field(setup_info, setup_info_field_pid));
  error = add_initial_images(s, Field(setup_info, setup_info_field_initial_maps), pid);
  if (error < 0) CAMLreturn (error);

  CAMLreturn (error);
}

/*** OCAML STUBS ***/

#define Decoding_state_val(v) (*((struct decoding_state **) Data_custom_val(v)))

static void finalize_decoding_state(value v) {
  destroy_decoding_state(Decoding_state_val(v));
}


static struct custom_operations decoding_state_ops =
  { .identifier = "com.janestreet.magic-trace.decoding_state"
  , .finalize = finalize_decoding_state
  , .compare = custom_compare_default
  , .compare_ext = custom_compare_ext_default
  , .hash = custom_hash_default
  , .serialize = custom_serialize_default
  , .deserialize = custom_deserialize_default
  , .fixed_length = custom_fixed_length_default
  };


CAMLprim value magic_pt_init_decoder_stub(value config) {
  CAMLparam1(config);
  CAMLlocal1(v);

  struct decoding_state *state = malloc(sizeof(*state));
  v = caml_alloc_custom(&decoding_state_ops, sizeof(state), 0, 1);
  Decoding_state_val(v) = state;

  memset(state, 0, sizeof(*state));
  state->pt_fd = Int_val(Field(config, config_field_pt_data_fd));
  state->pending_event_kind = event_kind_none;
  state->last_was_syscall = false;
  state->pt_synced = false;
  state->pending_section_head = NULL;
  state->saved_status = 0;
  pev_config_init(&state->pev_config);

  int status = setup_decoding(state,
    Field(config, config_field_setup_info),
    Field(config, config_field_sideband_filename));

  if(status < 0) {
    destroy_decoding_state(state);
    caml_failwith(pt_errstr(-status));
  }

  CAMLreturn(v);
}

CAMLprim value magic_pt_run_decoder_stub(value state_v, value event, value add_section) {
  CAMLparam3(state_v, event, add_section);

  struct decoding_state *state = Decoding_state_val(state_v);

  // We need to shove these in the state instead of using another parameter because of the
  // add_section callback only having access to the state.
  state->event = &event;
  state->add_section = &add_section;
  state->pending_decode_result = decode_result_none;

  int result = decode_until_event(state);

  state->event = NULL;
  state->add_section = NULL;

  if(result < 0) {
    caml_failwith(pt_errstr(-result));
  }

  enum decode_result decode_result = state->pending_decode_result;
  assert(decode_result >= 0);
  CAMLreturn(Val_int(decode_result));
}
