#ifndef AST_H
#define AST_H

#include "llvm/ADT/Optional.h"
#include <string>
#include <vector>

using namespace std;

namespace rhine {

class Type {
public:
  Type() {}
  Type *get() = delete;
  virtual bool containsTys();
};

class IntegerType : public Type {
public:
  IntegerType() {}
  static Type *get() {
    return new IntegerType();
  }
  bool containsTys() {
    return false;
  }
};

class FloatType : public Type {
public:
  FloatType() {}
  static Type *get() {
    return new FloatType();
  }
  bool containsTys() {
    return false;
  }
};

class FunctionType : public Type {
  Type ReturnType;
  std::vector<Type> ArgumentTypes;
public:
  template <typename R, typename... As>
    FunctionType(R RTy, As... ATys) {
    ReturnType = RTy;
    ArgumentTypes = { ATys... };
  }
};

template <typename T> class ArrayType : public Type {
public:
  T *elTy;
};

class Value {
public:
  Type VTy;
  Value(Type VTy) : VTy(VTy) {}
};

class Constant : public Value {
public:
  Constant(Type Ty) : Value(Ty) {}
};

class ConstantInt : public Constant {
public:
  int Val;
  ConstantInt(int Val) : Constant(IntegerType()), Val(Val) {}
  int getVal() {
    return Val;
  }
};

class ConstantFloat : public Constant {
public:
  float Val;
  ConstantFloat(float Val) : Constant(FloatType()), Val(Val) {}
  float getVal() {
    return Val;
  }
};

class Function : public Constant {
  Value *Val;
public:
  template <typename R, typename... As>
    Function(R RTy, As... ATys) : Constant(FunctionType(RTy, ATys...)) {}
  void setBody(Value *Body) {
    Val = Body;
  }
  Value *getVal() {
    return Val;
  }
};

template <typename T> class ConstantArray : public Constant {
public:
  std::vector<T> Val;
};

class Variable : public Value {
public:
  std::string Name;
  llvm::Optional<Constant> Binding;
};

class Instruction : public Value {
public:
  unsigned NumOperands;
  std::vector<Value *> OperandList;
  Instruction(Type Ty) : Value(Ty) {}
  void addOperand(Value *V) {
    OperandList.push_back(V);
    NumOperands++;
  }
};

template <typename T> class AddInst : public Instruction {
public:
  AddInst() : Instruction(T()) {}
};
}

#endif
