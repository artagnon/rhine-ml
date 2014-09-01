open Pretty

exception Error of string

let named_macros:(string, Ast.macro) Hashtbl.t = Hashtbl.create 10

let extract_strings args = List.map (fun i ->
                                       (match i with
                                          Ast.Atom(Ast.Symbol(s)) -> s
                                        | _ -> raise (Error "Bad argument")))
                                      args

let parse_defn_form = function
    Ast.Atom(Ast.Symbol(sym))::Ast.Vector(v)::
      Ast.Atom(Ast.String(_))::body |
    Ast.Atom(Ast.Symbol(sym))::Ast.Vector(v)::body ->
     if body == [] then
       raise (Error "Empty function definition");
     Ast.Defn(sym, extract_strings v, body)
    | se -> raise (Error ("Malformed defn form:" ^ ppsexprl se))

let parse_defmacro_form = function
    Ast.Atom(Ast.Symbol(sym))::Ast.Vector(v)::
      Ast.Atom(Ast.String(_))::body |
    Ast.Atom(Ast.Symbol(sym))::Ast.Vector(v)::body ->
     if body == [] then
       raise (Error "Empty macro definition");
     Ast.Defmacro(sym, extract_strings v, body)
    | se -> raise (Error ("Malformed defmacro form:" ^ ppsexprl se))

let parse_def_form = function
    [Ast.Atom(Ast.Symbol(sym)); expr] -> Ast.Def(sym, expr)
  | se -> raise (Error ("Malformed def form:" ^ ppsexprl se))

let cook_toplevel sexpr = match sexpr with
    Ast.List(Ast.Atom(Ast.Symbol(sym))::s2) ->
    (match sym with
       "defn" -> parse_defn_form s2
     | "def" -> parse_def_form s2
     | "defmacro" -> parse_defmacro_form s2
     | _ -> Ast.AnonCall [sexpr])
  | _ -> Ast.AnonCall [sexpr]
