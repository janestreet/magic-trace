all: decodedline_macho decodedline_elf functions

owee:
	make -C .. owee

decodedline_macho: decodedline_macho.ml owee
	ocamlopt -o $@ -g unix.cmxa bigarray.cmxa -I ../src ../src/owee.cmxa decodedline_macho.ml

decodedline_elf: decodedline_elf.ml owee
	ocamlopt -o $@ -g unix.cmxa bigarray.cmxa -I ../src ../src/owee.cmxa decodedline_elf.ml

functions: functions.ml owee
	ocamlopt -o $@ -g unix.cmxa bigarray.cmxa -I ../src ../src/owee.cmxa functions.ml

clean:
	rm -f *.cm* *.o *.a decodedline_macho decodedline_elf functions
