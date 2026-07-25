# Experimental macOS backend

This directory contains an experimental Apple Silicon backend for
`magic-trace`. It is implemented in native OCaml and produces timeline files
that can be opened by [magic-trace.org](https://magic-trace.org/) or the
standard [Perfetto UI](https://ui.perfetto.dev/).

The project currently provides two complementary paths:

1. A **working Time Profiler backend** that records a real macOS process with
   Xcode Instruments and converts its sampled stacks into estimated intervals.
2. A **synthetic Processor Trace model** that tests exact 40 ns call
   reconstruction and OCaml decoder throughput without claiming that an M1
   captured real processor-trace packets.

The implementation language is OCaml. The only C source in this directory is a
deterministic workload used by the smoke test and overhead benchmark.

## Status

| Capability | Status | Meaning |
|---|---|---|
| Launch and profile a command | Working | Uses Xcode's Time Profiler template |
| Attach to an existing process | Working | Records the selected PID |
| Convert an Instruments export | Working | Reads the `time-profile` XML schema |
| Perfetto/magic-trace.org output | Working | Writes Chrome Trace Event JSON, optionally gzip-compressed |
| Apple M1 Pro validation | Working | Build, correctness, recording, conversion, and overhead tested |
| 40 ns synthetic reconstruction | Working | Exact virtual timestamps; no sampling |
| 40 ns OCaml decoder-rate gate | Working | Median 67.36 million modeled events/s on the latest M1 Pro validation run |
| Real Apple Processor Trace capture | Not implemented | Requires supported hardware, an exportable packet source, and an ARM64 decoder |
| Original function-trigger snapshots | Not implemented | The fallback records a fixed time window |

The Time Profiler and synthetic paths answer different questions:

- Time Profiler proves that the OCaml CLI, Instruments integration,
  symbolication import, interval reconstruction, and trace export work on a
  real M1 Pro.
- The mock proves that the current OCaml decoder design can process a
  conservative 40 ns event stream faster than real time.
- Neither result proves that an M1 can perform hardware control-flow tracing.
  It cannot be made equivalent to Intel Processor Trace through faster
  software sampling.

## Why the original backend cannot simply be reused

The original Linux backend relies on Intel Processor Trace (Intel PT). The CPU
stores compressed control-flow information in hardware while the target runs;
software later combines those packets with the executable to reconstruct calls
and returns. The advertised approximately 40 ns figure is trace resolution,
not a stack-sampling interrupt every 40 ns.

Xcode Time Profiler takes periodic stack samples instead. On the validated M1
Pro configuration, the median period is 1,000,000 ns. A call that starts and
finishes between two samples is invisible, and visible function boundaries are
estimates. A 40 ns software sampler would require 25 million interrupts and
stack unwinds per second, so it is not a viable substitute for hardware trace.

## Architecture

### Real M1 fallback

```text
target process
    |
    v
Xcode xctrace / Time Profiler
    |
    v
Instruments .trace recording
    |
    v
xctrace time-profile XML export
    |
    v
OCaml XML parser and id/ref resolver
    |
    v
gap-aware sampled-stack interval reconstruction
    |
    v
Perfetto-compatible JSON or JSON.gz
```

The XML parser supports the compression used by `xctrace export`, including
reused `id`/`ref` elements and `sentinel` columns. Samples are grouped by
process and thread, stacks are converted to root-first order, and common stack
prefixes are extended across adjacent samples. Gaps close the active stack so
unobserved time is not presented as continuous execution.

Every output interval from this path is tagged as estimated from samples. The
trace metadata also records the median sampling period and a warning about
missing short calls.

### Synthetic 40 ns model

```text
deterministic nested-call workload
    |
    v
two call/return decisions per byte
plus sparse 64-bit timing anchors
    |
    v
OCaml packet decoder and call-stack machine
    |
    +--> checksum and throughput statistics
    |
    v
exact synthetic intervals in Perfetto JSON
```

The synthetic packet format is intentionally small and deterministic:

- identifiers `1` through `14` represent calls;
- identifier `0` represents a return;
- two decisions are packed into each byte;
- `0xff` introduces a little-endian 64-bit timing anchor;
- the default anchor interval is 4,096 events;
- the default virtual event spacing is exactly 40 ns.

This is an internal performance model, **not Apple's packet format**. It lets
development continue without compatible hardware and establishes an executable
performance gate for the OCaml portion of the design.

## Source layout

| File | Purpose |
|---|---|
| `magic_trace_macos.ml` | `run`, `attach`, and `convert` command-line interface |
| `magic_trace_macos_lib.ml` | Instruments control, XML parsing, interval reconstruction, and JSON writing |
| `mock_processor_trace.ml` | Synthetic packet generator, decoder, stack reconstruction, and JSON writer |
| `mock_processor_trace_cli.ml` | Creates a small visual 40 ns trace |
| `benchmark_mock_processor_trace.ml` | Measures modeled decoder throughput |
| `benchmark_overhead.ml` | Compares real target runtime with and without Time Profiler |
| `test_magic_trace_macos.ml` | Tests XML handling, sampled intervals, durations, and JSON |
| `test_mock_processor_trace.ml` | Tests exact 40 ns calls, timing anchors, and simulated metadata |
| `demo.c` | CPU-bound workload with stable, non-inlined nested functions |
| `PERFORMANCE.md` | Reproducible measurements and fidelity comparison |

## Requirements

- macOS on Apple Silicon
- A full Xcode installation containing `xctrace`
- OCaml 4.14 or newer
- Dune 3.0 or newer
- `clang` for the demonstration workload
- Developer Tools permission when macOS requests it

The production macOS code depends only on the OCaml standard library and
`unix`. It does not require Jane Street's `Core`, PPX extensions, Python, or a
new C binding.

Install the standalone build tools with Homebrew if needed:

```sh
brew install ocaml dune
```

For a standard Xcode installation, confirm that `xctrace` is available:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xctrace version
```

The backend checks `MAGIC_TRACE_XCTRACE`, the standard Xcode path, `PATH`, and
finally `xcrun`. If Xcode is installed in a nonstandard location, set
`MAGIC_TRACE_XCTRACE` to the absolute path of its `xctrace` executable.

## Quick start: record a real process

Run these commands from the repository root:

```sh
dune build macos/magic_trace_macos.exe

clang -O2 -g -Wall -Wextra -Werror \
  macos/demo.c \
  -o /tmp/magic-trace-macos-demo

_build/default/macos/magic_trace_macos.exe run \
  --duration 4s \
  --output trace.json.gz \
  --force \
  -- /tmp/magic-trace-macos-demo 2
```

The command:

1. launches the demo through `xctrace`;
2. records Time Profiler samples;
3. exports the symbolicated `time-profile` table;
4. reconstructs estimated intervals in OCaml;
5. writes `trace.json.gz`.

Open the result at [magic-trace.org](https://magic-trace.org/) or
[ui.perfetto.dev](https://ui.perfetto.dev/). Zoom into the main thread and
look for `main`, `work_a`, `work_b`, and `scramble`.

Do not expect every invocation of `scramble` to appear: it is deliberately much
shorter than the 1 ms sampling period.

## Command reference

### Record a command

```sh
_build/default/macos/magic_trace_macos.exe run \
  [--duration TIME] \
  [--output TRACE.json.gz] \
  [--keep-recording RECORDING.trace] \
  [--force] \
  -- COMMAND [ARGUMENTS...]
```

Example:

```sh
_build/default/macos/magic_trace_macos.exe run \
  --duration 5s \
  --output my-program.json.gz \
  -- ./my-program argument
```

`TIME` accepts values such as `500ms`, `5`, `5s`, `1m`, or `1h`. A bare
integer means seconds. Pick a limit long enough for a short command to start,
perform useful CPU work, and become visible to the sampler.

The launched command is terminated if it is still running when Instruments
reaches its time limit. Its standard output remains visible in the terminal.

### Attach to a process

```sh
_build/default/macos/magic_trace_macos.exe attach \
  --pid 12345 \
  --duration 5s \
  --output attached-process.json.gz
```

Recording an attached process does not intentionally terminate that process
when the time limit expires.

### Keep the Instruments recording

Preserve the `.trace` bundle when investigating symbolication or export issues:

```sh
_build/default/macos/magic_trace_macos.exe run \
  --duration 5s \
  --keep-recording recording.trace \
  --output trace.json.gz \
  -- ./my-program
```

The destination must not already exist.

### Convert an existing XML export

```sh
_build/default/macos/magic_trace_macos.exe convert \
  time-profile.xml \
  --output converted.json.gz \
  --force
```

The XML must contain the table whose schema is `time-profile`. This command is
useful for repeatable parser testing because it performs no new recording.

### Output behavior

- A filename ending in `.gz` is compressed with `/usr/bin/gzip`.
- Any other filename is written as uncompressed JSON.
- Existing output is preserved unless `--force` is supplied.
- Parent directories are created automatically.
- Recording and conversion happen locally; this backend sends no trace data to
  a service.

## Test the synthetic 40 ns model

Build a small exact trace:

```sh
dune exec macos/mock_processor_trace_cli.exe -- \
  --cycles 1000 \
  --resolution-ns 40 \
  --anchor-every 4096 \
  --output mock-40ns-trace.json \
  --force
```

The generated trace contains 10,000 call/return events and 5,000 exact
function intervals across 0.4 ms of virtual time. Open it in Perfetto and
inspect the nested `main`, `work_a`, `work_b`, and `scramble` calls.

Available mock options:

| Option | Default | Purpose |
|---|---:|---|
| `--cycles N` | 1,000 | Number of deterministic nested-call cycles |
| `--resolution-ns N` | 40 | Virtual time between events |
| `--anchor-every N` | 4,096 | Events between 64-bit timing anchors; must be positive and even |
| `--output FILE` | `mock-40ns-trace.json` | Perfetto JSON destination |
| `--force` | off | Replace an existing destination |

Large mock traces should be decoded with the benchmark rather than serialized
to JSON. JSON produces one object per reconstructed call and intentionally
measures formatting and file I/O in addition to decoding.

## Run the decoder-throughput gate

```sh
dune exec macos/benchmark_mock_processor_trace.exe -- \
  --events 10000000 \
  --runs 5
```

At 40 ns there are 25 million virtual event slots per second. The benchmark
warms the decoder, runs it repeatedly, verifies a stable checksum, and compares
the median rate with 25 million events/s.

Latest validation on the M1 Pro test system:

```text
model events=10000000
virtual_duration=0.400s
required_rate=25.000M_events/s
median_decode_rate=67.361M_events/s
realtime=2.69x
required_stream_rate=12.555MB/s
decoder_realtime_gate=PASS
```

This is deliberately stricter than merely reconstructing a trace offline: it
requires the decoder to keep up with one modeled event every 40 ns. Passing the
gate shows software throughput headroom. It does not measure target-process
slowdown, actual Apple packet bandwidth, or hardware capture reliability.

Use `--no-gate` when collecting diagnostic measurements on a slower machine
without making a low rate fail the command.

## Correctness tests

Run the self-contained macOS tests:

```sh
dune runtest macos --no-buffer
```

The tests cover:

- duration validation;
- XML entity decoding;
- `xctrace` `id`/`ref` resolution;
- `sentinel` column reuse;
- process and thread extraction;
- gap-aware sampled-stack reconstruction;
- Chrome Trace Event JSON output;
- exact 40 ns mock call boundaries;
- sparse timing-anchor validation;
- deterministic decoder checksums;
- explicit simulated-trace metadata;
- output overwrite protection.

The macOS targets are intentionally independent of the Linux backend's larger
dependency set. A complete repository build still requires all dependencies
listed by the upstream project.

## Measure real recording overhead

Build the benchmark and its workload:

```sh
dune build macos/benchmark_overhead.exe

clang -O2 -g -Wall -Wextra -Werror \
  macos/demo.c \
  -o /tmp/magic-trace-macos-demo
```

Run balanced baseline/traced pairs:

```sh
_build/default/macos/benchmark_overhead.exe \
  --runs 10 \
  --iterations 5000 \
  /tmp/magic-trace-macos-demo
```

The benchmark alternates whether the baseline or traced measurement runs first,
checks that both executions produce the same workload checksum, and reports an
approximate 95% confidence interval. Its gate passes only when the interval's
upper bound is at most 10%, matching the upper end of the original project's
published overhead range.

The recorded M1 Pro result was:

```text
mean_overhead=+0.779%
approximate_95%_confidence_interval=[-0.004%, +1.563%]
overhead_gate=PASS
```

The confidence interval slightly crosses zero because of measurement noise;
individual pairs with negative overhead are not evidence that profiling
accelerates the program. See [`PERFORMANCE.md`](PERFORMANCE.md) for the
environment, methodology, conversion measurement, and fidelity table.

## Interpreting the results

Three independent properties must not be collapsed into one performance
number:

| Property | Current evidence | Remaining validation |
|---|---|---|
| Target-process overhead | Time Profiler upper confidence bound is below 10% on the test M1 Pro | Repeat across machines and workloads |
| Trace fidelity | Real backend samples at 1 ms; synthetic backend reconstructs exact 40 ns events | Capture real hardware control flow |
| Decoder throughput | Synthetic OCaml decoder reaches 67.36M events/s | Parse Apple's actual packets and metadata |

The software model therefore clears its intended throughput gate, while the
M1 fallback still does **not** reach Jane Street's all-call trace fidelity.

## Path to a real Apple Processor Trace backend

Full parity requires a separate capture provider for Macs on which Apple's
Processor Trace facility is available. The following work remains:

1. Detect Processor Trace support and retain Time Profiler as the fallback.
2. Start a bounded or rolling trace without instrumenting the target.
3. Export raw trace packets, image load addresses, thread identifiers,
   scheduling information, and hardware timing data.
4. Decode ARM64 control flow against the exact Mach-O images used by the
   process.
5. Reconstruct direct and indirect calls, returns, branches, exceptions, and
   discontinuities across cores.
6. Correlate sparse hardware timing packets with decoded control flow.
7. Feed exact intervals into the trace writer.
8. Add ring-buffer snapshots and function-call triggers.
9. Validate the reconstructed sequence against an instrumented ground-truth
   workload.
10. Re-run the 2–10% overhead, approximately 40 ns resolution, and lost-packet
    gates on compatible hardware.

A real backend is acceptable only if the trace records actual target control
flow. Replaying the synthetic format or labelling sampled stacks at 40 ns would
not satisfy that requirement.

## Known limitations

- Real M1 traces use approximately 1 ms periodic stack samples.
- Short calls and branches between samples are missing.
- Sample-derived interval boundaries are estimates.
- Only user-space stacks exported by Time Profiler are represented.
- There is no function-call trigger or pre-trigger rolling buffer.
- The real backend depends on Xcode's `time-profile` export schema.
- The synthetic format is not compatible with Apple Processor Trace packets.
- The synthetic benchmark does not measure target overhead.
- Cross-core scheduling and trace discontinuities are not decoded.
- Hardware Processor Trace support has not been validated in this repository.

## Troubleshooting

### `xctrace was not found`

Install full Xcode, then select Command Line Tools in
**Xcode → Settings → Locations**. Verify:

```sh
xcrun --find xctrace
```

If command-line tool selection is intentionally different, point the backend
at the full Xcode installation directly:

```sh
export MAGIC_TRACE_XCTRACE=/Applications/Xcode.app/Contents/Developer/usr/bin/xctrace
```

### Instruments asks for permission or records no stacks

Allow Developer Tools access in macOS System Settings and rerun the command.
The exact panel name can vary between macOS releases. A CPU-bound target and a
recording of several seconds are easiest to validate.

### The trace contains no short functions

That is expected with the real Time Profiler path. Calls shorter than the
sampling interval may never be observed. Use the synthetic trace only to test
the prospective high-fidelity software pipeline; it does not contain data from
your target process.

### The output already exists

Choose another filename or pass `--force`. Instruments `.trace` bundles named
by `--keep-recording` are never overwritten.

### Symbols appear as addresses

Build the target with debug information, avoid stripping it, and retain the
original executable and dependent images while recording. Use
`--keep-recording` to inspect symbolication directly in Instruments.

### The whole repository does not build

The upstream Linux project requires additional packages such as Jane Street
`Core`, PPX tooling, `vec`, and LLVM utilities. The experimental macOS targets
and tests can be built independently with the commands in this README.

## Pull-request scope

The macOS work is isolated under `macos/` plus a short link from the root
README. It does not alter the existing Linux/Intel PT backend. This separation
allows review in stages:

1. accept the OCaml Time Profiler fallback and its tests;
2. accept the clearly labelled synthetic performance harness;
3. add a real Apple Processor Trace provider only after hardware-backed
   evidence is available.

This staging keeps the current contribution useful on an M1 while preserving a
strict definition of full magic-trace fidelity.
