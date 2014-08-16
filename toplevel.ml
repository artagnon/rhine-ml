open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts
open Codegen

exception Error of string

let _ = initialize_native_target ()
let the_execution_engine = ExecutionEngine.create_jit the_module 1
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
                   Ast.DottedPair(Ast.Vector(v), body)) ->
    (sym, extract_strings v, body)
  | _ -> raise (Error "Unparseable defn form")

let parse_def_form sexpr = match sexpr with
    Ast.DottedPair(Ast.Atom(Ast.Symbol(sym)),
                   Ast.DottedPair(expr, Ast.Atom(Ast.Nil))) -> (sym, expr)
  | _ -> raise (Error "Unparseable def form")

let sexpr_matcher sexpr =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  match sexpr with
    Ast.DottedPair(Ast.Atom(Ast.Symbol("defn")), s2) ->
    let (sym, args, body) = parse_defn_form s2 in
    codegen_func(Ast.Function(Ast.Prototype(sym, args), body))
  | Ast.DottedPair(Ast.Atom(Ast.Symbol("def")), s2) ->
     (* Emit initializer function *)
     let the_function = codegen_proto (Ast.Prototype("", [||])) in 
     let bb = append_block context "entry" the_function in
     position_at_end bb builder;
     let (sym, expr) = parse_def_form s2 in
     let llexpr = codegen_sexpr expr in
     let llexpr = build_load llexpr "llexpr" builder in
     let global = define_global sym (const_null value_t) the_module in
     ignore (build_store llexpr global builder);
     ignore (build_ret (const_int i64_type 0) builder);
     the_function
  | _ -> emit_anonymous_f sexpr

let print_and_jit se =
  let f = sexpr_matcher se in

  (* Validate the generated code, checking for consistency. *)
  (* Llvm_analysis.assert_valid_function f;*)

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

  (* Declare global variables/ types *)
  let llvalue_t = named_struct_type context "value_t" in
  let value_t_elts = [| i32_type;                 (* value type of struct, integer: 1, bool: 2, string: 3, array: 4, double: 6, function: 7 *)
                        i64_type;                 (* integer *)
                        i1_type;                  (* bool *)
                        (pointer_type i8_type);   (* string *)
                        (pointer_type (pointer_type llvalue_t));  (* array *)
                        i64_type; (* array length *)
                        double_type; (* double *)
                        pointer_type (function_type
                                        (pointer_type llvalue_t)
                                        [| (pointer_type llvalue_t) |]);
                       |] in
  struct_set_body llvalue_t value_t_elts false;

  (* Declare external functions *)
  let ft = function_type (pointer_type i8_type) [| i64_type |] in
  ignore (declare_function "malloc" ft the_module);
  let ft = function_type i64_type [| pointer_type i8_type |] in
  ignore (declare_function "strlen" ft the_module);
  let ft = function_type i32_type
                         [| pointer_type i8_type; pointer_type i8_type;
                            i64_type; i32_type; i1_type |] in
  ignore (declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module);
  ignore (codegen_proto (Ast.Prototype("println", Array.make 1 "v")));
  ignore (codegen_proto (Ast.Prototype("print", Array.make 1 "v")));
  ignore (codegen_proto (Ast.Prototype("cadd", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cdiv", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("csub", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cmul", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cmod", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cexponent", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("clt", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cgt", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("clte", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cgte", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cequ", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cand", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cor", Array.make 2 "v")));
  ignore (codegen_proto (Ast.Prototype("cnot", Array.make 1 "v")));
  ignore (codegen_proto (Ast.Prototype("cstrjoin", Array.make 1 "v")));

  List.iter (fun se -> print_and_jit se) ss
