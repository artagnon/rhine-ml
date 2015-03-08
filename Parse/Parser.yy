// -*- mode: bison -*-
%{
#include <iostream>
%}

%debug
%name-prefix "rhine"
%skeleton "lalr1.cc"
%locations

%initial-action
{
    @$.begin.filename = @$.end.filename = &Driver->StreamName;
};

%token-table
%define parser_class_name { Parser }
%defines

%parse-param { class ParseDriver *Driver }
%error-verbose

%union {
  int RawInteger;
  std::string *RawSymbol;
  class ConstantInt *Integer;
  class ConstantFloat *Float;
  class AddInst *AddOp;
  class Function *Fcn;
}

%start start

%token                  DEFUN
%token                  END       0
%token  <RawInteger>    INTEGER
%token  <RawSymbol>     SYMBOL
%type   <Integer>       constant
%type   <AddOp>         statement
%type   <Fcn>           defun

%{
#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

#undef yylex
#define yylex Driver->Lexx->lex
%}

%%

start:
        |       statement END
                {
                  Driver->Root.Statements.push_back($1);
                }

        |       defun END
                {
                  Driver->Root.Defuns.push_back($1);
                }

                ;
defun:
                DEFUN SYMBOL[N] '[' symbol_list[A] ']' statement[B]
                {
                  auto FTy = FunctionType::get(IntegerType::get());
                  auto Fn = Function::get(FTy);
                  Fn->setName(*$N);
                  Fn->setBody($B);
                  $$ = Fn;
                }
                ;
symbol_list:
		  SYMBOL
		| symbol_list SYMBOL
                ;

statement:
                '+' constant[L] constant[R]
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
{
  std::cerr << l << ": " << m << std::endl;
}
