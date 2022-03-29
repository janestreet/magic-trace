Owee is an experimental library to work with DWARF format.

OCaml users might find the `Owee_location` module interesting.

Provided an executable:

- runs on Linux,
- runs on a 64-bit x86 architecture,
- contains debug symbols generated with DWARF 2 to DWARF 4,
- contains native code,
- is not relocated, and
- does not use `Dynlink`.

Then it gives you the location of the definition of an arbitrary functional
value. Linking the library is enough, no change to the toolchain is required.

There is partial support for DWARF 5; only symbol names and filenames are fully
tested.

These restrictions can be relaxed. Open issues for platform you'd find
interesting to support & on which you can test the library.
