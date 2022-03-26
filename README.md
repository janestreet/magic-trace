<h1 align="center">
  <img src="https://user-images.githubusercontent.com/128969/160190311-6b614b68-ab0a-430d-9cc5-c6759d9dc118.svg?sanitize=true#gh-dark-mode-only" width="150px"><img src="https://user-images.githubusercontent.com/128969/160190307-f3fdc6bc-f6f9-418f-8058-a5c71ed3ab44.svg?sanitize=true#gh-light-mode-only" width="150px">
  <br/>
  magic-trace
</h1>
  <p align="center">
    <a href="https://github.com/janestreet/magic-trace/actions?query=workflow%3Abuild" alt="Linux Build Status">
      <img src="https://img.shields.io/github/workflow/status/janestreet/magic-trace/build?logo=github&style=flat-square"/>
  </a>
  <a href="https://github.com/janestreet/magic-trace/releases/latest">
    <img src="https://img.shields.io/github/v/tag/janestreet/magic-trace?label=version&style=flat-square"/>
  </a>
  <img src="https://img.shields.io/github/license/janestreet/magic-trace?style=flat-square"/>
</p>

Magic-trace uses Intel PT to tell you what just happened. You give it a function name. then, it attaches to a running process and when that function is called it will show you everything that happened for ~10ms (varies, and is partially configurable) leading up to that function call.

There's also a lazy way to use this: attach it to a running process and detatch it with <kbd>Ctrl</kbd>+<kbd>C</kbd>, and see a random trace of your program. This is especially useful if your program is being slow and you don't know why.

Magic-trace traces *all control flow* in the snapshot, and that means you can get extremely low granularity data on what your program is doing. For example, here's 10us of an ocaml program's startup procedure, with timing resolution of around 40ns:

![10us of OCaml program startup](docs/assets/example-trace.png) 

[Get started.](https://github.com/janestreet/magic-trace/wiki/Getting-started)

If you'd like to contribute, follow the [Build instructions](https://github.com/janestreet/magic-trace/wiki/Build-instructions).

If you're on the fence about trying this out, we've collected some [testimonials](https://github.com/janestreet/magic-trace/wiki/Unsolicited-reviews) from other users.
