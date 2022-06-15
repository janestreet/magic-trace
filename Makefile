INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)
BUILD_ARGS := $(if $(PROFILE),--profile $(PROFILE),)

default:
	dune build $(BUILD_ARGS)

install:
	dune install $(INSTALL_ARGS) magic-trace

uninstall:
	dune uninstall $(INSTALL_ARGS)

reinstall: uninstall install

clean:
	dune clean

.PHONY: default install uninstall reinstall clean
