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
  class GlobalString *String;
  class Instruction *Inst;
  class Function *Fcn;
  std::vector<class Variable *> *VarList;
  std::vector<class Value *> *StmList;
}

%start start

%token                  DEFUN
%token                  IF
%token                  THEN
%token                  END       0
%token  <RawSymbol>     SYMBOL
%token  <Integer>       INTEGER
%token  <String>        STRING
%type   <VarList>       symbol_list
%type   <Inst>          expression
%type   <StmList>       compound_stm stm_list single_stm
%type   <Fcn>           fn_decl defun

%destructor { delete $$; } SYMBOL INTEGER
%destructor { delete $$; } symbol_list
%destructor { delete $$; } expression
%destructor { delete $$; } stm_list
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
                stm_list[L]
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
                fn_decl[F] compound_stm[L]
                {
                  $F->setBody(*$L);
                  $$ = $F;
                }
                ;
compound_stm:
                '{' stm_list[L] '}'
                {
                  $$ = $L;
                }
        |       single_stm[L]
                {
                  $$ = $L;
                }
stm_list:
                single_stm[L]
                {
                  $$ = $L;
                }
        |       stm_list[L] expression[E] ';'
                {
                  $L->push_back($E);
                  $$ = $L;
                }
                ;
single_stm:
                expression[E] ';'
                {
                  auto StatementList = new std::vector<Value *>;
                  StatementList->push_back($E);
                  $$ = StatementList;
                }
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
        |       SYMBOL[S] STRING[P]
                {
                  auto Op = CallInst::get(*$S);
                  Op->addOperand($P);
                  $$ = Op;
                }
        |       IF expression[C] THEN compound_stm[T] compound_stm[F]
                {
                  $$ = nullptr;
                }

%%

void rhine::Parser::error(const rhine::location &l,
                          const std::string &m)
{
  Driver->error(l, m);
}
