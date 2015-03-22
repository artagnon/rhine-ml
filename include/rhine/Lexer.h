// -*- C++ -*-

#ifndef LEXER_H
#define LEXER_H

// Flex expects the signature of yylex to be defined in the macro YY_DECL, and
// the C++ parser expects it to be declared. We can factor both as follows.

#include "Parser.hpp"

typedef rhine::Parser P;
typedef P::token T;

#define yyterminate() return T::END

#define	YY_DECL		       			\
    P::token_type				\
    rhine::Lexer::lex(                          \
	P::semantic_type* yylval,		\
	P::location_type* yylloc		\
    )

#ifndef __FLEX_LEXER_H
#include <FlexLexer.h>
#endif

/** Scanner is a derived class to add some extra function to the scanner
 * class. Flex itself creates a class named yyFlexLexer. However we change the
 * context of the generated yylex() function to be contained within the Lexer
 * class. This is required because the yylex() defined in yyFlexLexer has no
 * parameters. */
namespace rhine {
class Lexer : public yyFlexLexer {
public:
  Lexer(std::istream* arg_yyin = 0, std::ostream* arg_yyout = 0) :
      yyFlexLexer(arg_yyin, arg_yyout) {}
  void LexerError(const char msg[]) {
    *yyout << msg << std::endl;
  }
  virtual ~Lexer() {}
  virtual P::token_type lex(P::semantic_type* yylval,
                            P::location_type* yylloc);
};
}

#endif
