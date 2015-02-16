#ifndef SUPPORT_H
#define SUPPORT_H

#include "llvm/IR/LLVMContext.h"

#include "Ast.h"

using namespace llvm;

Type *RhTypeToLLType(rhine::Type *Ty);

#endif
