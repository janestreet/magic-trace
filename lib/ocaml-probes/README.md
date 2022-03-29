Tracing probes for OCaml
========================

Experimental mechanism for tracing OCaml native programs in user-space.

Provides a way to track program behaviour by inspecting program state
at certain points (called probes) while the program executes.  For
example, it can be used to turn on and off performance monitoring and
debug logging in a running program, without having to restart or
recompile it.

The tracing mechanism consists of two parts:

1) OCaml compiler support for defining probes in OCaml native code.

2) A command-line tracer tool `ocaml-probes` (also available as
   a library, `ocaml-probes-lib`) to control the behaviour of probes
   at runtime.


## Installation using OPAM

```
opam switch create probes-411 --empty
opam pin add ocaml-variants https://github.com/gretay-js/ocaml.git#411+probes
opam pin add probes https://github.com/gretay-js/probes.git
```

Requires shexp v0.14-preview.122.11+261 or later.

##  Quick start

Trace a short program instrumented with probes:
```
dune build test/terminating/test.exe
ocaml-probes trace -prog _build/default/test/terminating/test.exe
```

Attach to a service instrumented with probes:

`dune build example/test.exe`

Assuming that `test.exe` is running somewhere in the background:
```
ocaml-probes attach -pid `pgrep test.exe` -enable-all
ocaml-probes info -pid `pgrep test.exe`
ocaml-probes attach -pid `pgrep test.exe` -disable fooia
ocaml-probes info -pid `pgrep test.exe`
```

## How to add a tracing probe to an OCaml program

A probe is defined using OCaml's extension point syntax as follows:

    [%probe <name> <handler>]

where `<name>` is a string literal without spaces or special
characters and `<handler>` is an arbitrary
OCaml expression of type `unit`.

For example:

    let foo x y =
        [%probe "my_first_probe" (myprint "from foo" x y)]
        bar x y


By default, all probes are disabled when the program starts.  A
disabled probe does not do anything and does not cost almost anything
at runtime, and in particular, the handler is not evaluated at all.

If a probe is enabled, whenever the execution reaches it, the
corresponding handler is evaluated.

A probe can be enabled and disabled during program execution. There is
no need to restart a running program or recompile the code to enable
or disable a probe.

Some examples of what a probe handler can do:

 - collect performance counters

 - write to a log file

 - write data into a ring buffer or similar for transmission to a
   another tool that can analyze or visualize it.

## The `ocaml-probes` tool

Start a program with all probes enabled:

    ocaml-probes trace -prog test.exe

Attach to a running program and enable probes named "myprobe":

    ocaml-probes attach -pid 1234 -enable myprobe

Attach to a running program and disable all probes:

    ocaml-probes attach -pid 1234 -disable-all

List all ocaml probes and whether they are enabled or not:

    ocaml-probes info -pid 1234

### Probe names

Probe names are used by the tracer to specify which probes to enable and
disable. More than one probe can be defined with the same name. For example:

    let foo (x:int) (y:float) =
       [%probe "boo" (print_myint x)];
       [%probe "boo" (print_myfloat y)];
       ..

Enabling a probe with name `boo` results in enabling all probes with
this name in all compilation units.

It can be used to group related probes so that they can be
enabled/disabled all at once.


### Requirements

Currently only supported on Linux amd64.

The tracer uses `ptrace` to start a new process or attach to a running
process and change its memory.

The tracing is performed entirely in user-space. There is no need to
switch to kernel space. The tracer binary does not need to have setuid
or elevated permissions to enable or disable the probes or execute the
handler. The only requirement is that the user is permitted to invoke
`ptrace`, which is the same requirement as for using `gdb`.



## Performance impact of disabled probes

For each probe, the compiler generates a short instruction
that has no effect on the execution when the probe is disabled.

We aim to ensure that the presence of probes does not affect inlining
decisions and does not cause additional allocation.
The cost of `[%probe ..]` for the purpose of inlining is set to 0 by
the compiler. The cost of `[%probe_is_enabled ...]` is the same as
reading a global variable.

We need to be careful about handler expressions using variables, bound to
closures, that would not otherwise be needed in the enclosing code.  If the
closure is not lifted to a symbol, there might be an extra load or allocation
even when the probe is disabled.

The presence of probes can cause some changes in code generation.  A probe
handler can refer to variables from the enclosing code, which might affect
register allocation and spill code generation (e.g., by changing the relative
importance of variables or extending their live ranges).  However with care
writing probe handlers these changes should be able to be kept to a minimum.


## Can I use OCaml probes with my favorite tracing tool?


Probes defined in OCaml code
using `[%probe]` syntax can be traced with Systemtap.  The OCaml
compiler emits the information required by Systemtap to identify the
probe locations in the ELF executable.  Other tools, such as `dtrace`,
`gdb`, and `perf probe`, can decode this format and hence find
probes as well.  However, external tracing tools do not know anything
about OCaml probe handlers, only the locations of the
probes. Unlike probe handlers defined using eBPF or Systemtap scripts, OCaml probe
handlers can execute arbitrary OCaml code.


### Semaphores

With Systemtap, arguments of a probe are always evaluated, regardless of
whether the probe is enabled or not. This may be costly, so systemtap
provides a relatively cheap test to determine if a probe is enabled:

    if (SDT_PROBES_TEST_1_ENABLED())
      SDT_PROBES_TEST_1(expensive_function(s));

**This test is not needed for OCaml probes** because the handler
expression is not evaluated at all when the probe is disabled.  This
test is exposed in OCaml using `[%probe_is_enabled]` syntax for
the programmer's convenience only.

In systemtap, this test is implemented using global variables, known
as `semaphores` (even though they do not seem to perform any
synchronization).  For consistency with systemtap, OCaml compiler
emits semaphores for all OCaml probes and the tracer maintains
them.

### Example using gdb

For example, we can list OCaml probes and their state using `gdb`.
Use `info probes` command to list all the probes and find
probes provided by `ocaml`:

    gdb ./test.exe -ex 'info probes' -ex q

    Provider Name    Where              Semaphore          Object
    ocaml    myprobe 0x00000000004abcd4 0x000000000065432 test.exe

The output also shows addresses of the semaphores. Read the value of
the semaphores to see which probes are enabled, when the program is
stopped with `gdb`.
