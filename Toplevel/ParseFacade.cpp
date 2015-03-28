#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Module.h"

#include "rhine/Ast.h"
#include "rhine/ParseDriver.h"

#include <iostream>
#include <string>

namespace rhine {
std::string LLToPP (llvm::Value *Obj)
{
  std::string Output;
  llvm::raw_string_ostream OutputStream(Output);
  Obj->print(OutputStream);
  return OutputStream.str();
}

llvm::Value *parseCodeGenString(std::string PrgString,
                                llvm::Module *M,
                                std::ostream &ErrStream,
                                bool Debug)
{
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root, ErrStream, Debug);
  if (Driver.parseString(PrgString))
    return Root.Body.empty() ? Root.Defuns.back()->toLL(M) :
      Root.Body.back()->toLL(M);
  else
    return llvm::ConstantInt::get(RhContext, APInt(32, 0));
}

llvm::Value *parseCodeGenString(std::string PrgString,
                                std::ostream &ErrStream,
                                bool Debug)
{
  auto M = new llvm::Module("main", RhContext);
  return parseCodeGenString(PrgString, M, ErrStream, Debug);
}

void parseCodeGenFile(std::string Filename, llvm::Module *M, bool Debug) {
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root, std::cerr, Debug);
  Driver.parseFile(Filename);
  for (auto ve : Root.Body)
    ve->toLL(M);
  for (auto ve : Root.Defuns)
    ve->toLL(M);
  if (Debug)
    M->dump();
}
}
