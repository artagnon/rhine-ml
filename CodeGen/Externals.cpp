#include "rhine/Ast.h"
#include "rhine/Externals.h"

#include "llvm/IR/Type.h"

using namespace llvm;

namespace rhine {
llvm::Function *Externals::printf(llvm::Module *M)
{
  std::vector<llvm::Type*> printf_arg_types;
  printf_arg_types.push_back(llvm::Type::getInt8PtrTy(RhContext));

  llvm::FunctionType* printf_type =
    llvm::FunctionType::get(
        llvm::Type::getInt32Ty(RhContext), printf_arg_types, true);

  llvm::Function *func = llvm::Function::Create(
      printf_type, llvm::Function::ExternalLinkage,
      Twine("printf"), M);
  func->setCallingConv(llvm::CallingConv::C);
  return func;
}
}
