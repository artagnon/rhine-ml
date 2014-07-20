%{ open Ast %}

%token LPAREN RPAREN NIL TRUE FALSE EOF
%token <int> INTEGER

%start prog
%type <Ast.prog> prog

%%
prog:
  sexpr EOF { Prog(List.rev $1) }

sexp:
  atom { Atom($1) }
| LPAREN RPAREN { Atom(Nil) }
| LPAREN sexprs RPAREN { $2 }

sexprs:
  sexprs sexpr { $2::$1 }
| sexpr { [$1] }
