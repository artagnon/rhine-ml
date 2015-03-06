// -*- Bison -*-
%{
%}

%debug
%name-prefix "rhine"
%skeleton "lalr1.cc"
%locations
%token-table
%define parser_class_name { Parser }
%defines

%parse-param { class ParseDriver *Driver }

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

%{
#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

#undef yylex
#define yylex Driver->Lexx->lex
%}

%%

input
    : expr { Driver->Root.dExpressions.push_back($1); }
    ;

expr
    : expr[L] PLUS expr[R] { $$ = ( token::PLUS, $L, $R ); }
    | expr[L] MULTIPLY expr[R] { $$ = ( token::MULTIPLY, $L, $R ); }
    | LPAREN expr[E] RPAREN { $$ = $E; }
    | NUMBER { $$ = $1; }
    ;

%%

void rhine::Parser::error(const rhine::location& l,
			  const std::string& m)
{}
