#include "llvm/IR/TypeBuilder.h"
#include "llvm/IR/DerivedTypes.h"

#include "Ast.h"
#include "Support.h"

using namespace llvm;

LLVMContext &TyContext = getGlobalContext();

Type *RhTypeToLLType(rhine::Type *Ty)
{
  if (dynamic_cast<rhine::IntegerType *>(Ty))
    return TypeBuilder<types::i<32>, true>::get(TyContext);
  else if (dynamic_cast<rhine::FloatType *>(Ty))
    return Type::getFloatTy(TyContext);
  return nullptr;
}
