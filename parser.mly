%{
  open Parsetree
  open Ast_helper

  let (--) i j =
    let rec aux n acc =
      if n < i then acc else aux (n-1) (n :: acc)
    in aux j []

  let symbol_rloc start_pos end_pos = {
    Location.loc_start = start_pos;
    Location.loc_end = end_pos;
    Location.loc_ghost = false;
  }

  let mklsexpr d sp ep = Lsexpr.mk ~loc:(symbol_rloc sp ep) d
  let unlsexpr d = List.map (fun i -> i.lsexpr_desc) d
%}

%token LPAREN RPAREN LSQBR RSQBR NIL TRUE FALSE REST_ARGS EOF
%token <int> SQUOTE
%token <int> UNQUOTE
%token <int> INTEGER
%token <float> DOUBLE
%token <string> SYMBOL
%token <char> CHAR
%token <string> STRING

%start prog
%type <Parsetree.prog> prog
%type <Parsetree.atom> atom
%type <Parsetree.sexpr> sexpr
%type <Parsetree.sexpr> vsexpr
%type <Parsetree.sexpr> tsexpr
%type <Parsetree.sexpr list> tsexprs
%type <Parsetree.lsexpr list> sexprs

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
   atom { Atom $1 }
 | REST_ARGS SYMBOL { Atom (RestArgs $2) }
 | LPAREN sexprs RPAREN { List (unlsexpr $2) }

vsexpr:
   LSQBR sexprs RSQBR { Array (unlsexpr $2) }
 | LSQBR RSQBR { Array [] }

tsexpr:
   sexpr { $1 }
 | vsexpr { $1 }

tsexprs:
   tsexpr sexprs { $1::(unlsexpr $2) }

sexprs:
   tsexpr { [mklsexpr $1 $startpos $endpos] }
 | SQUOTE tsexpr
          {
            let towrap = $2 in
            let w1 = List.fold_left (fun a b -> SQuote a) towrap (1--$1) in
            [mklsexpr w1 $startpos $endpos]
          }
 | UNQUOTE tsexpr
           {
             let towrap = $2 in
             let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$1) in
             [mklsexpr w1 $startpos $endpos]
           }
 | SQUOTE UNQUOTE tsexpr
          {
            let towrap = $3 in
            let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$2) in
            let w2 = List.fold_left (fun a b -> SQuote a) w1 (1--$1) in
            [mklsexpr w2 $startpos $endpos]
          }
 | tsexprs { List.map (fun i -> mklsexpr i $startpos $endpos) $1 }
 | SQUOTE tsexprs
           {
             let towrap = List.hd $2 in
             let w1 = List.fold_left (fun a b -> SQuote a) towrap (1--$1) in
             (mklsexpr w1 $startpos $endpos)::
               (List.map (fun i -> mklsexpr i $startpos $endpos) (List.tl $2))
           }
 | UNQUOTE tsexprs
           {
             let towrap = List.hd $2 in
             let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$1) in
             (mklsexpr w1 $startpos $endpos)::
               (List.map (fun i -> mklsexpr i $startpos $endpos) (List.tl $2))
           }
 | SQUOTE UNQUOTE tsexprs
          {
            let towrap = List.hd $3 in
            let w1 = List.fold_left (fun a b -> Unquote a) towrap (1--$2) in
            let w2 = List.fold_left (fun a b -> SQuote a) w1 (1--$1) in
            (mklsexpr w2 $startpos $endpos)::
              (List.map (fun i -> mklsexpr i $startpos $endpos) (List.tl $3))
          }
