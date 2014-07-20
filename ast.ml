type atom =
    Symbol of string
  | Int of int
  | Double of float
  | Str of string
  | Nil

type sexp =
    Atom of atom
  | DottedPair of sexp * sexp

type prog =
    Prog of sexpr list
