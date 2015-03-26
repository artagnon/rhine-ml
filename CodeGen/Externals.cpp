#include "rhine/Ast.h"
#include "rhine/Externals.h"

#include "llvm/IR/Type.h"
#include "llvm/ADT/ArrayRef.h"

using namespace llvm;

namespace rhine {
llvm::Function *Externals::printf(llvm::Module *M) {
  auto ArgTys = llvm::ArrayRef<llvm::Type *>(RhBuilder.getInt8PtrTy());
  llvm::FunctionType* printf_type =
    llvm::FunctionType::get(RhBuilder.getInt32Ty(), ArgTys, true);

  llvm::Function *func =
    llvm::Function::Create(printf_type, llvm::Function::ExternalLinkage,
                           Twine("printf"), M);
  func->setCallingConv(llvm::CallingConv::C);
  return func;
}
}
