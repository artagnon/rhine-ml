// -*- C++ -*-

#ifndef LEXER_H
#define LEXER_H

// Flex expects the signature of yylex to be defined in the macro YY_DECL, and
// the C++ parser expects it to be declared. We can factor both as follows.

#include "rhine/ParseTree.h"
#include "Parser.hpp"

typedef rhine::parser P;
typedef P::token T;

#define yyterminate() return T::END

#define	YY_DECL		       			\
    P::token_type				\
    rhine::rhFlexLexer::lex(                    \
	P::semantic_type* yylval,		\
	P::location_type* yylloc		\
    )

#ifndef __FLEX_LEXER_H
#include <FlexLexer.h>
#endif

/** Scanner is a derived class to add some extra function to the scanner
 * class. Flex itself creates a class named yyFlexLexer, which is renamed using
 * macros to ExampleFlexLexer. However we change the context of the generated
 * yylex() function to be contained within the Scanner class. This is required
 * because the yylex() defined in ExampleFlexLexer has no parameters. */
namespace rhine {
class rhFlexLexer : public yyFlexLexer {
public:
  rhFlexLexer(std::istream* arg_yyin = 0, std::ostream* arg_yyout = 0) {}
  virtual ~rhFlexLexer() {}
  virtual P::token_type lex(P::semantic_type* yylval,
                            P::location_type* yylloc);
};
}

#endif
