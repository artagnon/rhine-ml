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

void parseFacade(std::string Filename, bool Debug) {
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root, Debug);
  Driver.parseFile(Filename);
  std::cout << "Statements:" << std::endl;
  for (auto ve : Root.Body)
    ve->toLL()->dump();
  std::cout << "Defuns:" << std::endl;
  for (auto ve : Root.Defuns)
    ve->toLL()->dump();
}

void parseFacade2(Module *M) {
  rhine::Function *RhF = rhine::emitAdd2Const();
  RhF->toLL(M);
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

void toplevelJit(std::string Filename, bool Debug) {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();

  parseFacade(Filename, Debug);
  std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", rhine::RhContext);
  if (auto Fptr = codegenFacade(Owner))
    std::cout << Fptr() << std::endl;
}
