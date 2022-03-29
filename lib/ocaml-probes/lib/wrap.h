// untested
static inline long ptrace_traceme()
{ return ptrace(PT_TRACE_ME, 0, (caddr_t)1, 0); }

static inline long ptrace_attach(pid_t pid)
{ return ptrace(PT_ATTACHEXC, pid, (caddr_t)1, 0); }

/* static inline long ptrace_cont(pid_t pid) */
/* { return ptrace(PT_CONTINUE, pid, (caddr_t)1, 0); } */

static inline long ptrace_detach(pid_t pid)
{ return ptrace(PT_DETACH, pid, (caddr_t)1, 0); }

static inline long ptrace_kill(pid_t pid)
{ return ptrace(PT_KILL, pid, (caddr_t)1, 0); }

static inline long get_mem(pid_t pid, void *addr, vm_prot_t prot)
{
  kern_return_t kret;
  mach_port_t task;
  unsigned long res;
  pointer_t buffer;
  uint32_t size;

  kret = task_for_pid(mach_task_self(), pid, &task);
  if ((kret!=KERN_SUCCESS) || !MACH_PORT_VALID(task))
    {
      fprintf(stderr, "task_for_pid failed: %s!\n",mach_error_string(kret));
      exit(2);
    }

  kret = vm_protect(task, (vm_address_t) addr, sizeof (unsigned long),
                    FALSE, prot);
  if (kret!=KERN_SUCCESS)
  {
    fprintf(stderr, "vm_protect failed: %s!\n", mach_error_string(kret));
    exit(2);
  }

  kret = vm_read(task, (vm_address_t) addr, sizeof(unsigned long), &buffer,
                 &size);
  if (kret!=KERN_SUCCESS)
  {
    fprintf(stderr, "vm_read failed: %s!\n",mach_error_string(kret));
    exit(2);
  }
  res = *((unsigned long *) buffer);
  return res;
}

static inline long set_mem(pid_t pid, void *addr, void *data, vm_prot_t prot)
{
  kern_return_t kret;
  mach_port_t task;

  kret = task_for_pid(mach_task_self(), pid, &task);
  if ((kret!=KERN_SUCCESS) || !MACH_PORT_VALID(task))
    {
      fprintf(stderr, "task_for_pid failed: %s!\n",mach_error_string(kret));
      exit(2);
    }

  kret = vm_protect(task, (vm_address_t) addr, sizeof (unsigned long), FALSE,
                    prot);
  if (kret!=KERN_SUCCESS)
  {
    fprintf(stderr, "vm_protect failed: %s!\n", mach_error_string(kret));
    exit(2);
  }

  kret = vm_write(task, (vm_address_t) addr, (vm_address_t) data,
                  sizeof(unsigned long));
  if (kret!=KERN_SUCCESS)
  {
    fprintf(stderr, "vm_write failed: %s!\n", mach_error_string(kret));
    exit(2);
  }
  return 0;
}

static inline long ptrace_get_text(pid_t pid, void *addr)
{ return get_mem(pid,addr, VM_PROT_READ | VM_PROT_EXECUTE); }

static inline long ptrace_set_text(pid_t pid, void *addr, void *data)
{
  return set_mem(pid,addr,data,VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
}

static inline long ptrace_get_data(pid_t pid, void *addr)
{ return get_mem(pid,addr, VM_PROT_READ); }

static inline long ptrace_set_data(pid_t pid, void *addr, void *data)
{ return set_mem(pid,addr,data,VM_PROT_READ | VM_PROT_WRITE); }
