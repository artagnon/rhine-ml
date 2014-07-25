%{ open Ast %}

%token LPAREN RPAREN NIL TRUE FALSE EOF PLUS MINUS DIVIDE TIMES
%token <int> INTEGER
%token <string> SYMBOL

%start prog
%type <Ast.prog> prog

%%
prog:
    sexprs EOF { Prog(List.rev $1) }

atom:
   NIL { Nil }
 | TRUE { Bool(true) }
 | FALSE { Bool(false) }
 | INTEGER { Int($1) }
 | SYMBOL { Symbol($1) }

sexpr:
   atom { Atom($1) }
 | PLUS sexprs { }
 | LPAREN sexprs RPAREN {
       let rec buildDP = function
            [] -> Atom(Nil)
          | h::t -> DottedPair(h, buildDP t)
       in buildDP($2)
   }

sexprs:
  sexpr sexprs { $1::$2 }
| sexpr { [$1] }

