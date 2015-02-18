#include "rhine/Ast.h"

using namespace rhine;

namespace rhine {
Function *emitAdd2Const() {
  auto F = Function::get(IntegerType::get());
  auto Op = AddInst::get(IntegerType::get());
  auto I1 = ConstantInt::get(3);
  auto I2 = ConstantInt::get(4);
  Op->addOperand(I1);
  Op->addOperand(I2);
  F->setName("foom");
  F->setBody(Op);
  return F;
}
}
