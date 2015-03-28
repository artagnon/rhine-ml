#include "rhine/Ast.h"
#include "rhine/Externals.h"

namespace rhine {
//===--------------------------------------------------------------------===//
// ToLL() stubs.
//===--------------------------------------------------------------------===//
llvm::Type *IntegerType::toLL(llvm::Module *M) { return LLVisitor::visit(this); }

llvm::Type *FloatType::toLL(llvm::Module *M) { return LLVisitor::visit(this); }

llvm::Type *StringType::toLL(llvm::Module *M) { return LLVisitor::visit(this); }

llvm::Type *FunctionType::toLL(llvm::Module *M) { return nullptr; }

template <typename T>
llvm::Type *ArrayType<T>::toLL(llvm::Module *M) { return nullptr; }

llvm::Constant *rhine::ConstantInt::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Constant *ConstantFloat::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Value *GlobalString::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Constant *Function::toLL(llvm::Module *M) {
  return LLVisitor::visit(this, M);
}

llvm::Value *Variable::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Value *AddInst::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Value *CallInst::toLL(llvm::Module *M) {
  return LLVisitor::visit(this, M);
}

//===--------------------------------------------------------------------===//
// LLVisitor visits.
//===--------------------------------------------------------------------===//
llvm::Type *LLVisitor::visit(IntegerType *V) {
  return RhBuilder.getInt32Ty();
}

llvm::Type *LLVisitor::visit(FloatType *V) {
  return RhBuilder.getFloatTy();
}

llvm::Type *LLVisitor::visit(StringType *V) {
  return RhBuilder.getInt8PtrTy();
}

llvm::Value *LLVisitor::visit(Variable *V) {
  assert(0 && "Cannot lower variable");
}

llvm::Value *LLVisitor::visit(GlobalString *S) {
  auto SRef = llvm::StringRef(S->getVal());
  return RhBuilder.CreateGlobalStringPtr(SRef);
}

llvm::Constant *LLVisitor::visit(ConstantInt *I) {
  return llvm::ConstantInt::get(RhContext, APInt(32, I->getVal()));
}

llvm::Constant *LLVisitor::visit(ConstantFloat *F) {
  return llvm::ConstantFP::get(RhContext, APFloat(F->getVal()));
}

llvm::Constant *LLVisitor::visit(Function *RhF, llvm::Module *M) {
  auto RType = RhF->getVal()->getType()->toLL();
  auto F = llvm::Function::Create(llvm::FunctionType::get(RType, false),
                                  GlobalValue::ExternalLinkage,
                                  RhF->getName(), M);
  BasicBlock *BB = BasicBlock::Create(rhine::RhContext, "entry", F);
  RhBuilder.SetInsertPoint(BB);
  llvm::Value *RhV = RhF->getVal()->toLL();
  RhBuilder.CreateRet(RhV);
  return F;
}

llvm::Value *LLVisitor::visit(AddInst *A) {
  auto Op0 = A->getOperand(0)->toLL();
  auto Op1 = A->getOperand(1)->toLL();
  return RhBuilder.CreateAdd(Op0, Op1);
}

llvm::Value *LLVisitor::visit(CallInst *C, llvm::Module *M) {
  auto Callee = Externals::printf(M);
  auto StrPtr = C->getOperand(0)->toLL();
  return RhBuilder.CreateCall(Callee, StrPtr, C->getName());
}
}
