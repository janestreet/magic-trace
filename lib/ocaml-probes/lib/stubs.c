#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdbool.h>
#include <stdarg.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/ptrace.h>
#include <sys/mman.h>
#include <sys/uio.h>

/* #ifdef OCAML_OS_TYPE == "Unix" */
#if defined(__GNUC__) && (defined (__ELF__))
#include <linux/ptrace.h>

static inline long ptrace_traceme()
{ return ptrace(PTRACE_TRACEME, 0, NULL, NULL); }

static inline long ptrace_attach(pid_t pid)
{ return ptrace(PTRACE_ATTACH, pid, NULL, NULL); }

/* static inline long ptrace_cont(pid_t pid) */
/* { return ptrace(PTRACE_CONT, pid, NULL, NULL); } */

static inline long ptrace_detach(pid_t pid)
{ return ptrace(PTRACE_DETACH, pid, NULL, NULL); }

static inline long ptrace_kill(pid_t pid)
{ return ptrace(PTRACE_KILL, pid, NULL, NULL); }

static inline long ptrace_get_text(pid_t pid, void *addr)
{ return ptrace(PTRACE_PEEKTEXT, pid, addr, NULL); }

static inline long ptrace_set_text(pid_t pid, void *addr, void *data)
{ return ptrace(PTRACE_POKETEXT, pid, addr, data); }

static inline long ptrace_get_data(pid_t pid, void *addr)
{ return ptrace(PTRACE_PEEKDATA, pid, addr, NULL); }

static inline long ptrace_set_data(pid_t pid, void *addr, void *data)
{ return ptrace(PTRACE_POKEDATA, pid, addr, data); }

#elif defined(__APPLE__)
// untested
#include <mach/mach_types.h>
#include <mach/mach.h>
#include <wrap.h>
#endif

#include <sys/user.h>
#include <sys/wait.h>

#include <caml/fail.h>
#include <caml/callback.h>
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>

// Error handling
static bool verbose = false;

static inline void v_raise_error(const char *fmt, va_list argp)
{
  int n = 256;
  char buf[n];
  vsnprintf(buf,n,fmt,argp);
  if (verbose) fprintf(stderr,"Error: %s\n", buf);
  const value *ex = caml_named_value("probes_lib_stub_exception");
  if (ex == NULL) {
    fprintf(stderr, "Fatal error: exception "
            "probes_lib_stub_exception ");
    vfprintf(stderr, fmt, argp);
    exit(2);
  }
  caml_raise_with_string(*ex, buf);
}

static inline void raise_error(const char * msg, ...) {
  va_list args;
  va_start (args, msg);
  v_raise_error(msg, args);
  va_end (args);
}

static bool kill_child_on_error = false;

static inline void signal_and_error(pid_t cpid, const char * msg, ...)
{
  if (kill_child_on_error) {
    ptrace_kill(cpid);
    wait(NULL);
  }
  va_list args;
  va_start (args, msg);
  v_raise_error(msg, args);
  va_end (args);
}

static inline void vm_simple(bool read, /* 1 read, 0 write */
                             pid_t cpid,
                             unsigned long addr,
                             ssize_t n,
                             void *data)
{
  struct iovec local[1];
  local[0].iov_base = data;
  local[0].iov_len = n;
  struct iovec remote[1];
  remote[0].iov_base = (void *) addr;
  remote[0].iov_len = n;

  ssize_t m = 0;
  errno = 0;
  if (read)
    m = process_vm_readv(cpid, local, 1, remote, 1, 0);
  else
    m = process_vm_writev(cpid, local, 1, remote, 1, 0);
  if ((m == -1) || (errno !=0)) {
    raise_error ("process_vm_readv or process_vm_writev failed (pid=%d, addr=%lx:\n%s\n",
                 (strerror));
  } else if (m != n)
    raise_error ("process_vm_%sv: done %d instead of %d byte for pid %d from %lx\n",
                 (read?"read":"write"),
                 m, n, cpid, addr);
}


// read n consecutive bytes from addr in remote process cpid memory
static inline void vm_read_simple(pid_t cpid, unsigned long addr, ssize_t n, void *res)
{
  vm_simple(1, cpid, addr, n, res);
}


// write n consecutive bytes to addr in remote process cpid memory
static inline void vm_write_simple(pid_t cpid, unsigned long addr, ssize_t n, void *data)
{
  vm_simple(0, cpid, addr, n, data);
}


/* Keep in sync with [type mode] in probes_lib.ml */
typedef enum mode { Mode_self, Mode_ptrace, Mode_vm } mode;

