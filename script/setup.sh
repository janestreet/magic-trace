#!/usr/bin/env bash
set -euo pipefail

if [ "$(uname)" = "Darwin" ]; then
  if command -v brew >/dev/null 2>&1; then
    for pkg in gmp pkgconf; do
      brew list --formula "$pkg" >/dev/null 2>&1 || brew install "$pkg"
    done
  else
    echo "error: Homebrew not found — install gmp and pkgconf manually" >&2
    exit 1
  fi
fi

if ! command -v opam >/dev/null 2>&1; then
  echo "error: opam not found — install it from https://opam.ocaml.org/doc/Install.html" >&2
  exit 1
fi

eval "$(opam env 2>/dev/null)" || true

opam install --deps-only -y ./magic-trace.opam

echo "Ready. Run: dune test"
