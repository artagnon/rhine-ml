#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "gtest/gtest.h"

TEST(Statement, ConstantInt) {
  auto SourcePrg = "2 + 3;";
  auto Source = rhine::parsePrgString(SourcePrg);
  auto PP = rhine::LLToPP(Source);
  EXPECT_STREQ(PP.c_str(), "i32 5");
}