// The crux: update probes and semaphores

#define CMP_OPCODE 0x3d
#define CALL_OPCODE 0xe8

// when the semaphore is read using ptrace,
// the entire word that was read is also returned in [data].
// it'll be used to write updated value back,
// because peek/poke work on words only.
static inline uint16_t read_semaphore_ptrace(pid_t cpid,
                                                   unsigned long addr,
                                                   signed long *data)
{
  // initialize to an invalid value:
  // will raise later if not read correctly in the next block.
  uint16_t semaphore = 0;
  // semaphore is only 2 bytes long, but we can only read a whole word.
  // extract the 2 bytes from the word
  errno = 0;
  *data = ptrace_get_data(cpid, (void *) addr);
  if (errno != 0)
    raise_error ("read_semaphore for probe in pid %d: "
                 "failed to PEEKDATA at %lx with errno %d: %s",
                 cpid, addr, errno, strerror(errno));
  semaphore = (uint16_t) (*data & 0xffff);
  if (verbose)
    fprintf (stderr, "semaphore at %lx = %lx (short:%x)\n",
             addr, *data, semaphore);
  return semaphore;
}

static inline void write_semaphore_ptrace(pid_t cpid,
                                          unsigned long addr,
                                          uint16_t new_semaphore)
{
  // when the semaphore is written using ptrace,
  // the entire word that was read from [addr] must also be provided,
  // because peek/poke work on words only.
  signed long cur_data = 0;
  read_semaphore_ptrace(cpid, addr, &cur_data);
  // semaphore is only 2 bytes long, be we can only write a whole word.
  // modify the current word and put back the whole word back.
  unsigned long new_data = (cur_data & ~0xffff) | ((long) new_semaphore);
  if (verbose) fprintf (stderr, "new data at %lx: %lx\n", addr, new_data);
  if (ptrace_set_data(cpid, (void *) addr, (void *) new_data)) {
    raise_error ("wirte_semaphore for probe in pid %d:"
                 "failed to POKEDATA at %lx new val=%lx with errno %d\n"
                 "%s\n",
                 cpid, addr, new_data, errno, strerror(errno));
  }
}

static inline uint16_t read_semaphore_vm (pid_t cpid,
                                          unsigned long addr)
{
  uint16_t semaphore = 0;
  vm_read_simple(cpid, addr, 2, &semaphore);
  return semaphore;
}

static inline void write_semaphore_vm (pid_t cpid,
                                       unsigned long addr,
                                       uint16_t new_semaphore)
{
  vm_write_simple(cpid, addr, 2, &new_semaphore);
}

static inline uint16_t read_semaphore_self(unsigned long addr)
{
  uint16_t semaphore = *((uint16_t *) addr);
  if (verbose) fprintf (stderr, "semaphore at %lx = %x\n", addr,
                        semaphore);
  return semaphore;
}

static inline void write_semaphore_self(unsigned long addr,
                                        uint16_t new_semaphore)
{
   *((uint16_t *)addr) = new_semaphore;
}

static inline bool is_enabled_opcode(uint8_t byte, pid_t cpid,
                                     unsigned long addr)
{
  switch (byte) {
  case CMP_OPCODE: return false;
  case CALL_OPCODE: return true;
  default: raise_error ("Unexpected instruction opcode %x at %lx for pid %d",
                        byte, addr, cpid);
  }
  __builtin_unreachable();
}

static inline uint8_t get_opcode(bool enable)
{
  return (enable ? CALL_OPCODE : CMP_OPCODE);
}

static inline uint8_t read_opcode_self (unsigned long addr)
{
  uint8_t opcode = *((uint8_t *) addr);
  if (verbose) fprintf (stderr, "cur at %lx: %x\n",
                        addr, opcode);
  return opcode;
}

static inline void write_opcode_self (unsigned long addr,
                                      uint8_t opcode)
{
  static long pagesize = 0;
  if (pagesize == 0) pagesize = sysconf(_SC_PAGE_SIZE);
  if (pagesize == -1) raise_error ("cannot get pagesize");
  long pagestart = addr & ~(pagesize-1);
  errno = 0;
  if (mprotect((void *)pagestart, pagesize,
               PROT_READ | PROT_EXEC | PROT_WRITE)) {
    raise_error (
                 "modify_probe in self"
                 "(self) mprotect add write prot failed at %lx"
                 "(pagestart=%lx, pagesize=%lx) with errno %d",
                 addr, pagestart, pagesize, write, errno);
  }

  *((uint8_t *) addr) = opcode;
  errno = 0;
  if (mprotect((void *)pagestart, pagesize,  PROT_READ | PROT_EXEC)) {
    raise_error (
                 "modify_probe in self:"
                 "(self) mprotect remote write prot failed at %lx"
                 "(pagestart=%lx, pagesize=%lx) with errno %d",
                 addr, pagestart, pagesize, write, errno);
  }
}

