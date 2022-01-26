# Magic_trace library

Used with the `magic-trace` tool to capture a trace of the execution
leading up to a call to `Magic_trace.take_snapshot ()` for performance
analysis and debugging.

The tool can attach to any symbol, but it defaults to the special
symbol used by this library, making this the easiest way to modify
your code to take a snapshot under certain conditions.
