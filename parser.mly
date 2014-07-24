%{ open Ast %}

%token LPAREN RPAREN NIL TRUE FALSE EOF
%token <int> INTEGER
%token <string> SYMBOL

%start prog
%type <Ast.prog> prog

%%
prog:
  sexprs EOF { Prog(List.rev $1) }

sexpr:
| NIL { Nil }
| TRUE { Bool(true) }
| FALSE { Bool(false) }
| INTEGER { Int($1) }
| SYMBOL { Symbol($1) }
| LPAREN sexprs RPAREN { $2 }

sexprs:
  sexpr { [$1] }
| sexpr sexprs { $2::$1 }
