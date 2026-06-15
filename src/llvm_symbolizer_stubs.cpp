#include <cstdint>
#include <cstring>
#include <cstddef>
#include <string_view>

#include "caml/alloc.h"
#include "caml/memory.h"
#include "caml/mlvalues.h"
#include "llvm/DebugInfo/Symbolize/SymbolizableModule.h"
#include "llvm/DebugInfo/Symbolize/Symbolize.h"

namespace {
value ocaml_string_of_cpp_string(std::string_view string) {
  return caml_alloc_initialized_string(string.length(), string.data());
}

// Matches `caml[A-Z]`, the prefix for an OCaml mangled name.
bool is_ocaml_mangled(std::string_view name) noexcept {
  return name.starts_with("caml") && name.size() > 4 && name[4] >= 'A' && name[4] <= 'Z';
}
} // namespace

extern "C" {
CAMLprim llvm::symbolize::LLVMSymbolizer *__attribute__((used, retain))
magic_trace_llvm_symbolizer_create() {
  return new llvm::symbolize::LLVMSymbolizer();
}

CAMLprim void __attribute__((used, retain))
magic_trace_llvm_symbolizer_destroy(llvm::symbolize::LLVMSymbolizer *symbolizer) {
  delete symbolizer;
}

CAMLprim value __attribute__((used, retain))
magic_trace_llvm_symbolize_address(llvm::symbolize::LLVMSymbolizer *symbolizer,
                                   value v_executable_file, uintptr_t address) {
  CAMLparam1(v_executable_file);
  CAMLlocal2(inlined_frames, symbol_name);
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

  // LLVM gives us the (demangled) LinkageName, but it can't demangle OCaml
  // symbols. We could demangle ourselves, but the name the compiler emits
  // under [DW_AT_name] is considerably more readable, so we use that instead.
  const llvm::DIInliningInfo *short_frames = nullptr;
  llvm::DIInliningInfo short_result;
  bool needs_short_names = false;
  for (uint32_t i = 0; i < num_frames; i++) {
    if (is_ocaml_mangled(frames.getFrame(i).FunctionName)) {
      needs_short_names = true;
      break;
    }
  }
  if (needs_short_names) {
    if (auto module = symbolizer->getOrCreateModuleInfo(executable_file)) {
      if (llvm::symbolize::SymbolizableModule *info = *module) {
        short_result = info->symbolizeInlinedCode(
            sectioned_address,
            llvm::DILineInfoSpecifier(
                llvm::DILineInfoSpecifier::FileLineInfoKind::AbsoluteFilePath,
                llvm::DINameKind::ShortName),
            /*UseSymbolTable=*/true);
        short_frames = &short_result;
      }
    } else {
      llvm::consumeError(module.takeError());
    }
  }

  if (num_frames <= Max_young_wosize) [[likely]] {
    inlined_frames = caml_alloc_small(/*wosize=*/num_frames, /*tag=*/0);
  } else {
    inlined_frames = caml_alloc_shr(/*wosize=*/num_frames, /*tag=*/0);
  }
  memset((uint8_t *)inlined_frames, 0xFF, Bsize_wsize(num_frames));
  for (uint32_t i = 0; i < num_frames; i++) {
    const auto &frame = frames.getFrame(i);
    std::string_view name = frame.FunctionName;
    if (short_frames != nullptr && is_ocaml_mangled(frame.FunctionName) &&
        i < short_frames->getNumberOfFrames()) {
      name = short_frames->getFrame(i).FunctionName;
    }
    symbol_name = ocaml_string_of_cpp_string(name);
    caml_modify(&Field(inlined_frames, num_frames - 1 - i), symbol_name);
  }
  CAMLreturn(inlined_frames);
}
}
