(** Demangle a C++ Itanium ABI mangled symbol name.

    Returns [Some human_readable_name] when [s] starts with [_Z] and is a
    valid mangled name.  Returns [None] for everything else — plain C
    symbols, OCaml symbols, Rust v0 symbols ([_R...]), and any unrecognised
    [_Z]-prefixed input.  The non-[_Z] case short-circuits before the FFI
    call. *)
val demangle : string -> string option
