# Magic-trace Tutorial

This is a detailed walkthrough of the steps involved in using
`magic-trace` to diagnose a performance problem. To get an overview of
`magic-trace` see [the Readme](../README.md).

## Decide how to tell magic-trace to capture a snapshot

Because of the immense detail of the data, `magic-trace` currently only
supports capturing 10ms trace snapshots. There's a variety of options
for how to tell `magic-trace` when to capture a snapshot:

- **Does your problem happen over a long period or right before a
  crash?** Press `Ctrl-C` while attached or have your program
  end/crash while being run under `magic-trace trace`. A snapshot is
  automatically captured when tracing ends.
- **Can you easily use a new build of your code?** Add a call to
  `Magic_trace.take_snapshot` where you want `magic-trace` to capture.
  You can use conditional logic to snapshot under whatever conditions
  you can program.
    - **Do you want to capture tail latency events?** You can use
      `Magic_trace.mark_start` to mark the start of processing. Then
      if you're okay paying an 8us pause on every
      `Magic_trace.take_snapshot` then use an argument like
      `-duration-thresh 5ms` to only snap events over a time
      threshold. 
        - If you want to avoid the breakpoint pause on every event you
          can use `Magic_trace.Min_duration` (see its docs) to compile
          in a duration check, which you can use in concert with a
          larger `-duration-thresh`.
- **Is there an existing function that's called when you want a
  snapshot?** You can use the `-symbol` argument with part of the
  function name (or `''` if you want to search all symbols) and
  `magic-trace` will present a fuzzy-finder box for you to select the
  full symbol you want.
    - **If it's an anonymous function** you can use `gdb mybinary` and
      then a command like `info line myfile.ml:470` to find the symbol
      name at a given line.

### Capturing long Async cycles

If you want to capture after an `Async` cycle takes too long, first
you need some code to be called after that happens. There's a built-in
feature of `Async` for this but you need to add some code to your app
if it doesn't already have something like it:

```ocaml
Stream.iter
 (Scheduler.long_cycles ~at_least:(Time_ns.Span.of_sec 5.))
 ~f:(fun ts ->
   Magic_trace.take_snapshot ();
   Log.Global.info !"long async cycle: %{Time_ns.Span}" ts);
```

If you already have a logging function and don't want to rebuild your
app with a `Magic_trace.take_snapshot` call you can try the trick above
with using `gdb` to identify the symbol name of the logging function.

If you don't want to rebuild and don't have an existing long cycle
callback, there's a `-delay-thresh` argument, where you attach to a
function called every cycle like `Async_unix.Raw_scheduler.one_iter`
and then it takes a snapshot if the delay between calls exceeds a
specified amount. However this is only a good idea for some apps,
since it'll add the 8us breakpoint pause on every async cycle, which
is fine for epoll-based apps where cycles are usually around 10ms, but
not viable for apps that use high-performance networking where cycles
are much shorter.

## Attaching to the program

- **To attach to an existing process** use the `magic-trace attach`
  command, by default it will offer a fuzzy finder for the process to
  attach to. It will automatically detach and stop when it captures a
  snapshot.
    - **If you want to automate process selection** you can use
      something like `-pid $(pgrep myprogram)`
- **To run a process under magic-trace** use `magic-trace trace`. This
  attaches tracing before starting the process so a call to the
  snapshot symbol can't be missed. If no snapshot is captured
  before the program ends it'll capture the final trace buffer
  contents, which can be useful for diagnosing crashes.
    - You can pass additional arguments to the program running under
      `magic-trace` by including them after `--`

There's some other interesting options you can add:

- `-multi-thread` enables recording of all threads of the target
  process. Note that currently only hitting the breakpoint symbol in
  the main thread will trigger a snapshot. Traces created this way can
  look a bit weird, in that sleeping doesn't use up trace buffer size,
  so the lookback provided can vary greatly between threads.
- `-multi-snapshot` enables capturing multiple snapshots in one trace.
  This option isn't very well tested and has lots of gotchas. If you
  know that your snapshot symbol will be called spaced apart in time by
  at least a few hundred milliseconds, it may work for you.
- `-immediate-stop` ensures that trace recording stops exactly when
  the snapshot symbol is hit, rather than shortly after once the
  `magic-trace` process has woken up and paused it. This is usually
  not necessary, and on [newer][1] kernels (such as the one in
  Enterprise Linux 8) there's a bug we haven't yet patched which can
  hard crash the machine if you use this option.

[1]: https://github.com/torvalds/linux/commit/670638477aede0d7a355ced04b569214aa3feacd

## Saving/viewing the trace

- By default, `magic-trace` will host an HTTP server for a Perfetto UI
  which you can visit to view the trace. You can click the `Download`
  button in the sidebar to save the trace file. (Only in the Jane
  Street internal version of magic-trace)
- The `-output` option lets you tell it to save a trace file instead,
  which you can then load in Perfetto.

Some `magic-trace` specific trace viewing tips:

- Start by zooming way in on the end of the trace to find the call to
  your snapshot symbol (or searching for `magic_trace_stop` if using
  `Magic_trace.take_snapshot`)
- You can click on spans to see their file and line number, which
  helps figure out which actual functions things refer to.
- The `Magic_trace.take_snapshot_with_arg` function allows including an
  argument integer which you can see in the arguments panel by clicking
  on the event in the "Snapshot symbol hits" track.
