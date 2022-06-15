# magic-trace

`magic-trace` is a tool for diagnosing tricky performance issues using
Intel Processor Trace. You tell it a function and attach it to a
running process, and when that function is called it'll detach and give
you a visualization of everything that happened in the around 10ms
leading up to that function call. Here's me zoomed in to about 10us of
this data, but it has timing resolution of around 40ns:

![10us of OCaml program startup](docs/assets/example-trace.png) 

See [the tutorial](docs/tutorial.md) for more on how to use it.
