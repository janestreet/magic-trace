#!/bin/sh

if [ -z "$1" ]; then
  echo "Usage: $0 <file to generate>"
  exit 1
fi

VERSION="$(git describe --always --dirty --abbrev=7 --tags)"

cat > "$1" <<EOF
#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>

CAMLprim value generated_hg_version(value unit __attribute__ ((unused))) {
  return caml_copy_string("${VERSION}");
}
EOF
