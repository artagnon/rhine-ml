#ifndef SUPPORT_H
#define SUPPORT_H

#include "rhine/Ast.h"

namespace rhine {
llvm::Type *RhTypeToLL(rhine::Type *Ty);
llvm::Constant *RhConstantToLL(rhine::Constant *V);
Function *emitAdd2Const();
}

#endif
