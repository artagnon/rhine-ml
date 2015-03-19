//-*- C++ -*-

#ifndef AST_H
#define AST_H

#include "llvm/IR/Module.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/TypeBuilder.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Constants.h"
#include "llvm/ADT/Optional.h"
#include "llvm/ADT/STLExtras.h"
#include <string>
#include <vector>

using namespace std;

namespace rhine {
using namespace llvm;

static LLVMContext &RhContext = getGlobalContext();
static IRBuilder<> RhBuilder(RhContext);

class Type {
public:
  static Type *get() {
    return new Type();
  }
  virtual ~Type() { };
  virtual llvm::Type *toLL(llvm::Module *M = nullptr) {
    assert(false && "Cannot toLL() without inferring type");
  }
};

class IntegerType : public Type {
public:
  static IntegerType *get() {
    return new IntegerType();
  }
  llvm::Type *toLL(llvm::Module *M = nullptr);
};

class FloatType : public Type {
public:
  static FloatType *get() {
    return new FloatType();
  }
  llvm::Type *toLL(llvm::Module *M = nullptr);
};

class FunctionType : public Type {
  Type *ReturnType;
  std::vector<Type *> ArgumentTypes;
public:
  template <typename R, typename... As>
  FunctionType(R RTy, As... ATys) {
    ReturnType = RTy;
    ArgumentTypes = {ATys...};
  }
  ~FunctionType() {
    delete ReturnType;
    for (auto i : ArgumentTypes)
      delete i;
    ArgumentTypes.clear();
  }
  template <typename R, typename... As>
  static FunctionType *get(R RTy, As... ATys) {
    return new FunctionType(RTy, ATys...);
  }
  Type *getATy(unsigned i) {
    return ArgumentTypes[i];
  }
  llvm::Type *toLL(llvm::Module *M = nullptr);
};

template <typename T> class ArrayType : public Type {
public:
  T *elTy;
  llvm::Type *toLL(llvm::Module *M = nullptr);
};

class Value {
  Type *VTy;
public:
  Value(Type *VTy) : VTy(VTy) {}
  virtual ~Value() { delete VTy; };
  Value *get() = delete;
  Type *getType() {
    return VTy;
  }
  virtual bool containsVs() = 0;
  virtual llvm::Value *toLL(llvm::Module *M = nullptr) = 0;
};

class Constant : public Value {
public:
  Constant(Type *Ty) : Value(Ty) {}
  bool containsVs() {
    return false;
  }
private:
  llvm::Constant *toLL(llvm::Module *M = nullptr) { return nullptr; }
};

class Variable : public Value {
  std::string Name;
  Value *Binding;
public:
  Variable(std::string N, Value *B = nullptr) :
      Value(Type::get()), Name(N), Binding(B) {}

  static Variable *get(std::string N, Value *B = nullptr) {
    return new Variable(N, B);
  }
  std::string getName() {
    return Name;
  }
  Value *getVal() {
    return Binding;
  }
  bool containsVs() {
    return true;
  }
  llvm::Value *toLL(llvm::Module *M = nullptr);
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
  llvm::Constant *toLL(llvm::Module *M = nullptr);
};

class ConstantFloat : public Constant {
public:
  float Val;
  ConstantFloat(float Val) : Constant(FloatType::get()), Val(Val) {}
  float getVal() {
    return Val;
  }
  llvm::Constant *toLL(llvm::Module *M = nullptr);
};

class Function : public Constant {
  std::vector<Variable *> ArgumentList;
  std::string Name;
  std::vector<Value *> Val;
public:
  Function(FunctionType *FTy) :
      Constant(FTy) {}
  ~Function() {
    for (auto i : ArgumentList)
      delete i;
    ArgumentList.clear();
    for (auto i : Val)
      delete i;
    Val.clear();
  }
  static Function *get(FunctionType *FTy) {
    return new Function(FTy);
  }
  void setName(std::string N) {
    Name = N;
  }
  void setBody(std::vector<Value *> Body) {
    Val = Body;
  }
  std::string getName() {
    return Name;
  }
  Value *getVal() {
    return Val.back();
  }
  bool containsVs() {
    return true;
  }
  llvm::Constant *toLL(llvm::Module *M = nullptr);
};

class Instruction : public Value {
  unsigned NumOperands;
  std::vector<Value *> OperandList;
public:
  Instruction(Type *Ty) :
      Value(Ty) {}
  ~Instruction() {
    for (auto i : OperandList)
      delete i;
    OperandList.clear();
  }
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
private:
  llvm::Value *toLL(llvm::Module *M = nullptr) { return nullptr; }
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
  llvm::Value *toLL(llvm::Module *M = nullptr);
};

class LLVisitor
{
public:
  static llvm::Type *visit(IntegerType *V) {
    return RhBuilder.getInt32Ty();
  }
  static llvm::Type *visit(FloatType *V) {
    return RhBuilder.getFloatTy();
  }
  static llvm::Constant *visit(ConstantInt *I) {
    return llvm::ConstantInt::get(RhContext, APInt(32, I->getVal()));
  }
  static llvm::Constant *visit(ConstantFloat *F) {
    return llvm::ConstantFP::get(RhContext, APFloat(F->getVal()));
  }
  static llvm::Constant *visit(Function *RhF, llvm::Module *M) {
    llvm::Value *RhV = RhF->getVal()->toLL();
    auto F = llvm::Function::Create(llvm::FunctionType::get(RhV->getType(), false),
                                    GlobalValue::ExternalLinkage,
                                    RhF->getName(), M);
    BasicBlock *BB = BasicBlock::Create(rhine::RhContext, "entry", F);
    rhine::RhBuilder.SetInsertPoint(BB);
    rhine::RhBuilder.CreateRet(RhV);
    return F;
  }
  static llvm::Value *visit(Variable *V) {
    assert (V && "Cannot lower unbound variable");
    return V->toLL();
  }
  static llvm::Value *visit(AddInst *A) {
    auto Op0 = A->getOperand(0)->toLL();
    auto Op1 = A->getOperand(1)->toLL();
    return RhBuilder.CreateAdd(Op0, Op1);
  }
};
}

#endif
