INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)

default:
	dune build

install:
	dune install $(INSTALL_ARGS)

uninstall:
	dune uninstall $(INSTALL_ARGS)

reinstall: uninstall install

clean:
	dune clean

.PHONY: default install uninstall reinstall clean
