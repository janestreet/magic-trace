Owee is an experimental library to work with DWARF format.

OCaml users might find the `Owee_location` module interesting.

Provided you:
- use Linux,
- on 64-bit x86 architecture,
- generated debugging symbols,
- compiled in native code,
- no relocation happened and you're not using `Dynlink`

Then it gives you the location of the definition of an arbitrary functional
value. Linking the library is enough, no change to the toolchain is required.

These restrictions can be relaxed, open issues for platform you'd find interesting to support & on which you can test the library.
