<h1 align="center">
  <img src="https://user-images.githubusercontent.com/128969/160190311-6b614b68-ab0a-430d-9cc5-c6759d9dc118.svg?sanitize=true#gh-dark-mode-only" width="150px"><img src="https://user-images.githubusercontent.com/128969/160190307-f3fdc6bc-f6f9-418f-8058-a5c71ed3ab44.svg?sanitize=true#gh-light-mode-only" width="150px">
  <br>
  magic-trace
</h1>
<p align="center">
  <a href="https://github.com/janestreet/magic-trace/actions?query=workflow%3Abuild" alt="Linux Build Status">
    <img src="https://img.shields.io/github/workflow/status/janestreet/magic-trace/build?logo=github&style=flat-square"/>
  </a>
  <a href="https://github.com/janestreet/magic-trace/releases/latest">
    <img src="https://img.shields.io/github/v/tag/janestreet/magic-trace?label=version&style=flat-square"/>
  </a>
  <a href="LICENSE.md">
    <img src="https://img.shields.io/github/license/janestreet/magic-trace?style=flat-square"/>
  </a>
</p>

magic-trace uses Intel PT to tell you what just happened. You give it a function name. Then, it attaches to a running process and when that function is called it will show you everything that happened for ~10ms (varies, and is partially configurable) leading up to that function call, with ~40ns timing resolution.

There's also a lazy way to use this: attach it to a running process and detatch it with <kbd>Ctrl</kbd>+<kbd>C</kbd>, and see a random trace of your program. This is especially useful if your program is being slow and you don't know why.

magic-trace traces *all control flow* in the snapshot, and that means you can get extremely low granularity data on what your program is doing.

![](https://user-images.githubusercontent.com/128969/160288084-d91d838b-79a1-4a5e-bc62-0ff459b4cfcb.mov)

# Getting started

1. Make sure the system you want to trace is [supported](https://github.com/janestreet/magic-trace/wiki/Supported-platforms,-programming-languages,-and-runtimes). The constraints that most commonly trip people up are: VMs are mostly not supported, Intel only (Skylake or later), Linux only.

2. Grab a release binary from the [latest release page](https://github.com/janestreet/magic-trace/releases/latest).

   1. If downloading the prebuilt binary (not package), `chmod +x magic-trace`
   1. If downloading the package, run `sudo dpkg -i magic-trace*.deb`

   Then, test it by running `magic-trace -help`, which should bring up some help text.

3. [Here](https://raw.githubusercontent.com/janestreet/magic-trace/master/demo/demo.c)'s a sample C program to try out. It's a slightly modified version of the example in `man 3 dlopen`. Download that, build it with `gcc -gdwarf-4 -ldl demo.c -o demo`, then leave it running `./demo`.

4. Run `magic-trace attach -pid $(pidof demo) -output trace`. When you see the message that it's successfully attached, wait a couple seconds and <kbd>Ctrl</kbd>+<kbd>C</kbd> `magic-trace`. It will output a file called `trace` in your working directory.

5. Open [Perfetto](https://ui.perfetto.dev/), click _"Open trace file"_ in the top-left-hand and give it the trace file generated in the previous step.

6. Once it's loaded, expand the trace by clicking the two little arrows in the main trace area.

![](https://user-images.githubusercontent.com/128969/160213103-7c5d9b07-793c-43f1-9fe1-d56ded1c98e5.png)

7. That should have expanded into a trace. Your screen should now look something like this:

![](https://user-images.githubusercontent.com/128969/160200722-aac49645-e0cc-4ebf-a149-e0c04c2f23d0.png)

8. Use <kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd> and the scroll wheel to navigate around. <kbd>W</kbd> zooms in (you'll need to zoom in a bunch to see anything useful), <kbd>S</kbd> zooms out, <kbd>A</kbd> moves left, <kbd>D</kbd> moves right, and scroll wheel moves your viewport up and down the stack. You'll only need to scroll to see particularly deep stack traces, it's probably not useful for this example. Zoom in until you can see an individual loop through `dlopen`/`dlsym`/`cos`/`printf`/`dlclose`.

![](https://user-images.githubusercontent.com/128969/160201314-33ee72d0-c0b0-41e4-86e2-e80a0075cc2b.png)

9. Click and drag on the white space around the call stacks to measure. Plant flags by clicking in the timeline along the top. Using the measurement tool, measure how long it takes to run `cos`. On my screen it takes ~3us.

![](https://user-images.githubusercontent.com/128969/160201591-dc51b5d9-fb78-4c8b-9b21-8c127f89b13d.png)

Congratulations, you just magically traced your first program!

The way magic-trace works is that it continuously records control flow into a ring buffer. Upon some sort of trigger, it takes a snapshot of that buffer and reconstructs call stacks.

There are two ways to take a snapshot:

You just did this one: <kbd>Ctrl</kbd>+<kbd>C</kbd> magic-trace. If magic trace terminates with already having taken a snapshot, it takes a snapshot.

You can also trigger snapshots when the application calls a function. To do so, pass magic-trace
the `-trigger` flag.

- `-trigger $` brings up a fuzzy-finding selector that lets you choose from all
  symbols in your executable,
- `-trigger SYMBOL` selects a specific, fully mangled, symbol you know ahead of time, and
- `-trigger .` selects the default symbol `magic_trace_stop_indicator`.

Stop indicators are powerful. Here are some ideas for where you might want to place one:

- If you're using an asynchronous runtime, any time a scheduler cycle takes too long.
- In a server, when a request takes a surprisingly long time.
- After the garbage collector runs, to see what it's doing and what it interrupted.
- After a compiler pass has completed.

You may leave the stop indicator in production code. It doesn't need to do anything in particular, magic-trace just needs the name. It is just an empty, but not inlined, function. It will cost ~10us to call, but *only when magic-trace actually uses it to take a snapshot*.

# Contributing

If you'd like to contribute:

1. [read the build instructions](https://github.com/janestreet/magic-trace/wiki/Build-instructions),
1. [set up your editor](https://ocaml.org/learn/tutorials/up_and_running.html#Editor-support-for-OCaml),
1. [take a quick tour through the codebase](https://github.com/janestreet/magic-trace/wiki/A-quick-tour-of-the-codebase), then
1. [hit up the issue tracker](https://github.com/janestreet/magic-trace/issues?q=is%3Aissue+is%3Aopen+label%3A%22good+first+issue%22) for a good starter project.

# Testimonials

If you're on the fence about trying this out, we've collected some [testimonials](https://github.com/janestreet/magic-trace/wiki/Unsolicited-reviews) from other users.

# Acknowledgements

[Tristan Hume](https://thume.ca/) is the original author of magic-trace. He wrote it while working at [Jane Street](https://www.janestreet.com/join-jane-street/).
