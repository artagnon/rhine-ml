%{ open Ast %}

%token SQUOTE UNQUOTE LPAREN RPAREN LSQBR RSQBR NIL TRUE FALSE EOF
%token <int> INTEGER
%token <float> DOUBLE
%token <string> SYMBOL
%token <char> CHAR
%token <string> STRING

%start prog
%type <Ast.prog> prog
%type <Ast.atom> atom
%type <Ast.sexpr> sexpr

%%

prog:
   sexprs EOF { Prog($1) }

atom:
   NIL { Nil }
 | TRUE { Bool(true) }
 | FALSE { Bool(false) }
 | INTEGER { Int($1) }
 | DOUBLE { Double($1) }
 | CHAR { Char($1) }
 | STRING { String($1) }
 | SYMBOL { Symbol($1) }

sexpr:
   atom { Atom($1) }
 | LPAREN sexprs RPAREN { List($2) }

vsexpr:
   LSQBR sexprs RSQBR { Vector($2) }
 | LSQBR RSQBR { Vector([]) }

sexprs:
   sexpr sexprs { $1::$2 }
 | SQUOTE sexpr sexprs { SQuote($2)::$3 }
 | UNQUOTE sexpr sexprs { Unquote($2)::$3 }
 | vsexpr sexprs { $1::$2 }
 | SQUOTE vsexpr sexprs { SQuote($2)::$3 }
 | UNQUOTE vsexpr sexprs { Unquote($2)::$3 }
 | sexpr { [$1] }
 | SQUOTE sexpr { [SQuote($2)] }
 | UNQUOTE sexpr { [Unquote($2)] }
 | vsexpr { [$1] }
 | SQUOTE vsexpr { [SQuote($2)] }
 | UNQUOTE vsexpr { [Unquote($2)] }
