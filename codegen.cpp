#include "llvm/IR/Verifier.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/TypeBuilder.h"
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

int main() {
	LLVMInitializeNativeTarget();
	LLVMInitializeNativeAsmPrinter();
	LLVMInitializeNativeAsmParser();

	LLVMContext &Context = getGlobalContext();
	IRBuilder<> Builder(Context);
	std::unique_ptr<Module> Owner = make_unique<Module>("simple_module", Context);
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
	ExecutionEngine *EE = EngineBuilder(std::move(Owner)).create();
	assert(EE != NULL && "error creating MCJIT with EngineBuilder");
	union {
		uint64_t raw;
		int (*usable)();
	} functionPointer;
	functionPointer.raw = EE->getFunctionAddress("ooo1");
	std::cout << functionPointer.usable() << std::endl;

	return 0;
}
