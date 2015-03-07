#include "rhine/Ast.h"
#include "rhine/Support.h"

namespace rhine {
using namespace llvm;

llvm::Type *IntegerType::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Type *FloatType::toLL(llvm::Module *M) { return LLVisitor::visit(this); }

llvm::Type *FunctionType::toLL(llvm::Module *M) { return nullptr; }

template <typename T>
llvm::Type *ArrayType<T>::toLL(llvm::Module *M) { return nullptr; }

llvm::Constant *rhine::ConstantInt::toLL(llvm::Module *M) {
  return LLVisitor::visit(this);
}

llvm::Constant *ConstantFloat::toLL(llvm::Module *M) {
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
}