static inline uint8_t read_opcode_ptrace (pid_t cpid,
                                          unsigned long addr,
                                          unsigned long *data)
{
  uint8_t opcode = 0;
  errno = 0;
  *data = ptrace_get_text(cpid, (void *) addr);
  opcode = (uint8_t) (*data & 0xff);
  if (errno != 0)
    raise_error ("read_opcode of probe in pid %d: "
                 "failed to PEEKTEXT at %lx with errno %d\n",
                 cpid, addr, errno);
  if (verbose) fprintf (stderr, "cur at %lx: %x with data = %lx\n",
                        addr, opcode, *data);
  return opcode;
}

static inline uint8_t read_opcode_vm (pid_t cpid,
                                      unsigned long addr)
{
  uint8_t opcode = 0;
  vm_read_simple(cpid, addr, 1, &opcode);
  return opcode;
}

static inline void write_opcode_ptrace (pid_t cpid,
                                        unsigned long addr,
                                        uint8_t opcode,
                                        unsigned long data)
{
  data = (data & ~0xff) | opcode;
  if (verbose) fprintf (stderr, "new at %lx: %lx\n", addr, data);
  if (ptrace_set_text(cpid, (void *) addr, (void *) data)) {
    raise_error ("modify_probe in pid %d: "
                 "failed to POKETEXT at %lx new val=%lx with errno %d\n",
                 cpid, addr, data, errno);
  }
}

static inline void write_semaphore(mode mode,
                                   pid_t cpid,
                                   unsigned long addr,
                                   uint16_t sem)
{
  switch (mode) {
  case Mode_self: write_semaphore_self(addr, sem); return;
  case Mode_ptrace: write_semaphore_ptrace(cpid, addr, sem); return;
  case Mode_vm: write_semaphore_vm(cpid, addr, sem); return;
  default: raise_error ("mode undefined %d\n", mode);
  }
}


static inline uint16_t read_semaphore(mode mode,
                                            pid_t cpid,
                                            unsigned long addr)
{
  signed long data = 0;
  switch (mode) {
  case Mode_self: return read_semaphore_self(addr);
  case Mode_vm: return read_semaphore_vm(cpid, addr);
  case Mode_ptrace:
    // data is ignored
    return read_semaphore_ptrace(cpid, addr, &data);
  default: raise_error ("mode undefined %d\n", mode);
  }
  __builtin_unreachable ();
}


static inline uint8_t read_opcode(mode mode,
                                  pid_t cpid,
                                  unsigned long addr,
                                  unsigned long *data)
{
  switch (mode) {
  case Mode_self: return read_opcode_self(addr);
  case Mode_vm: return read_opcode_vm(cpid, addr);
  case Mode_ptrace: return read_opcode_ptrace(cpid, addr, data);
  default: raise_error ("mode undefined %d\n", mode);
  }
  __builtin_unreachable ();
}

static inline void write_opcode(mode mode,
                                pid_t cpid,
                                unsigned long addr,
                                uint8_t op,
                                unsigned long data)
{
  switch (mode) {
  case Mode_self: write_opcode_self(addr, op); return;
  case Mode_vm: raise_error ("cannot vm_process_write at 0x%x: opcode\n", addr);
  case Mode_ptrace: write_opcode_ptrace(cpid, addr, op, data); return;
  default: raise_error ("mode undefined %d\n", mode);
  }
  __builtin_unreachable ();
}

static inline void modify_opcode(mode mode,
                                 pid_t cpid,
                                 unsigned long addr,
                                 bool enable)
{
  unsigned long data = 0;
  // It is not necessary to read_opcode in Mode_self,
  // but for safety we keep it here to make sure we don't modify memory
  // that contains something completely unexpected.
  uint8_t opcode = read_opcode(mode, cpid, addr, &data);
  is_enabled_opcode(opcode, cpid, addr);
  uint8_t new_opcode = get_opcode(enable);
  if (opcode != new_opcode) {
    write_opcode(mode, cpid, addr, new_opcode, data);
  }
}

