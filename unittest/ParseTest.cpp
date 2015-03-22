#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "gtest/gtest.h"

#include <regex>

TEST(Statement, ConstantInt) {
  auto SourcePrg = "2 + 3;";
  std::ostringstream Scratch;
  auto Source = rhine::parsePrgString(SourcePrg, Scratch);
  auto PP = rhine::LLToPP(Source);
  EXPECT_STREQ(PP.c_str(), "i32 5");
}

TEST(Statement, BareDefun) {
  auto SourcePrg = "defun foo [bar]";
  std::regex AnsiColorRe("\\x1b\\[[0-9;]*m");
  std::ostringstream Scratch;
  rhine::parsePrgString(SourcePrg, Scratch);
  auto Actual = Scratch.str();
  auto CleanedActual = std::regex_replace(Actual, AnsiColorRe, "");
  EXPECT_PRED_FORMAT2(::testing::IsSubstring,
                      "string stream:1:16: error: syntax error",
                      CleanedActual.c_str());
}
