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
  std::string *RawSymbol;
  class ConstantInt *Integer;
  class ConstantFloat *Float;
  class AddInst *AddOp;
  class Function *Fcn;
  std::vector<class Variable *> *VarList;
  std::vector<class Value *> *Body;
}

%start start

%token                  DEFUN
%token                  IF
%token                  END       0
%token  <RawSymbol>     SYMBOL
%token  <Integer>       INTEGER
%type   <VarList>       symbol_list
%type   <AddOp>         expression
%type   <Body>          statement_list
%type   <Fcn>           fn_decl defun

%destructor { delete $$; } SYMBOL INTEGER
%destructor { delete $$; } symbol_list
%destructor { delete $$; } expression
%destructor { delete $$; } statement_list
%destructor { delete $$; } fn_decl defun

%{
#include "rhine/ParseDriver.h"
#include "rhine/Lexer.h"

#undef yylex
#define yylex Driver->Lexx->lex
%}

%%

start:
                tlexpr END
        |       start tlexpr END
                ;


tlexpr:
                statement_list[L]
                {
                  Driver->Root.Body = *$L;
                }
        |       defun[D]
                {
                  Driver->Root.Defuns.push_back($D);
                }
                ;

fn_decl:
                DEFUN SYMBOL[N] '[' symbol_list[A] ']'
                {
                  auto ITy = IntegerType::get();
                  auto FTy = FunctionType::get(ITy);
                  auto Fn = Function::get(FTy);
                  Fn->setName(*$N);
                  $$ = Fn;
                }
                ;
defun:
                fn_decl[F] '{' statement_list[V] '}'
                {
                  $F->setBody(*$V);
                  $$ = $F;
                }
                ;
statement_list:
                expression[E] ';'
                {
                  auto StatementList = new std::vector<Value *>;
                  StatementList->push_back($E);
                  $$ = StatementList;
                }
        |       statement_list[L] expression[E] ';'
                {
                  $L->push_back($E);
                  $$ = $L;
                }
                ;
symbol_list:
                SYMBOL[S]
                {
                  auto SymbolList = new std::vector<Variable *>;
                  auto Sym = Variable::get(*$S);
                  SymbolList->push_back(Sym);
                  $$ = SymbolList;
                }
        |       symbol_list[L] SYMBOL[S]
                {
                  auto Sym = Variable::get(*$S);
                  $L->push_back(Sym);
                  $$ = $L;
                }
                ;
expression:
                INTEGER[L] '+' INTEGER[R]
                {
                  auto Op = AddInst::get(IntegerType::get());
                  Op->addOperand($L);
                  Op->addOperand($R);
                  $$ = Op;
                }
                ;
%%

void rhine::Parser::error(const rhine::location& l,
			  const std::string& m)
{
  std::cerr << l << ": " << m << std::endl;
}
