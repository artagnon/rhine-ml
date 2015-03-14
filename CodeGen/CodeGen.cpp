#include "rhine/ParseDriver.h"
#include "rhine/CodeGen.h"
#include "rhine/Support.h"

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
#include <sstream>

using namespace llvm;

typedef int (*MainFTy)();

MainFTy eeFacade(std::unique_ptr<Module> &Owner) {
  ExecutionEngine *EE = EngineBuilder(std::move(Owner)).create();
  assert(EE && "error creating MCJIT with EngineBuilder");
  union {
    uint64_t raw;
    MainFTy usable;
  } functionPointer;
  functionPointer.raw = EE->getFunctionAddress("main");
  return functionPointer.usable;
}

void codegenFacade() {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();
  std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", rhine::RhContext);
}
