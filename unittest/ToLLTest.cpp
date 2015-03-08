#include "llvm/Support/raw_ostream.h"
#include "rhine/Ast.h"
#include "gtest/gtest.h"

TEST(ToLLTest, ConstantInt) {
  auto Source = rhine::ConstantInt::get(32);
  auto Converted = Source->toLL();
  std::string Output;
  llvm::raw_string_ostream OutputStream(Output);
  Converted->print(OutputStream);
  EXPECT_STREQ(OutputStream.str().c_str(), "i32 32");
}
