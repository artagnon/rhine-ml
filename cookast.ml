open Pretty

let extract_strings args = List.map (fun i ->
                                       (match i with
                                          Ast.Atom(Ast.Symbol(s)) -> s
                                        | _ -> raise (Error "Bad argument")))
                                      args

let parse_defn_form = function
    Ast.Atom(Ast.Symbol(sym))::Ast.Vector(v)::body ->
    Ast.Defn(sym, extract_strings v, body)
  | Ast.Atom(Ast.Symbol(sym))::body ->
     Ast.Defn(sym, [], body)
  | se -> raise (Error "Malformed defn form")

let parse_def_form = function
    [Ast.Atom(Ast.Symbol(sym)); expr] -> Ast.Def(sym, expr)
  | se -> raise (Error "Malformed def form")

let cook_toplevel sexpr = match sexpr with
    Ast.List(Ast.Atom(Ast.Symbol(sym))::s2) ->
    (match sym with
       "defn" -> parse_defn_form s2
     | "def" -> parse_def_form s2
     | _ -> Ast.AnonCall [sexpr])
  | _ -> Ast.AnonCall [sexpr]
