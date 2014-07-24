type atom =
    Symbol of string
  | Int of int
  | Bool of bool
  | Double of float
  | Nil

type sexpr =
    Atom of atom
  | DottedPair of sexpr * sexpr

type prog =
    Prog of sexpr list
