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
  virtual ~Type() {}
  Type *get() = delete;
  virtual bool containsTys() = 0;
};

class IntegerType : public Type {
public:
  static IntegerType *get() {
    return new IntegerType();
  }
  bool containsTys() {
    return false;
  }
};

class FloatType : public Type {
public:
  static FloatType *get() {
    return new FloatType();
  }
  bool containsTys() {
    return false;
  }
};

class FunctionType : public Type {
  Type *ReturnType;
  std::vector<Type *> ArgumentTypes;
public:
  template <typename R, typename... As>
  FunctionType(R RTy, As... ATys) {
    ReturnType = RTy;
    ArgumentTypes = { ATys... };
  }
  ~FunctionType() {
    delete ReturnType;
    ArgumentTypes.clear();
  }
  template <typename R, typename... As>
  static FunctionType *get(R RTy, As... ATys) {
    return new FunctionType(RTy, ATys...);
  }
  bool containsTys() {
    return true;
  }
};

template <typename T> class ArrayType : public Type {
public:
  T *elTy;
};

class Value {
  Type *VTy;
public:
  Value(Type *VTy) : VTy(VTy) {}
  virtual ~Value() {
    delete VTy;
  }
  Value *get() = delete;
  Type *getType() {
    return VTy;
  }
  virtual bool containsVs() = 0;
};

class Constant : public Value {
public:
  Constant(Type *Ty) : Value(Ty) {}
  bool containsVs() {
    return false;
  }
};

class ConstantInt : public Constant {
public:
  int Val;
  ConstantInt(int Val) : Constant(IntegerType::get()), Val(Val) {}
  static ConstantInt *get(int Val) {
    return new ConstantInt(Val);
  }
  int getVal() {
    return Val;
  }
  bool containsVs() {
    return false;
  }
};

class ConstantFloat : public Constant {
public:
  float Val;
  ConstantFloat(float Val) : Constant(FloatType::get()), Val(Val) {}
  float getVal() {
    return Val;
  }
};

class Function : public Constant {
  std::string Name;
  Value *Val;
public:
  template <typename R, typename... As>
  Function(R RTy, As... ATys) : Constant(FunctionType::get(RTy, ATys...)) {}
  ~Function() {
    delete Val;
  }
  void setName(std::string N) {
    Name = N;
  }
  void setBody(Value *Body) {
    Val = Body;
  }
  template <typename R, typename... As>
  static Function *get(R RTy, As... ATys) {
    return new Function(RTy, ATys...);
  }
  std::string getName() {
    return Name;
  }
  Value *getVal() {
    return Val;
  }
  bool containsVs() {
    return true;
  }
};

template <typename T> class ConstantArray : public Constant {
public:
  std::vector<T> Val;
  bool containsVs() {
    return true;
  }
};

class Variable : public Value {
  std::string Name;
  llvm::Optional<Constant> Binding;
public:
  bool containsVs() {
    return true;
  }
};

class Instruction : public Value {
  unsigned NumOperands;
  std::vector<Value *> OperandList;
public:
  Instruction(Type *Ty) : Value(Ty) {}
  void addOperand(Value *V) {
    OperandList.push_back(V);
    NumOperands++;
  }
  Value *getOperand(unsigned i) {
    return OperandList[i];
  }
  bool containsVs() {
    return true;
  }
};

class AddInst : public Instruction {
public:
  AddInst(Type *Ty) : Instruction(Ty) {}
  static AddInst *get(Type *Ty) {
    return new AddInst(Ty);
  }
  bool containsVs() {
    return true;
  }
};
}

#endif
