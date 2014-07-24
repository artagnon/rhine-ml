type atom =
    Symbol of string
  | Int of int
  | Bool of bool
  | Double of float
  | Nil

type sexpr =
  | DottedPair of sexpr * sexpr

type prog =
    Prog of sexpr list
