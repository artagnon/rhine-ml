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

class BoolType : public Type {
public:
  static BoolType *get() {
    return new BoolType();
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

class StringType : public Type {
public:
  static StringType *get() {
    return new StringType();
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
  virtual llvm::Value *toLL(llvm::Module *M = nullptr) = 0;
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
  llvm::Value *toLL(llvm::Module *M = nullptr);
};

class GlobalString : public Value {
public:
  std::string Val;
  GlobalString(std::string Val) : Value(StringType::get()), Val(Val) {}
  static GlobalString *get(std::string Val) {
    return new GlobalString(Val);
  }
  std::string getVal() {
    return Val;
  }
  // Returns GEP to GlobalStringPtr, which is a Value; data itself is in
  // constant storage.
  llvm::Value *toLL(llvm::Module *M = nullptr);
};

class Constant : public Value {
public:
  Constant(Type *Ty) : Value(Ty) {}
private:
  llvm::Constant *toLL(llvm::Module *M = nullptr) { return nullptr; }
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
  llvm::Constant *toLL(llvm::Module *M = nullptr);
};

class ConstantBool : public Constant {
public:
  bool Val;
  ConstantBool(bool Val) : Constant(BoolType::get()), Val(Val) {}
  static ConstantBool *get(bool Val) {
    return new ConstantBool(Val);
  }
  float getVal() {
    return Val;
  }
  llvm::Constant *toLL(llvm::Module *M = nullptr);
};

class ConstantFloat : public Constant {
public:
  float Val;
  ConstantFloat(float Val) : Constant(FloatType::get()), Val(Val) {}
  static ConstantFloat *get(float Val) {
    return new ConstantFloat(Val);
  }
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
  void setArgumentList(std::vector<Variable *> L) {
    ArgumentList = L;
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
private:
  llvm::Value *toLL(llvm::Module *M = nullptr) { return nullptr; }
};

class AddInst : public Instruction {
public:
  AddInst(Type *Ty) : Instruction(Ty) {}
  static AddInst *get(Type *Ty) {
    return new AddInst(Ty);
  }
  llvm::Value *toLL(llvm::Module *M = nullptr);
};

class CallInst : public Instruction {
public:
  // May be untyped
  CallInst(std::string FunctionName, Type *Ty = IntegerType::get()) :
      Instruction(Ty), Name(FunctionName) {}
  static CallInst *get(std::string FunctionName, Type *Ty = IntegerType::get()) {
    return new CallInst(FunctionName, Ty);
  }
  std::string getName() {
    return Name;
  }
  llvm::Value *toLL(llvm::Module *M = nullptr);
private:
  std::string Name;
};

class LLVisitor
{
public:
  static llvm::Type *visit(IntegerType *V);
  static llvm::Type *visit(BoolType *V);
  static llvm::Type *visit(FloatType *V);
  static llvm::Type *visit(StringType *V);
  static llvm::Value *visit(Variable *V);
  static llvm::Value *visit(GlobalString *S);
  static llvm::Constant *visit(ConstantInt *I);
  static llvm::Constant *visit(ConstantBool *B);
  static llvm::Constant *visit(ConstantFloat *F);
  static llvm::Constant *visit(Function *RhF, llvm::Module *M);
  static llvm::Value *visit(AddInst *A);
  static llvm::Value *visit(CallInst *C, llvm::Module *M);
};
}

#endif
