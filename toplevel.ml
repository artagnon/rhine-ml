open Llvm
open Llvm_executionengine
open Llvm_target
open Llvm_scalar_opts
open Parsetree
open Codegen
open Cookast
open Ctypes
open Mlunbox

exception Error of string

let _ = initialize ()
let the_execution_engine = create the_module
let the_fpm = PassManager.create_function the_module

let anon_gen =
   let count = ref (-1) in
   fun () ->
     incr count;
     "anon" ^ string_of_int !count

let emit_anonymous_f s =
  codegen_func (Function(Prototype(anon_gen (), [||], RestNil), s))
               ~main_p:true

let run_f f =
  let mainty = Foreign.funptr (void @-> returning (ptr_opt cvalue_t)) in
  let mainf = get_function_address (value_name f) mainty the_execution_engine in
  let cptr = mainf () in
  match cptr with
    None -> LangNil
  | Some p -> unbox_value !@p

let macro_args:(string, sexpr) Hashtbl.t = Hashtbl.create 5

let rec macroexpand_se ?(unquote_p = false) se quote_nr =
  let run_se_splice se =
    let f = emit_anonymous_f [se] in
    dump_value f;
    let lv = run_f f in
    lang_val_to_ast lv in
  match se with
      SQuote(se) -> macroexpand_se se (quote_nr + 1)
    | Unquote(se) ->
       if quote_nr > 0 then
         macroexpand_se se ~unquote_p:true (quote_nr - 1)
       else
         raise (Error ("Extra unquote: " ^ Pretty.ppsexpr se))
    | Atom(Symbol(s)) as a ->
       if unquote_p then
         (try Hashtbl.find macro_args s with Not_found -> a)
       else a
    | List(sl) ->
       let leval = List(List.map (fun se ->
                                      macroexpand_se se quote_nr) sl) in
       if unquote_p then run_se_splice leval
       else leval
    | Array(sl) -> Array(List.map (fun se ->
                                             macroexpand_se se quote_nr) sl)
    | se -> if unquote_p then run_se_splice se
            else se

let macroexpand m s2 =
  let arg_names, sl = match m with Macro(args, sl) -> args, sl in
  Array.iteri (fun i n -> Hashtbl.add macro_args n (List.nth s2 i)) arg_names;
  let l = List.map (fun se -> macroexpand_se se 0) sl in
  List.nth l 0

let rec lift_macros body =
  let lift_macros_se = function
      List(Atom(Symbol s)::s2) ->
      (try
          let m = Hashtbl.find named_macros s
          in macroexpand m s2
        with
          Not_found -> List(Atom(Symbol s)::lift_macros s2))
    | se -> se in
  List.map lift_macros_se body

let tlform_matcher sexpr =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  match sexpr with
    Defn(sym, args, restarg, body) ->
    let lbody = lift_macros body in
    let proto = Prototype(sym, Array.of_list args, restarg) in
    let main_p = if sym = "main" then true else false in
    let f = codegen_func(Function(proto, lbody)) ~main_p:main_p in
    ParsedFunction(f, main_p)
  | Defmacro(sym, args, restarg, body) ->
     Hashtbl.add named_macros sym (Macro(Array.of_list args, body));
     ParsedMacro
  | Def(sym, expr) ->
     (* Emit initializer function *)
     let the_function = codegen_proto (Prototype(anon_gen (), [||], RestNil))
                                      ~main_p:true in
     let bb = append_block context "entry" the_function in
     position_at_end bb builder;
     let llexpr = codegen_sexpr expr in
     let llexpr = build_load llexpr "llexpr" builder in
     let global = define_global sym (const_null value_t) the_module in
     ignore (build_store llexpr global builder);
     ignore (build_ret (const_null (pointer_type value_t)) builder);
     ParsedFunction(the_function, true)
  | AnonCall(body) -> let lbody = lift_macros body in
                          ParsedFunction(emit_anonymous_f lbody, true)
  | _ -> raise (Error "Invalid toplevel form")

let validate_and_optimize_f f =
  (* Validate the generated code, checking for consistency. *)
  Llvm_analysis.assert_valid_function f;
  (* Optimize the function. *)
  ignore (PassManager.run_function f the_fpm);
  (* Set the gc *)
  set_gc (Some "rgc") f

let main_loop sl =
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
  (* 1 int, 2 bool, 3 str, 4 ar/env, 5 len, 6 dbl, 7 fun, 8 char *)
  let value_t_elts = [| i32_type;                 (* value type of struct *)
                        i64_type;                 (* integer *)
                        i1_type;                  (* bool *)
			(* string: addrspace(0) because build_global_strptr *)
                        pointer0_type i8_type;
                        pointer_type pvalue_t;    (* array *)
                        i64_type;                 (* array length *)
                        double_type;
                        pointer0_type (var_arg_function_type
                                         pvalue_t
                                         [| i32_type; pointer_type pvalue_t |]);
                        i8_type;
                        i1_type;                  (* gc_marked *)
                        pointer_type value_t;     (* gc_next *)
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
  ignore (declare_function "gc_malloc" ft the_module);
  let ft = function_type i64_type [| pointer0_type i8_type |] in
  ignore (declare_function "strlen" ft the_module);
  let ft = function_type void_type
                         [| pointer_type i8_type; pointer_type i8_type;
                            i64_type; i32_type; i1_type |] in
  ignore (declare_function "llvm.memcpy.p1i8.p1i8.i64" ft the_module);
  let ft = function_type double_type [| double_type; double_type |] in
  ignore (declare_function "llvm.pow.f64" ft the_module);
  let ft = function_type void_type [| pointer0_type i8_type |] in
  ignore (declare_function "llvm.va_start" ft the_module);
  let ft = function_type void_type [| pointer0_type i8_type |] in
  ignore (declare_function "llvm.va_end" ft the_module);
  let ft = var_arg_function_type i32_type [| pointer0_type
					       (var_arg_function_type
						  pvalue_t
						  [| i32_type;
						     pointer_type pvalue_t |]);
					     i32_type; i32_type |] in
  (* What a monster name! *)
  ignore (declare_function
	    "llvm.experimental.gc.statepoint.p0f_p1value_ti32p1p1value_tvarargf"
	    ft the_module);
  let ft = function_type pvalue_t [| i32_type |] in
  ignore (declare_function "llvm.experimental.gc.result.ptr.p1value_t"
			   ft the_module);
  let ar n = Array.make n "v" in
  ignore (codegen_proto (Prototype("println", ar 1, RestNil)));
  ignore (codegen_proto (Prototype("print", ar 1, RestNil)));
  ignore (codegen_proto (Prototype("cequ", ar 2, RestNil)));
  ignore (codegen_proto (Prototype("cstrjoin", ar 1, RestNil)));

  let fnms = List.map (fun se -> tlform_matcher (cook_toplevel se.lsexpr_desc)) sl in
  let fns = List.filter (fun fnm -> match fnm with
				      ParsedFunction(f, main_p) -> true
				    | _ -> false) fnms in
  List.iter (fun fn -> match fn with
			 ParsedFunction(f, _) -> validate_and_optimize_f f
		       | _ -> ()) fns;
  dump_module the_module;
  List.iter (fun fn -> match fn with
			 ParsedFunction(f, true) ->
			 print_string "Evaluated to ";
			 print_value (run_f f);
			 print_newline ()
		       | _ -> ()) fns
