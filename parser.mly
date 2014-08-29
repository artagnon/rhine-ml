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

tsexpr:
   sexpr { $1 }
 | vsexpr { $1 }

tsexprs:
   tsexpr sexprs { $1::$2 }

sexprs:
   tsexpr { [$1] }
 | SQUOTE tsexpr { [SQuote($2)] }
 | UNQUOTE tsexpr { [Unquote($2)] }
 | SQUOTE UNQUOTE tsexpr { [SQuote(Unquote($3))] }
 | tsexprs { $1 }
 | SQUOTE tsexprs { SQuote(List.hd $2)::(List.tl $2) }
 | UNQUOTE tsexprs { Unquote(List.hd $2)::(List.tl $2) }
 | SQUOTE UNQUOTE tsexprs { SQuote(Unquote(List.hd $3))::(List.tl $3) }
