//-*- C++ -*-

#ifndef SUPPORT_H
#define SUPPORT_H

#include "llvm/IR/Module.h"
#include "rhine/Ast.h"

namespace rhine {
Function *emitAdd2Const();
std::string LLToPP (llvm::Value *Obj);
llvm::Value *parsePrgString(std::string PrgString, bool Debug = false);
}

#endif
