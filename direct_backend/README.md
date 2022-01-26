# The magic-trace direct backend and ideas for the future

The `direct_backend` subdirectory of `magic-trace` contains an
alternative backend which directly uses `perf_event_open` and the
`libipt` library to capture the Processor Trace data and decode it.
This is faster for decoding than going via the `perf` command, and
gives more control, but had more gotchas and needed more work than
initially expected.

It works, but currently it doesn't support decoding usage of the Linux
vDSO, which means whenever a vDSO syscall like getting the current time
happens, it causes a trace decoding error leading to a short gap in the
trace. It's also missing many other features `perf` has like
multi-threaded recording and capturing multiple snapshots.

It remains here because it represents a substantial investment in
figuring out how to directly use `perf_event_open` with Intel Processor
Trace and `libipt` together, the only such example code I know of.
Should anyone want to do something that requires deeper control over
Processor Trace, they may need this code. That's also why it's
open-sourced despite it not (yet) being set up to build outside the
Jane Street tree, because it's potentially valuable reference code.

## The demand for instruction-level information

The main reason we started down the path to this backend is that the
basic `perf` backend of `magic-trace` doesn't properly follow the
effect of OCaml exceptions on the stack. Doing so requires noticing the
instructions that push, pop and raise from the OCaml exception handler
stack, which aren't branches and so aren't listed in perf's branch
output.

The initial purpose of the `libipt` backend, as well as increased
decoding performance, was enabling instruction-by-instruction decoding
so we could follow exceptions properly.

## An alternative approach

During the process of implementing the direct backend, it became clear
that the task was more difficult than we thought, and a picture of an
alternative approach emerged, on that seemed like potentially less work
than bringing the direct backend up to where `perf` is.

Here's a sketch about what the future of `magic-trace` could look like:

### perf dlfilter

Newer versions of `perf` have a feature called `perf-dlfilter` that
allows `perf` to load a shared library which gets callbacks for decoded
events using a C API. This was specifically designed to allow consuming
Intel Processor Trace data very quickly and without text parsing.

We could implement a small shared library in something that's easy to
connect with a C interface, like C/Rust/Zig, that does the following:

- Filter out jumps that are within the same symbol, currently we need
  to process and discard all of these in OCaml, which is inefficient.
- Write out info about the relevant events in an efficient binary
  format that's easy to consume from OCaml, potentially even Fuchsia
  Trace Format.

This would achieve the goal of improving decoding performance with much
less tricky C code and without reimplementing so many `perf` features.

### perf --control

Currently we tell `perf` to take snapshots by sending it `SIGUSR2`.
This requires some arbitrary wait timers and has some issues reliably
capturing snapshots when a process shuts down. The direct backend's use
of `perf_event_open` was going to solve this.

However newer versions of perf add a `--control` flag that allows using
a FIFO with acks to toggle events and take snapshots, removing the need
for signals and waits, and also a `--snapshot=e` option to guarantee a
snapshot on end if there hasn't been another snapshot.

### instruction-level decoding using basic blocks

In order to handle OCaml exceptions we need instruction-level decoding.
This could've been done with `libipt` but an alternative way is to use
a separate instruction decoding library/tool to decode the instructions
between branch events provided by `perf`.

This would look something like having a cache of computed info for each
previously encountered basic block, for example the exception handler
pushes and pops present in it. When a new basic block (start and end
address of execution with no intervening branches) is encountered, that
range of the binary is decoded with a disassembler library and the
necessary info computed from it and put in the cache.

There's a few potential ways to do this:

- Do the basic block decoding inside the `perf-dlfilter` stub and then
  pass out the decoded info.
- Use an instruction decoding library from OCaml.
- Use an offline disassembler tool like `objdump` on the entire binary
  and fetch basic blocks from that and parse them from text. This is
  probably the simplest to do from OCaml but would run slowest.
