#include "rhine/Ast.h"
#include "rhine/Support.h"

namespace rhine {
using namespace llvm;

llvm::Type *IntegerType::toLL() { return LLVisitor::visit(this); }

llvm::Type *FloatType::toLL() { return LLVisitor::visit(this); }

llvm::Type *FunctionType::toLL() { return nullptr; }

template <typename T>
llvm::Type *ArrayType<T>::toLL() { return nullptr; }

llvm::Constant *rhine::ConstantInt::toLL() { return LLVisitor::visit(this); }

llvm::Constant *ConstantFloat::toLL() { return LLVisitor::visit(this); }

llvm::Constant *Function::toLL() { return nullptr; }

llvm::Value *AddInst::toLL() { return LLVisitor::visit(this); }
}
