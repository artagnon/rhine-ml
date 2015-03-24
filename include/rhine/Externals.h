#ifndef EXTERNALS_H
#define EXTERNALS_H

#include "llvm/IR/Function.h"

namespace rhine {
struct Externals {
  static llvm::Function *printf(Module *M);
};
}

#endif
