// -*- Bison -*-
%{
#include "rhine/Lexer.h"
%}

%output  "Parser/Parser.cpp"
%defines "include/rhine/Parser.h"

%skeleton "lalr1.cc"
%locations
%token-table
%lex-param   { void *scanner }
%parse-param { void *scanner }
%parse-param { double **expression }

%union {
    int value;
    double *expression;
}

%left '+' TOKEN_PLUS
%left '*' TOKEN_MULTIPLY

%token TOKEN_LPAREN
%token TOKEN_RPAREN
%token TOKEN_PLUS
%token TOKEN_MULTIPLY
%token <value> TOKEN_NUMBER

%type <expression> expr

%%

input
    : expr { *expression = $1; }
    ;

expr
    : expr[L] TOKEN_PLUS expr[R] { $$ = createOperation( ePLUS, $L, $R ); }
    | expr[L] TOKEN_MULTIPLY expr[R] { $$ = createOperation( eMULTIPLY, $L, $R ); }
    | TOKEN_LPAREN expr[E] TOKEN_RPAREN { $$ = $E; }
    | TOKEN_NUMBER { $$ = createNumber($1); }
    ;

%%
