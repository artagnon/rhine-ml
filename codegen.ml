open Llvm

exception Error of string

let context = global_context ()
let the_module = create_module context "Rhine JIT"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let i64_type = i64_type context
let i1_type = i1_type context
let double_type = double_type context
let void_type = void_type context

let int_of_bool = function true -> 1 | false -> 0

let codegen_atom = function
    Ast.Int n -> const_int i64_type n
  | Ast.Bool n -> const_int i1_type (int_of_bool n)
  | Ast.Double n -> const_float double_type n
  | Ast.Nil -> const_null i1_type

let rec codegen_sexpr = function
    Ast.Atom n -> codegen_atom n
  | Ast.DottedPair(s1, s2) -> begin match s1 with
                                      Ast.Atom n -> codegen_atom n
                                    | _ -> codegen_sexpr s1
                              end;
                              begin match s2 with
                                      Ast.Atom n -> codegen_atom n
                                    | _ -> codegen_sexpr s2
                              end
