#include "rhine/Support.h"
#include "rhine/Ast.h"

#include "llvm/IR/Verifier.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/Bitcode/BitstreamWriter.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/ExecutionEngine/MCJIT.h"
#include "llvm/ExecutionEngine/SectionMemoryManager.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Host.h"

#include "llvm/CodeGen/GCMetadataPrinter.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/Target/TargetSubtargetInfo.h"

#include <iostream>

using namespace llvm;

void buildRhIR(std::unique_ptr<Module> &Owner) {
  Module *M = Owner.get();

  rhine::Function *RhF = rhine::emitAdd2Const(M);
  RhF->toLL();
  M->dump();
}

int main() {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();

  std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", rhine::RhContext);
  buildRhIR(Owner);
  ExecutionEngine *EE = EngineBuilder(std::move(Owner)).create();
  assert(EE && "error creating MCJIT with EngineBuilder");
  union {
    uint64_t raw;
    int (*usable)();
  } functionPointer;
  functionPointer.raw = EE->getFunctionAddress("foom");
  std::cout << functionPointer.usable() << std::endl;

  return 0;
}
