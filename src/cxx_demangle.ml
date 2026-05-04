(** C++ symbol demangling via __cxa_demangle.

    Returns [Some demangled_name] when the input is a valid Itanium ABI mangled
    symbol (i.e. anything starting with [_Z]).  Returns [None] for plain C
    symbols, OCaml symbols, and anything __cxa_demangle does not recognise.

    The underlying C stub passes a NULL output buffer to __cxa_demangle so it
    malloc-allocates exactly the space required — no truncation occurs regardless
    of how deeply nested the C++ template instantiation is. *)
external demangle : string -> string option = "magic_trace_cxx_demangle"