/* ptrace calls, nothing specific to probes */
CAMLprim value probes_lib_start_ptrace (value v_argv)
{
  CAMLparam1(v_argv); /* string array , boolean */
  int argc = Wosize_val(v_argv);
  if (verbose) fprintf(stderr, "start: argc=%d\n", argc);

  if (argc < 1) {
    raise_error("Missing executable name\n");
  }
  char ** argv = (char **) malloc ((argc + 1 /* for NULL */)
                                   * sizeof(char *));
  for (int i = 0; i < argc; i++) {
    argv[i] = strdup(String_val(Field(v_argv, i)));
    if (verbose) fprintf(stderr, "start: argv[%d]=%s\n", i, argv[i]);
  }
  argv[argc] = NULL;


  pid_t cpid = fork();
  if (cpid == -1) {
    raise_error("error doing fork\n");
  }

  if (cpid==0) {
    if (ptrace_traceme()) {
      raise_error("ptrace traceme error\n");
    }
    errno = 0;
    execv(argv[0], argv);

    /* only get here on an exec error */
    if (errno == ENOENT)
      raise_error("error running exec: program not found\n");
    else if (errno == ENOMEM)
      raise_error("error running exec: not enough memory\n");
    else
      raise_error("error running exec\n");
  }

  int status = 0;
  wait(&status);
  if (!WIFSTOPPED(status)) {
    signal_and_error(cpid, "not stopped %d\n", status);
  }

  for (int i = 0; i < argc; i++) {
    free(argv[i]);
  }
  free (argv);
  CAMLreturn(Val_long(cpid));
}

CAMLprim value probes_lib_attach (value v_pid)
{
  pid_t cpid = Long_val(v_pid);
  if(ptrace_attach(cpid)) {
    raise_error("ptrace attach %d, error=%d\n", cpid, errno);
  }

  int status = 0;
  pid_t res = waitpid(cpid, &status, WUNTRACED);
  if ((res != cpid) || !(WIFSTOPPED(status)) ) {
    raise_error ("Unexpected wait result res %d stat %x\n",res,status);
  }
  return Val_unit;
}

CAMLprim value probes_lib_detach (value v_pid)
{
  pid_t cpid = Long_val(v_pid);
  if (ptrace_detach(cpid)) {
    signal_and_error(cpid, "could not detach %d, errno=%d\n", cpid, errno);
  }
  return Val_unit;
}

value probes_lib_read_semaphore (value v_mode,
                                  value v_pid,
                                  value v_address)
{
  CAMLparam1(v_address);
  mode mode = Long_val(v_mode);
  pid_t cpid = Long_val(v_pid);
  unsigned long address = Int64_val(v_address);
  CAMLreturn(Val_long(read_semaphore(mode, cpid, address)));
}

value probes_lib_write_semaphore (value v_mode,
                                   value v_pid,
                                   value v_addresses,
                                   value v_sem)
{
  CAMLparam1(v_addresses);
  CAMLlocal1(v_address);
  mode mode = Long_val(v_mode);
  pid_t cpid = Long_val(v_pid);
  uint16_t new_sem = Long_val(v_sem);
  int n = Wosize_val(v_addresses);
  for (int i = 0; i < n; i++) {
    v_address = Field(v_addresses, i);
    const uint64_t address = Int64_val(v_address);
    write_semaphore(mode, cpid, address, new_sem);
  }
  CAMLreturn(Val_unit);
}


value probes_lib_write_probes (value v_mode,
                               value v_pid,
                               value v_addresses,
                               value v_enable)
{
  CAMLparam1(v_addresses);
  CAMLlocal1(v_address);
  mode mode = Long_val(v_mode);
  pid_t cpid = Long_val(v_pid);
  bool enable = Bool_val(v_enable);
  int n = Wosize_val(v_addresses);
  for (int i = 0; i < n; i++) {
    v_address = Field(v_addresses, i);
    const uint64_t address = Int64_val(v_address);
    modify_opcode(mode, cpid, address, enable);
  }
  CAMLreturn(Val_unit);
}

CAMLprim value probes_lib_set_verbose(value v_bool)
{
  verbose = Bool_val(v_bool);
  return Val_unit;
}

CAMLprim value probes_lib_realpath(value v_filename)
{
  CAMLparam1(v_filename);
  const char *filename = String_val(v_filename);
  char *res = realpath(filename, NULL);
  if (res == NULL)
    raise_error ("could not get realpath of %s\n", filename);
  value v_res = caml_copy_string(res);
  free(res);
  CAMLreturn(v_res);
}
