#include "rhine/ParseDriver.h"
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

void parseFacade(std::unique_ptr<Module> &Owner) {
  std::string Prg = "491";
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root);
  Driver.parseString(Prg);
  std::cout << "Parsed:" << std::endl;
  for (auto ve : Root.Integers) {
    cout << ve << std::endl;
  }
}

void parseFacade2(std::unique_ptr<Module> &Owner) {
  Module *M = Owner.get();

  rhine::Function *RhF = rhine::emitAdd2Const(M);
  RhF->toLL();
  M->dump();
}

MainFTy codegenFacade(std::unique_ptr<Module> &Owner) {
  ExecutionEngine *EE = EngineBuilder(std::move(Owner)).create();
  assert(EE && "error creating MCJIT with EngineBuilder");
  union {
    uint64_t raw;
    MainFTy usable;
  } functionPointer;
  functionPointer.raw = EE->getFunctionAddress("main");
  return functionPointer.usable;
}

int main() {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();
  std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", rhine::RhContext);
  parseFacade(Owner);
  if (auto Fptr = codegenFacade(Owner))
    std::cout << Fptr() << std::endl;
  return 0;
}
