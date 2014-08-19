type atom =
    Symbol of string
  | Int of int
  | Bool of bool
  | Double of float
  | String of string
  | Nil

type sexpr =
    Atom of atom
  | List of sexpr list
  | Vector of sexpr array

type prog =
    Prog of sexpr list

type proto =
    Prototype of string * string array

type func =
    Function of proto * sexpr
