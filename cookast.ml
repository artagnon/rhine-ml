open Pretty
open Ast

exception Error of string

let named_macros:(string, Parsetree.macro) Hashtbl.t = Hashtbl.create 10

let extract_strings args =
  let restarg, atoms =
    if args == [] then Parsetree.RestNil, [] else
      match List.hd (List.rev args) with
        Parsetree.Atom(Parsetree.RestArgs s) -> Parsetree.RestVar s,
                                    List.rev (List.tl (List.rev args))
      | _ -> Parsetree.RestNil, args in
  let args = List.map (fun i ->
                        match i with
                          Parsetree.Atom(Parsetree.Symbol s) -> s
                        | _ -> raise (Error "Bad argument in defn"))
                       atoms in
  args, restarg

let parse_defn_form = function
    Parsetree.Atom(Parsetree.Symbol(sym))::Parsetree.Array(v)::
      Parsetree.Atom(Parsetree.String(_))::body |
    Parsetree.Atom(Parsetree.Symbol(sym))::Parsetree.Array(v)::body ->
     if body == [] then
       raise (Error "Empty function definition");
     let args, restarg = extract_strings v in
     Parsetree.Defn(sym, args, restarg, body)
    | se -> raise (Error ("Malformed defn form:" ^ ppsexprl se))

let parse_defmacro_form = function
    Parsetree.Atom(Parsetree.Symbol(sym))::Parsetree.Array(v)::
      Parsetree.Atom(Parsetree.String(_))::body |
    Parsetree.Atom(Parsetree.Symbol(sym))::Parsetree.Array(v)::body ->
     if body == [] then
       raise (Error "Empty macro definition");
     let args, restarg = extract_strings v in
     Parsetree.Defmacro(sym, args, restarg, body)
    | se -> raise (Error ("Malformed defmacro form:" ^ ppsexprl se))

let parse_def_form = function
    [Parsetree.Atom(Parsetree.Symbol(sym)); expr] -> Parsetree.Def(sym, expr)
  | se -> raise (Error ("Malformed def form:" ^ ppsexprl se))

let cook_toplevel sexpr = match sexpr with
    Parsetree.List(Parsetree.Atom(Parsetree.Symbol(sym))::s2) ->
    (match sym with
       "defn" -> parse_defn_form s2
     | "def" -> parse_def_form s2
     | "defmacro" -> parse_defmacro_form s2
     | _ -> Parsetree.AnonCall [sexpr])
  | _ -> Parsetree.AnonCall [sexpr]
