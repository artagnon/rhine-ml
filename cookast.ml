open Pretty

exception Error of string

let named_macros:(string, Ast.macro) Hashtbl.t = Hashtbl.create 10

let extract_strings args =
  let restarg, atoms =
    if args == [] then Ast.RestNil, [] else
      match List.hd (List.rev args) with
        Ast.Atom(Ast.RestArgs s) -> Ast.RestVar s,
                                    List.rev (List.tl (List.rev args))
      | _ -> Ast.RestNil, args in
  let args = List.map (fun i ->
                        match i with
                          Ast.Atom(Ast.Symbol s) -> s
                        | _ -> raise (Error "Bad argument in defn"))
                       atoms in
  args, restarg

let parse_defn_form = function
    Ast.Atom(Ast.Symbol(sym))::Ast.Array(v)::
      Ast.Atom(Ast.String(_))::body |
    Ast.Atom(Ast.Symbol(sym))::Ast.Array(v)::body ->
     if body == [] then
       raise (Error "Empty function definition");
     let args, restarg = extract_strings v in
     Ast.Defn(sym, args, restarg, body)
    | se -> raise (Error ("Malformed defn form:" ^ ppsexprl se))

let parse_defmacro_form = function
    Ast.Atom(Ast.Symbol(sym))::Ast.Array(v)::
      Ast.Atom(Ast.String(_))::body |
    Ast.Atom(Ast.Symbol(sym))::Ast.Array(v)::body ->
     if body == [] then
       raise (Error "Empty macro definition");
     let args, restarg = extract_strings v in
     Ast.Defmacro(sym, args, restarg, body)
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
