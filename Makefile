INSTALL_ARGS := $(if $(PREFIX),--prefix $(PREFIX),)
BUILD_ARGS := $(if $(PROFILE),--profile $(PROFILE),)

BREW_DEPS = gmp pkgconf

.PHONY: default install uninstall reinstall clean test setup

setup:
	@command -v brew >/dev/null 2>&1 && { \
	  for pkg in $(BREW_DEPS); do \
	    brew list --formula $$pkg >/dev/null 2>&1 || brew install $$pkg; \
	  done; \
	} || true
	opam install --deps-only -y ./magic-trace.opam

default: setup
	dune test $(BUILD_ARGS)

install:
	dune install $(INSTALL_ARGS) magic-trace

uninstall:
	dune uninstall $(INSTALL_ARGS)

reinstall: uninstall install

test: setup
	dune test $(BUILD_ARGS)

clean:
	dune clean
