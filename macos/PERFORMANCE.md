# macOS performance results

This document separates target-process overhead from trace fidelity. Both
matter when comparing this backend with the original Intel Processor Trace
implementation.

## Test system

- Apple M1 Pro
- macOS 26.5.2
- Xcode `xctrace` 16.0 (17F113)
- OCaml 5.5.0
- Dune 3.24.1
- Demo compiled as a native arm64 Mach-O with `clang -O2 -g`

## Target-process overhead

The native OCaml benchmark ran ten balanced baseline/traced pairs with 5,000
fixed demo iterations per measurement. It alternated baseline-first and
traced-first ordering and verified the same workload checksum in every pair.

```text
runs=10
mean_overhead=+0.779%
standard_deviation=1.264%
approximate_95%_confidence_interval=[-0.004%, +1.563%]
overhead_gate=PASS
```

The confidence interval's upper bound is below the original project's
published 10% upper bound. Individual pairs can report negative overhead due
to measurement noise; that is not a claim that profiling makes the program
faster.

Reproduce the result using:

```sh
dune build macos/benchmark_overhead.exe
clang -O2 -g -Wall -Wextra -Werror \
  macos/demo.c -o /tmp/magic-trace-macos-demo

_build/default/macos/benchmark_overhead.exe \
  --runs 10 \
  --iterations 5000 \
  /tmp/magic-trace-macos-demo
```

## Conversion performance

Converting a 393 KiB Time Profiler XML export containing 2,002 samples and
2,925 reconstructed intervals took 0.04 seconds and produced a 23 KiB
compressed trace.

Conversion happens after recording, so it does not add overhead to the target
process.

## Fidelity

The recorded median sampling period was 1,000,000 ns. The original
magic-trace backend advertises complete function-call tracing at approximately
40 ns resolution.

| Property | Original Intel backend | M1 Time Profiler backend |
|---|---:|---:|
| Runtime-overhead gate | 2–10% | Passes the 10% ceiling |
| Time resolution | ~40 ns | 1,000,000 ns |
| Relative resolution | 1× | 25,000× coarser |
| Captures every function call | Yes | No |

The M1 backend therefore reaches the runtime-overhead target but cannot reach
the original trace-fidelity target. OCaml removes the prototype-language
difference; it cannot replace processor trace hardware that is absent from the
M1.

## Synthetic 40 ns hardware model

`mock_processor_trace_cli.exe` supplies deterministic compressed packets at the
boundary where a future Apple Processor Trace capture provider will connect.
The model uses:

- a 40 ns virtual event period;
- two call/return decisions per byte;
- one 64-bit timing anchor every 4,096 events;
- balanced nested calls with exact expected start and end times.

`benchmark_mock_processor_trace.exe` gates the OCaml decoder against 25 million
events per second, which is one event slot every 40 ns. This is deliberately a
software readiness benchmark. Passing it does not claim that an M1 acquired
real branch data, nor does it replace an overhead measurement on supported
Processor Trace hardware.

On the M1 Pro test system, five decodes of a 10,000,000-event stream produced:

```text
median_decode_rate=67.361M events/s
required_rate=25.000M events/s
realtime_factor=2.69x
synthetic_packet_bandwidth=12.555MB/s
decoder_realtime_gate=PASS
```

The checksum was identical in all five runs. At this model's worst-case rate,
the OCaml decoder therefore has substantial headroom; real Apple packet parsing
and trace acquisition remain the unmeasured parts.
