open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts
open Codegen
open Cookast

exception Error of string

let _ = initialize_native_target ()
let the_execution_engine = ExecutionEngine.create_jit the_module 1
let the_fpm = PassManager.create_function the_module

let emit_anonymous_f s =
  codegen_func ~main_p:true (Ast.Function(Ast.Prototype("", [||]), s))

let extract_strings args = Array.map (fun i ->
                                       (match i with
                                          Ast.Atom(Ast.Symbol(s)) -> s
                                        | _ -> raise (Error "Bad argument")))
                                      args

let sexpr_matcher sexpr =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  match sexpr with
    Ast.Defn(sym, args, body) ->
    let f = codegen_func(Ast.Function(Ast.Prototype(sym, Array.of_list args),
                                      body)) in
    Ast.ParsedFunction(f, false)
  | Ast.Defmacro(sym, args, body) ->
     Hashtbl.add named_macros sym (Ast.Macro(Array.of_list args, body));
     Ast.ParsedMacro
  | Ast.Def(sym, expr) ->
     (* Emit initializer function *)
     let the_function = codegen_proto (Ast.Prototype("", [||])) ~main_p:true in
     let bb = append_block context "entry" the_function in
     position_at_end bb builder;
     let llexpr = codegen_sexpr expr in
     let llexpr = build_load llexpr "llexpr" builder in
     let global = define_global sym (const_null value_t) the_module in
     ignore (build_store llexpr global builder);
     ignore (build_ret (const_int i64_type 0) builder);
     Ast.ParsedFunction(the_function, true)
  | Ast.AnonCall(body) -> Ast.ParsedFunction(emit_anonymous_f body, true)
  | _ -> raise (Error "Invalid toplevel form")

let print_and_jit se =
  match sexpr_matcher se with
    Ast.ParsedFunction(f, main_p) ->
    (* Validate the generated code, checking for consistency. *)
    (* Llvm_analysis.assert_valid_function f;*)

    (* Optimize the function. *)
    ignore (PassManager.run_function f the_fpm);

    dump_value f;

    if main_p then (
      let result = ExecutionEngine.run_function f [||] the_execution_engine in
      print_string "Evaluated to ";
      print_int (GenericValue.as_int result);
      print_newline ()
    )
    | Ast.ParsedMacro -> ()

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
  let value_t = named_struct_type context "value_t" in
  let pvalue_t = pointer_type value_t in
  (* 1 int, 2 bool, 3 str, 4 ar, 5 len, 6 dbl, 7 fun, 8 char, 9 env *)
  let value_t_elts = [| i32_type;                 (* value type of struct *)
                        i64_type;                 (* integer *)
                        i1_type;                  (* bool *)
                        (pointer_type i8_type);   (* string *)
                        (pointer_type pvalue_t);  (* array *)
                        i64_type; (* array length *)
                        double_type;
                        pointer_type (var_arg_function_type
                                        pvalue_t
                                        [| i32_type; pointer_type pvalue_t |]);
                        i8_type;
                        pointer_type pvalue_t;
                       |] in
  struct_set_body value_t value_t_elts false;

  let valist_t = named_struct_type context "__va_list_tag" in
  let valist_t_elts = [| i32_type;
                         i32_type;
                         (pointer_type i8_type);
                         (pointer_type i8_type) |] in
  struct_set_body valist_t valist_t_elts false;

  (* Declare external functions *)
  let ft = function_type (pointer_type i8_type) [| i64_type |] in
  ignore (declare_function "malloc" ft the_module);
  let ft = function_type i64_type [| pointer_type i8_type |] in
  ignore (declare_function "strlen" ft the_module);
  let ft = function_type void_type
                         [| pointer_type i8_type; pointer_type i8_type;
                            i64_type; i32_type; i1_type |] in
  ignore (declare_function "llvm.memcpy.p0i8.p0i8.i64" ft the_module);
  let ft = function_type double_type [| double_type; double_type |] in
  ignore (declare_function "llvm.pow.f64" ft the_module);
  let ft = function_type void_type [| pointer_type i8_type |] in
  ignore (declare_function "llvm.va_start" ft the_module);
  let ft = function_type void_type [| pointer_type i8_type |] in
  ignore (declare_function "llvm.va_end" ft the_module);
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

  List.iter (fun se -> print_and_jit (cook_toplevel se)) ss
