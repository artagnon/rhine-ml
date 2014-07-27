{
  open Parser
  exception SyntaxError of string
}

rule token = parse
 | [' ' '\t' '\r' '\n'] { token lexbuf }
 | ";;" { comment lexbuf }
 | '(' { LPAREN }
 | ')' { RPAREN }
 | "nil" { NIL }
 | "true" { TRUE }
 | "false" { FALSE }
 | ['0'-'9']+ as s { INTEGER(int_of_string s) }
 | ['0'-'9']* '.' ['0'-'9']+  as s { DOUBLE(float_of_string s) }
 | ['a'-'z' 'A'-'Z' '-' '?' '+' '*' '/']+ as s { SYMBOL(s) }
 | eof { EOF }

and comment = parse
 '\n' { token lexbuf }
 | _ { comment lexbuf }
