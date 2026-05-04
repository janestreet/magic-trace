(** Demangle a C++ Itanium ABI mangled symbol name.

    Returns [Some human_readable_name] on success, [None] if the input is not
    a recognised mangled name or if demangling fails. *)
val demangle : string -> string option
