#include "Ast.h"

using namespace rhine;

Value *emitAdd2Const() {
  auto F = new Function(IntegerType::get());
  auto Op = new AddInst<IntegerType>();
  auto I1 = new ConstantInt(3);
  auto I2 = new ConstantInt(4);
  Op->addOperand(I1);
  Op->addOperand(I2);
  F->setBody(Op);
  return F;
}
