//-*- C++ -*-

#ifndef PARSETREE_H
#define PARSETREE_H

#include "rhine/Ast.h"
#include <vector>

namespace rhine {
class SExpr {
public:
  std::vector<AddInst *> Statements;
  std::vector<Function *> Defuns;
};
}

#endif
