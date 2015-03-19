//-*- C++ -*-

#ifndef PARSETREE_H
#define PARSETREE_H

#include "rhine/Ast.h"
#include <vector>

using namespace std;

namespace rhine {
class SExpr {
public:
  std::vector<Value *> Body;
  std::vector<Function *> Defuns;
};
}

#endif
