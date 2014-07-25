{
  open Parser
  exception SyntaxError of string
}

rule token = parse
 | [' ' '\t' '\r' '\n'] { token lexbuf }
 | ";;" { comment lexbuf }
 | '(' { LPAREN }
 | ')' { RPAREN }
 | '+' { PLUS }
 | '-' { MINUS }
 | '/' { DIVIDE }
 | '*' { TIMES }
 | "nil" { NIL }
 | "true" { TRUE }
 | "false" { FALSE }
 | ['0'-'9']+ as s { INTEGER(int_of_string s) }
 | ['a'-'z' 'A'-'Z' '-' '?']+ as s { SYMBOL(s) }
 | eof { EOF }

and comment = parse
 '\n' { token lexbuf }
 | _ { comment lexbuf }
