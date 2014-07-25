type token =
  | LPAREN
  | RPAREN
  | NIL
  | TRUE
  | FALSE
  | EOF
  | PLUS
  | MINUS
  | DIVIDE
  | TIMES
  | INTEGER of (int)
  | SYMBOL of (string)

val prog :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.prog
