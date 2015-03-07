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
    int Integer;
    double Double;
}

%token LPAREN
%token RPAREN
%left PLUS
%left MULTIPLY
%token END
%token <Integer> INTEGER
%type <Integer> expr

%{
#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

#undef yylex
#define yylex Driver->Lexx->lex
%}

%%

input:
    | expr { Driver->Root.Integers.push_back($1); }
    ;

expr:
      INTEGER { $$ = $1; }
    | expr[L] PLUS expr[R] { $$ = $L + $R; }
    | expr[L] MULTIPLY expr[R] { $$ = $L * $R; }
    | LPAREN expr[E] RPAREN { $$ = $E; }
    ;

%%

void rhine::Parser::error(const rhine::location& l,
			  const std::string& m)
{}
