open Llvm

exception Error of string

let context = global_context ()
let the_module = create_module context "Rhine JIT"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let i64_type = i64_type context

let rec codegen_expr = function
  | Ast.Int n -> const_int i64_type n
  | Ast.BinaryOp (op, lhs, rhs) ->
     let lhs_val = codegen_expr lhs in
     let rhs_val = codegen_expr rhs in
     begin
       match op with
       | '+' -> build_add lhs_val rhs_val "addtmp" builder
       | '-' -> build_sub lhs_val rhs_val "subtmp" builder
       | '*' -> build_mul lhs_val rhs_val "multmp" builder
       | '<' -> build_cmp Fcmp.Ult lhs_val rhs_val "cmptmp" builder
       | _ -> raise (Error "invalid binary operator")
     end
