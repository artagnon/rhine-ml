#ifndef SUPPORT_H
#define SUPPORT_H

#include "llvm/IR/LLVMContext.h"

#include "Ast.h"

using namespace llvm;

LLVMContext &Context = getGlobalContext();
Type *RhTypeToLLType(rhine::Type *Ty);

#endif
