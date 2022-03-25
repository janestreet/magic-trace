<h1 align="center">
  <img src="https://user-images.githubusercontent.com/128969/160153610-22726be8-faf9-4042-97c3-d5c9fb2027dd.svg" width="150px"/>
  <br/>
  magic-trace
</h1>
  <p align="center">
    <a href="https://github.com/janestreet/magic-trace/actions?query=workflow%3Abuild" alt="Linux Build Status">
      <img src="https://img.shields.io/github/workflow/status/janestreet/magic-trace/build?logo=github&style=flat-square"/>
  </a>
  <img src="https://img.shields.io/github/v/tag/janestreet/magic-trace?label=version&style=flat-square"/>
  <img src="https://img.shields.io/github/license/janestreet/magic-trace?style=flat-square"/>
</p>

`magic-trace` is a tool for diagnosing tricky performance issues using
Intel Processor Trace. You tell it a function and attach it to a
running process, and when that function is called it'll detach and give
you a visualization of everything that happened in the around 10ms
leading up to that function call. Here's me zoomed in to about 10us of
this data, but it has timing resolution of around 40ns:

![10us of OCaml program startup](docs/assets/example-trace.png) 

[Get started.](https://github.com/janestreet/magic-trace/wiki/Getting-started)

If you'd like to contribute, follow the [Build Instructions](https://github.com/janestreet/magic-trace/wiki/Build-instructions).
