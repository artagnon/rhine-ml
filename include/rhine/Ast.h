#ifndef AST_H
#define AST_H

#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/TypeBuilder.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Constants.h"
#include "llvm/ADT/Optional.h"
#include <string>
#include <vector>

using namespace std;

namespace rhine {
using namespace llvm;

static LLVMContext &RhContext = getGlobalContext();
static IRBuilder<> RhBuilder(RhContext);

class Type {
public:
  Type() {}
  virtual ~Type() {}
  Type *get() = delete;
  virtual bool containsTys() = 0;
  virtual llvm::Type *toLL() = 0;
};

class IntegerType : public Type {
public:
  static IntegerType *get() {
    return new IntegerType();
  }
  bool containsTys() {
    return false;
  }
  llvm::Type *toLL();
};

class FloatType : public Type {
public:
  static FloatType *get() {
    return new FloatType();
  }
  bool containsTys() {
    return false;
  }
  llvm::Type *toLL();
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
  llvm::Type *toLL();
};

template <typename T> class ArrayType : public Type {
public:
  T *elTy;
  llvm::Type *toLL();
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
  llvm::Constant *toLL();
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
  llvm::Constant *toLL();
};

class ConstantFloat : public Constant {
public:
  float Val;
  ConstantFloat(float Val) : Constant(FloatType::get()), Val(Val) {}
  float getVal() {
    return Val;
  }
  llvm::Constant *toLL();
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
  llvm::Constant *toLL();
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
  llvm::Value *toLL();
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
  llvm::Value *toLL();
};

class LLVisitor
{
public:
  static llvm::Type *visit(rhine::IntegerType *V) {
    return TypeBuilder<types::i<32>, true>::get(RhContext);
  }
  static llvm::Type *visit(rhine::FloatType *V) {
    return llvm::Type::getFloatTy(RhContext);
  }
  static llvm::Constant *visit(rhine::ConstantInt *I) {
    return llvm::ConstantInt::get(RhContext, APInt(32, I->getVal()));
  }
  static llvm::Constant *visit(rhine::ConstantFloat *F) {
    return llvm::ConstantFP::get(RhContext, APFloat(F->getVal()));
  }
  static llvm::Value *visit(rhine::AddInst *A) {
    auto Op0 = dynamic_cast<rhine::ConstantInt *>(A->getOperand(0))->toLL();
    auto Op1 = dynamic_cast<rhine::ConstantInt *>(A->getOperand(1))->toLL();
    return RhBuilder.CreateAdd(Op0, Op1);
  }
};
}

#endif
