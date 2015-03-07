/* -*- Bison -*- */
%{
#include "rhine/Lexer.h"
%}

%option c++ noyywrap nodefault warn yylineno stack

%option warn nodefault

SYMBOLC [a-z A-Z ? - * / < > = . % ^]
SYMBOL  [[:alpha:]][[:alnum:]]+
EXP     [Ee][- +]?[[:digit:]]+
INTEGER [- +]?[[:digit:]]+
WS      [ \r\n\t]*

%%

{WS} ;

{INTEGER} {
  yylval->RawInteger = atoi(yytext);
  return T::INTEGER;
}

"defun" { return T::DEFUN; }

{SYMBOL} {
  yylval->RawSymbol = new std::string(yytext, yyleng);
  return T::SYMBOL;
}

[\[ \] \( \) + *] {
  return static_cast<P::token_type>(*yytext);
}

. ;

%%

// Required to fill vtable
int yyFlexLexer::yylex()
{
  return 0;
}
