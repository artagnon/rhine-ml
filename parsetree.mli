type atom =
  | Symbol of string
  | Int of int
  | Bool of bool
  | Double of float
  | Char of char
  | String of string
  | RestArgs of string
  | Nil

type restplaceholder =
  | RestVar of string
  | RestNil

type sexpr =
  | Atom of atom
  | SQuote of sexpr
  | Unquote of sexpr
  | List of sexpr list
  | Array of sexpr list
  | Defn of string * string list * restplaceholder * sexpr list
  | Defmacro of string * string list * restplaceholder * sexpr list
  | Def of string * sexpr
  | Call of string * sexpr list
  | AnonCall of sexpr list

type lsexpr = {
  lsexpr_desc: sexpr;
  lsexpr_loc: Location.t;
}

type prog =
    Prog of lsexpr list

type proto =
    Prototype of string * string array * restplaceholder

type func =
    Function of proto * sexpr list

type macro =
    Macro of string array * sexpr list

type parsedtlform =
    ParsedFunction of Llvm.llvalue * bool
  | ParsedMacro
