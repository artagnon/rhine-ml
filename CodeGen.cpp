#include "rhine/Support.h"
#include "rhine/Ast.h"

#include "llvm/IR/Verifier.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
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

LLVMContext &Context = getGlobalContext();

void buildRhIR2(std::unique_ptr<Module> &Owner) {
  IRBuilder<> Builder(Context);
  Module *M = Owner.get();

  Function *F = Function::Create(TypeBuilder<int32_t(void), false>::get(Context),
                                 GlobalValue::ExternalLinkage, "scramble", M);
  BasicBlock *BB = BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(BB);
  Builder.CreateRet(ConstantInt::get(Context, APInt(32, 24)));

  F = Function::Create(TypeBuilder<int32_t(void), false>::get(Context),
                       GlobalValue::ExternalLinkage, "ooo1", M);
  BB = BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(BB);
  Builder.CreateRet(ConstantInt::get(Context, APInt(32, 42)));
  M->dump();
}

void buildRhIR(std::unique_ptr<Module> &Owner) {
  IRBuilder<> Builder(Context);
  Module *M = Owner.get();

  rhine::Function *RhF = rhine::emitAdd2Const();
  rhine::Value *RhV = RhF->getVal();
  auto RhI = dynamic_cast<rhine::AddInst *>(RhV);
  auto RhC = dynamic_cast<rhine::ConstantInt *>(RhI->getOperand(0));
  Constant *Op0 = rhine::RhConstantToLL(RhC);
  Type *RType = RhI->getType()->toLL();
  // Op1 = RhConstantToLL(RhI->getOperand(1));
  Function *F = Function::Create(FunctionType::get(RType, false),
                                 GlobalValue::ExternalLinkage,
                                 RhF->getName(), M);
  BasicBlock *BB = BasicBlock::Create(Context, "entry", F);
  Builder.SetInsertPoint(BB);
  Builder.CreateRet(Op0);
  M->dump();
}

int main() {
  LLVMInitializeNativeTarget();
  LLVMInitializeNativeAsmPrinter();
  LLVMInitializeNativeAsmParser();

  std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", Context);
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
