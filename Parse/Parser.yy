// -*- mode: bison -*-
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
  int RawInteger;
  class ConstantInt *Integer;
  class ConstantFloat *Float;
  class AddInst *AddOp;
}

%token LPAREN
%token RPAREN
%left PLUS
%left MULTIPLY
%token END
%token <RawInteger> INTEGER
%type <Integer> constant
%type <AddOp> statement

%{
#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

#undef yylex
#define yylex Driver->Lexx->lex
%}

%%

input:
                statement
                 {
                   Driver->Root.Statements.push_back($1);
                 }

                ;

statement:
                PLUS constant[L] constant[R]
                {
                  auto Op = AddInst::get(IntegerType::get());
                  Op->addOperand($L);
                  Op->addOperand($R);
                  $$ = Op;
                }

                ;
constant:
                INTEGER
                {
                  $$ = ConstantInt::get($1);
                }

                ;
%%

void rhine::Parser::error(const rhine::location& l,
			  const std::string& m)
{}
