#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "gtest/gtest.h"

TEST(Statement, ConstantInt) {
  auto SourcePrg = "2 + 3;";
  std::ostringstream Scratch;
  auto Source = rhine::parsePrgString(SourcePrg, Scratch);
  auto PP = rhine::LLToPP(Source);
  EXPECT_STREQ(PP.c_str(), "i32 5");
}

TEST(Statement, BareDefun) {
  auto SourcePrg = "defun foo [bar]";
  std::ostringstream Scratch;
  rhine::parsePrgString(SourcePrg, Scratch);
  EXPECT_PRED_FORMAT2(::testing::IsSubstring, "string stream:1.16: syntax error",
                      Scratch.str().c_str());
}
