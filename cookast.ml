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

let macro_args:(string, Ast.sexpr) Hashtbl.t = Hashtbl.create 5

let rec macroexpand_se se quote_p =
  match se with
      Ast.SQuote(se) -> Ast.SQuote(macroexpand_se se true)
    | Ast.Unquote(se) ->
       if quote_p then macroexpand_se se false else
         raise (Error ("Extra unquote: " ^ Pretty.ppsexpr se))
    | Ast.Atom(Ast.Symbol(s)) as a ->
       if quote_p then a else
         (try Hashtbl.find macro_args s with Not_found -> a)
    | Ast.List(sl) -> Ast.List(List.map (fun se ->
                                         macroexpand_se se quote_p) sl)
    | Ast.Vector(sl) -> Ast.Vector(List.map (fun se ->
                                             macroexpand_se se quote_p) sl)
    | token -> token

let macroexpand m s2 =
  let arg_names, sl = match m with Ast.Macro(args, sl) -> args, sl in
  Array.iteri (fun i n -> Hashtbl.add macro_args n (List.nth s2 i)) arg_names;
  let l = List.map (fun se -> macroexpand_se se false) sl in
  List.nth l 0

let rec lift_macros body =
  let lift_macros_se = function
      Ast.List(Ast.Atom(Ast.Symbol s)::s2) ->
      (try
          let m = Hashtbl.find named_macros s
          in macroexpand m s2
        with
          Not_found -> Ast.List(Ast.Atom(Ast.Symbol s)::lift_macros s2))
    | se -> se in
  let splice_toplevel se = match se with
      Ast.SQuote se -> se
    | _ -> se in
  List.map (fun i -> splice_toplevel (lift_macros_se i)) body
