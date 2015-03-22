//-*- C++ -*-

#ifndef SUPPORT_H
#define SUPPORT_H

#include <iostream>
#include "llvm/IR/Module.h"
#include "rhine/Ast.h"

namespace rhine {
Function *emitAdd2Const();
std::string LLToPP (llvm::Value *Obj);
llvm::Value *parsePrgString(std::string PrgString,
                            std::ostream &Out = std::cerr,
                            bool Debug = false);
}

#endif
