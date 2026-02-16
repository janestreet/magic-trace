#include <cstdint>
#include <cstring>

#include "caml/alloc.h"
#include "caml/memory.h"
#include "caml/mlvalues.h"
#include "llvm/DebugInfo/Symbolize/Symbolize.h"

namespace {
value ocaml_string_of_cpp_string(std::string_view string) {
  return caml_alloc_initialized_string(string.length(), string.data());
}
} // namespace

extern "C" {
CAMLprim llvm::symbolize::LLVMSymbolizer *__attribute__((used, retain))
magic_trace_llvm_symbolizer_create() {
  llvm::symbolize::LLVMSymbolizer::Options options{};
  // We need this for now to work around the fact the OCaml compiler inverts
  // `DW_AT_name` and `DW_AT_linkage_name`, which breaks LLVM's assumptions when
  // it tries to use the symbol table.
  options.UseSymbolTable = false;
  return new llvm::symbolize::LLVMSymbolizer(options);
}

CAMLprim void __attribute__((used, retain))
magic_trace_llvm_symbolizer_destroy(llvm::symbolize::LLVMSymbolizer *symbolizer) {
  delete symbolizer;
}

CAMLprim value __attribute__((used, retain))
magic_trace_llvm_symbolize_address(llvm::symbolize::LLVMSymbolizer *symbolizer,
                                   value v_executable_file, uintptr_t address) {
  CAMLparam1(v_executable_file);
  CAMLlocal2(inlined_frames, demangled_name);
  std::string_view executable_file{String_val(v_executable_file),
                                   caml_string_length(v_executable_file)};
  llvm::object::SectionedAddress sectioned_address{
      address, llvm::object::SectionedAddress::UndefSection};
  auto result = symbolizer->symbolizeInlinedCode(executable_file, sectioned_address);
  if (auto _ = result.takeError()) {
    CAMLreturn((value)NULL);
  }
  const auto &frames = result.get();
  const uint32_t num_frames = frames.getNumberOfFrames();
  if (num_frames == 0) {
    CAMLreturn((value)NULL);
  }
  if (num_frames <= Max_young_wosize) [[likely]] {
    inlined_frames = caml_alloc_small(/*wosize=*/num_frames, /*tag=*/0);
  } else {
    inlined_frames = caml_alloc_shr(/*wosize=*/num_frames, /*tag=*/0);
  }
  memset((uint8_t *)inlined_frames, 0xFF, Bsize_wsize(num_frames));
  for (uint32_t i = 0; i < num_frames; i++) {
    const auto &frame = frames.getFrame(i);
    demangled_name = ocaml_string_of_cpp_string(frame.FunctionName);
    caml_modify(&Field(inlined_frames, num_frames - 1 - i), demangled_name);
  }
  CAMLreturn(inlined_frames);
}
}
