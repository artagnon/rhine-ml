%{ open Ast
   let (--) i j =
     let rec aux n acc =
       if n < i then acc else aux (n-1) (n :: acc)
     in aux j []
%}

%token LPAREN RPAREN LSQBR RSQBR NIL TRUE FALSE EOF
%token <int> SQUOTE
%token <int> UNQUOTE
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
 | SQUOTE tsexpr
          {
            let towrap = $2 in
            let w1 = List.fold_left (fun a b -> SQuote a) towrap (1--$1) in
            [w1]
          }
 | UNQUOTE tsexpr
           {
             let towrap = $2 in
             let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$1) in
             [w1]
           }
 | SQUOTE UNQUOTE tsexpr
          {
            let towrap = $3 in
            let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$2) in
            let w2 = List.fold_left (fun a b -> SQuote a) w1 (1--$1) in
            [w2]
          }
 | tsexprs { $1 }
 | SQUOTE tsexprs
           {
             let towrap = List.hd $2 in
             let w1 = List.fold_left (fun a b -> SQuote a) towrap (1--$1) in
             w1::(List.tl $2)
           }
 | UNQUOTE tsexprs
           {
             let towrap = List.hd $2 in
             let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$1) in
             w1::(List.tl $2)
           }
 | SQUOTE UNQUOTE tsexprs
          {
            let towrap = List.hd $3 in
            let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$2) in
            let w2 = List.fold_left (fun a b -> SQuote a) w1 (1--$1) in
            w2::(List.tl $3)
          }
