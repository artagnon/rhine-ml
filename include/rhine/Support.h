//-*- C++ -*-

#ifndef SUPPORT_H
#define SUPPORT_H

#include "rhine/Ast.h"

namespace rhine {
Function *emitAdd2Const(llvm::Module *M);
}

#endif
