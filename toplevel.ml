open Codegen
open Llvm

exception Error of string

let emit_anonymous_f s =
  codegen_func(Ast.Function(Ast.Prototype("", [||]), s))

let extract_strings args = Array.map (fun i ->
                                       (match i with
                                          Ast.Atom(Ast.Symbol(s)) -> s
                                        | _ -> raise (Error "Bad argument")))
                                      args

let parse_defn_form sexpr = match sexpr with
    Ast.DottedPair(Ast.Atom(Ast.Symbol(sym)),
                   Ast.DottedPair(Ast.Vector(v),
                                  Ast.DottedPair(body,
                                                 Ast.Atom(Ast.Nil)))) ->
    (sym, extract_strings v, body)
  | _ -> raise (Error "Unparseable defn form")

let sexpr_matcher sexpr = match sexpr with
    Ast.DottedPair(Ast.Atom(Ast.Symbol("defn")), s2) ->
    let (sym, args, body) = parse_defn_form s2 in
    codegen_func(Ast.Function(Ast.Prototype(sym, args), body))
  | _ -> emit_anonymous_f sexpr

let main_loop ss = List.iter (fun i -> dump_value (sexpr_matcher i)) ss
