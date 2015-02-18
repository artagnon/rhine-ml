#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/TypeBuilder.h"
#include "llvm/IR/Constants.h"

#include "rhine/Ast.h"
#include "rhine/Support.h"

namespace rhine {
using namespace llvm;

LLVMContext &TyContext = getGlobalContext();

llvm::Type *RhTypeToLL(rhine::Type *Ty)
{
  if (dynamic_cast<rhine::IntegerType *>(Ty))
    return TypeBuilder<types::i<32>, true>::get(TyContext);
  else if (dynamic_cast<rhine::FloatType *>(Ty))
    return llvm::Type::getFloatTy(TyContext);
  return nullptr;
}

llvm::Constant *RhConstantToLL(rhine::Constant *V)
{
  if (auto I = dynamic_cast<rhine::ConstantInt *>(V))
    return llvm::ConstantInt::get(TyContext, APInt(32, I->getVal()));
  else if (auto F = dynamic_cast<rhine::ConstantFloat *>(V))
    return llvm::ConstantFP::get(TyContext, APFloat(F->getVal()));
  return nullptr;
}
}
