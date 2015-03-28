//-*- C++ -*-

#ifndef SUPPORT_H
#define SUPPORT_H

#include <iostream>
#include "llvm/IR/Module.h"
#include "rhine/Ast.h"

namespace rhine {
//===--------------------------------------------------------------------===//
// Meant to be used by unittests.
//===--------------------------------------------------------------------===//
std::string LLToPP (llvm::Value *Obj);

llvm::Value *parseCodeGenString(std::string PrgString,
                                llvm::Module *M,
                                std::ostream &ErrStream = std::cerr,
                                bool Debug = false);

llvm::Value *parseCodeGenString(std::string PrgString,
                                std::ostream &Out = std::cerr,
                                bool Debug = false);

//===--------------------------------------------------------------------===//
// Meant to be used by normal codepath: jitFacade.
//===--------------------------------------------------------------------===//
void parseCodeGenFile(std::string Filename, llvm::Module *M, bool Debug);
}

#endif
