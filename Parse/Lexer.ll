/* -*- Bison -*- */
%{
#include "rhine/Lexer.h"
%}

%option c++ noyywrap nodefault warn yylineno stack

%option warn nodefault

LPAREN      "("
RPAREN      ")"
PLUS        "+"
MULTIPLY    "*"

NUMBER      [0-9]+
WS          [ \r\n\t]*

%%

{WS}            { /* Skip blanks. */ }
{NUMBER}        { return T::NUMBER; }

{MULTIPLY}      { return T::MULTIPLY; }
{PLUS}          { return T::PLUS; }
{LPAREN}        { return T::LPAREN; }
{RPAREN}        { return T::RPAREN; }
.               {  }

%%

// Required to fill vtable
int yyFlexLexer::yylex()
{
    return 0;
}
