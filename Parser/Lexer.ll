/* -*- Bison -*- */
%{
#include "rhine/Parser.h"
typedef yy::parser::token T;
%}

%option c++ noyywrap nodefault warn yylineno stack

%option outfile="Parser/Lexer.cpp" header-file="include/rhine/Lexer.h"
%option warn nodefault

LPAREN      "("
RPAREN      ")"
PLUS        "+"
MULTIPLY    "*"

NUMBER      [0-9]+
WS          [ \r\n\t]*

%%

{WS}            { /* Skip blanks. */ }
{NUMBER}        { return T::TOKEN_NUMBER; }

{MULTIPLY}      { return T::TOKEN_MULTIPLY; }
{PLUS}          { return T::TOKEN_PLUS; }
{LPAREN}        { return T::TOKEN_LPAREN; }
{RPAREN}        { return T::TOKEN_RPAREN; }
.               {  }

%%
