#include "llvm/Support/raw_ostream.h"
#include "llvm/IR/Module.h"

#include "rhine/Ast.h"
#include "rhine/ParseDriver.h"

#include <iostream>
#include <string>

namespace rhine {
std::string LLToPP (llvm::Value *Obj) {
  std::string Output;
  llvm::raw_string_ostream OutputStream(Output);
  Obj->print(OutputStream);
  return OutputStream.str();
}

llvm::Value *parsePrgString(std::string PrgString, bool Debug) {
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root, Debug);
  Driver.parseString(PrgString);
  return Root.Body.back()->toLL();
}

void parseFacade(std::string Filename, bool Debug) {
  auto Root = rhine::SExpr();
  auto Driver = rhine::ParseDriver(Root, Debug);
  Driver.parseFile(Filename);
  std::cout << "Statements:" << std::endl;
  for (auto ve : Root.Body)
    ve->toLL()->dump();
  std::cout << "Defuns:" << std::endl;
  for (auto ve : Root.Defuns)
    ve->toLL()->dump();
}
}
