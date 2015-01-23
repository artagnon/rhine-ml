type primitivety =
  | Symbol of string
  | Int of int
  | Bool of bool
  | Double of float
  | Char of char
  | String of string
  | RestArgs of string
  | Array of primitivety list
  | Nil

type funty =
  {
    arity : int;
    returnty : primitivety;
  }
