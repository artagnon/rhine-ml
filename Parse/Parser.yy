// -*- Bison -*-
%{
#include "rhine/Lexer.h"
#include "rhine/ParseDriver.h"

#undef yylex
#define yylex Driver->Lexer->lex
%}

%name-prefix "rhine"
%parse-param { ParseDriver *Driver }

%skeleton "lalr1.cc"
%locations
%token-table

%union {
    int intValue;
    double doubleValue;
}

%left '+' PLUS
%left '*' MULTIPLY

%token LPAREN
%token RPAREN
%token PLUS
%token MULTIPLY
%token END
%token <intValue> NUMBER

%type <doubleValue> expr

%%

input
    : expr { root->dExpressions.push_back($1); }
    ;

expr
    : expr[L] PLUS expr[R] { $$ = ( token::PLUS, $L, $R ); }
    | expr[L] MULTIPLY expr[R] { $$ = ( token::MULTIPLY, $L, $R ); }
    | LPAREN expr[E] RPAREN { $$ = $E; }
    | NUMBER { $$ = $1; }
    ;

%%

void rhine::parser::error(const rhine::location& l,
			  const std::string& m)
{}
