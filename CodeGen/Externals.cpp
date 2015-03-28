#include "rhine/Ast.h"
#include "rhine/Externals.h"

#include "llvm/IR/Type.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ExecutionEngine/MCJIT.h"

using namespace llvm;

namespace rhine {
llvm::Function *Externals::printf(llvm::Module *M) {
  static llvm::Function *Handle = nullptr;
  if (Handle)
    return Handle;

  auto ArgTys = llvm::ArrayRef<llvm::Type *>(RhBuilder.getInt8PtrTy());
  llvm::FunctionType* printf_type =
    llvm::FunctionType::get(RhBuilder.getInt32Ty(), ArgTys, true);

  Handle = llvm::Function::Create(printf_type, llvm::Function::ExternalLinkage,
                                  Twine("printf"), M);
  Handle->setCallingConv(llvm::CallingConv::C);
  return Handle;
}
}
