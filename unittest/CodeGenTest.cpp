#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "gtest/gtest.h"

#include <regex>

void EXPECT_PARSE_PP(std::string SourcePrg, std::string *ExpectedErr = nullptr,
                     std::string *ExpectedPP = nullptr)
{
  std::regex AnsiColorRe("\\x1b\\[[0-9;]*m");
  std::ostringstream Scratch;
  auto Source = rhine::parseCodeGenString(SourcePrg, Scratch);
  auto Actual = Scratch.str();
  auto CleanedActual = std::regex_replace(Actual, AnsiColorRe, "");
  if (ExpectedErr) {
    ASSERT_EQ(ExpectedPP, nullptr);
    EXPECT_PRED_FORMAT2(::testing::IsSubstring, ExpectedErr->c_str(),
                        CleanedActual.c_str());
  } else {
    ASSERT_NE(ExpectedPP, nullptr);
    ASSERT_STREQ("", CleanedActual.c_str());
    auto PP = rhine::LLToPP(Source);
    EXPECT_PRED_FORMAT2(::testing::IsSubstring, ExpectedPP->c_str(),
                        PP.c_str());
  }
}

TEST(Statement, ConstantInt)
{
  std::string SourcePrg = "2 + 3;";
  std::string ExpectedPP = "i32 5";
  EXPECT_PARSE_PP(SourcePrg, nullptr, &ExpectedPP);
}

TEST(Statement, BareDefun)
{
  std::string SourcePrg = "defun foo [bar]";
  std::string ExpectedErr = "string stream:1:16: error: syntax error";
  EXPECT_PARSE_PP(SourcePrg, &ExpectedErr);
}

TEST(Statement, DefunStm)
{
  std::string SourcePrg = "defun foo [bar] 3 + 2;";
  std::string ExpectedPP =
    "define i32 @foo() {\n"
    "entry:\n"
    "  ret i32 5\n"
    "}\n";
  EXPECT_PARSE_PP(SourcePrg, nullptr, &ExpectedPP);
}

TEST(Statement, DefunCompoundStm)
{
  std::string SourcePrg =
    "defun foo [bar]\n"
    "{\n"
    "  3 + 2;\n"
    "  4 + 5;\n"
    "}";
  std::string ExpectedPP =
    "define i32 @foo() {\n"
    "entry:\n"
    "  ret i32 9\n"
    "}\n";
  EXPECT_PARSE_PP(SourcePrg, nullptr, &ExpectedPP);
}

TEST(Statement, FunctionCall)
{
  std::string SourcePrg = "printf \"43\";";
  std::string ExpectedPP =
    "call i32 (i8*, ...)* @printf";
  EXPECT_PARSE_PP(SourcePrg, nullptr, &ExpectedPP);
}
