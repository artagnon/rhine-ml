open Llvm
open Llvm_executionengine
open Codegen

exception Error of string

let the_execution_engine = ExecutionEngine.create the_module

let value_ptr =
  let llar = [| i64_type;
                array_type i8_type 10;
                vector_type i64_type 10 |] in
  let value_t = struct_type llar in
  declare_global value_t "value_t" the_module

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

let print_and_jit se =
  let f = sexpr_matcher se in
  dump_value f;
  let result = ExecutionEngine.run_function f [||] the_execution_engine in
  print_string "Evaluated to ";
  print_int (GenericValue.as_int result);
  print_newline ();;

let main_loop ss = List.iter (fun se -> print_and_jit se) ss;
                   dump_module the_module
