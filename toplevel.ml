open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts
open Codegen

exception Error of string

let the_execution_engine = ExecutionEngine.create_interpreter the_module
let the_fpm = PassManager.create_function the_module

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

  (* Validate the generated code, checking for consistency. *)
  Llvm_analysis.assert_valid_function f;

  (* Optimize the function. *)
  ignore (PassManager.run_function f the_fpm);

  dump_value f;
  if Array.length (params f) == 0 then (
    let result = ExecutionEngine.run_function f [||] the_execution_engine in
    print_string "Evaluated to ";
    print_int (GenericValue.as_int result);
    print_newline ()
  )

let main_loop ss =
  (* Do simple "peephole" optimizations and bit-twiddling optzn. *)
  add_instruction_combination the_fpm;

  (* reassociate expressions. *)
  add_reassociation the_fpm;

  (* Eliminate Common SubExpressions. *)
  add_gvn the_fpm;

  (* Simplify the control flow graph (deleting unreachable blocks, etc). *)
  add_cfg_simplification the_fpm;

  ignore (PassManager.initialize the_fpm);

  List.iter (fun se -> print_and_jit se) ss;
                   dump_module the_module
