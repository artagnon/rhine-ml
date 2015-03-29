#include "rhine/Toplevel.h"
#include "rhine/ParseDriver.h"
#include "rhine/Externals.h"
#include "rhine/Support.h"

#include "llvm/ExecutionEngine/ExecutionEngine.h"
#include "llvm/Bitcode/BitstreamWriter.h"
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

namespace rhine {
MainFTy jitFacade(std::string InStr, bool Debug, bool IsStringStream) {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();

  std::unique_ptr<Module> Owner = make_unique<Module>("main", rhine::RhContext);
  if (IsStringStream)
    parseCodeGenString(InStr, Owner.get(), std::cerr, Debug);
  else
    parseCodeGenFile(InStr, Owner.get(), Debug);
  ExecutionEngine *EE = EngineBuilder(std::move(Owner)).create();
  assert(EE && "Error creating MCJIT with EngineBuilder");
  union {
    uint64_t raw;
    MainFTy usable;
  } functionPointer;
  functionPointer.raw = EE->getFunctionAddress("main");
  assert(functionPointer.usable && "no main function found");
  return functionPointer.usable;
}
}
