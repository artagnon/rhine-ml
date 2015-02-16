#include "llvm/ADT/Optional.h"
#include <string>
#include <vector>

using namespace std;

namespace rhine {

class Type {
public:
  Type() {}
};

class IntegerType : public Type {
public:
  IntegerType() {}
};

class FloatType : public Type {
public:
  FloatType() {}
};

template <typename T> class FunctionType : public Type {
public:
  T ReturnType;
  FunctionType() {}
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

template <typename R, typename... Ts>
class Function : public Constant {
  Value *Val;
  std::vector<Type> AType;
  template <typename... As>
  void pushArguments() {
    AType = { (As())... };
  }
public:
  Function() : Constant(R()) {
    pushArguments<Ts...>();
  }
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
