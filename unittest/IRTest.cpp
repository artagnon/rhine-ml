#include "rhine/Ast.h"
#include "rhine/Support.h"
#include "gtest/gtest.h"

TEST(ToLL, ConstantInt) {
  auto Source = rhine::ConstantInt::get(32);
  auto PP = rhine::LLToPP(Source->toLL());
  EXPECT_STREQ(PP.c_str(), "i32 32");
}
