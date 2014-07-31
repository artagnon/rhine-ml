open Llvm

module StringSet = Set.Make(String)

exception Error of string

let context = global_context ()
let the_module = create_module context "Rhine JIT"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
let i8_type = i8_type context
let i32_type = i32_type context
let i64_type = i64_type context
let i1_type = i1_type context
let double_type = double_type context
let void_type = void_type context
let struct_type = struct_type context

let int_of_bool = function true -> 1 | false -> 0

let (--) i j =
    let rec aux n acc =
      if n < i then acc else aux (n-1) (n :: acc)
    in aux j []

let arith_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "+"; "-"; "*"; "/" ]

let vector_ops = List.fold_left (fun s k -> StringSet.add k s)
                                StringSet.empty
                                [ "head"; "rest" ]

let string_ops = List.fold_left (fun s k -> StringSet.add k s)
                                StringSet.empty
                                [ "str-split"; "str-join" ]

let box_value llval =
  let llar = [| i64_type;
                array_type i8_type 10;
                vector_type i64_type 10 |] in
  let value_t = struct_type llar in
  let value_ptr = build_alloca value_t "value" builder in
  let idx0 = [| const_int i32_type 0; const_int i32_type 0 |] in
  let dst = match type_of llval with
      i64_type -> build_in_bounds_gep value_ptr idx0 "boxptr" builder
    | _ -> raise (Error "Don't know how to box type") in
  ignore (build_store llval dst builder); value_ptr

let unbox_int llval =
  let idx0 = [| const_int i32_type 0; const_int i32_type 0 |] in
  let dst = build_in_bounds_gep llval idx0 "boxptr" builder in
  build_load dst "load" builder

let undef_vec len =
  let undef_list = List.map (fun i -> undef i64_type) (0--(len - 1)) in
  const_vector (Array.of_list undef_list)

let mask_vec len =
  let mask_list = List.map (fun i -> const_int i32_type i) (1--(len - 1)) in
  const_vector (Array.of_list mask_list)

let codegen_atom = function
    Ast.Int n -> box_value (const_int i64_type n)
  | Ast.Bool n -> const_int i1_type (int_of_bool n)
  | Ast.Double n -> const_float double_type n
  | Ast.Nil -> const_null i1_type
  | Ast.String s -> const_string context s
  | Ast.Symbol n -> (try Hashtbl.find named_values n with
                       Not_found -> raise (Error "Symbol not bound"))

let rec extract_args s = match s with
    Ast.DottedPair(s1, s2) ->
    begin match (s1, s2) with
            (Ast.Atom m, Ast.DottedPair(_, _)) ->
            (codegen_atom m)::(extract_args s2)
          | (Ast.Atom m, Ast.Atom(Ast.Nil)) -> [codegen_atom m]
          | (Ast.DottedPair(_, _), Ast.DottedPair(_, _)) ->
             (codegen_sexpr s1)::(extract_args s2)
          | (Ast.DottedPair(_, _), Ast.Atom(Ast.Nil)) -> [codegen_sexpr s1]
          | (Ast.Vector(qs), Ast.DottedPair(_, _)) ->
             (codegen_vector qs)::(extract_args s2)
          | (Ast.Vector(qs), Ast.Atom(Ast.Nil)) -> [codegen_vector qs]
          | _ -> raise (Error "Malformed sexp")
    end
  | _ -> raise (Error "Expected sexp")

and codegen_arith_op op args =
  let hd = unbox_int (List.hd args) in
  let tl = List.tl args in
  if tl == [] then box_value hd else
    let unboxed_value = match op with
        "+" -> build_add hd (unbox_int (codegen_arith_op op tl))
                         "add" builder
      | "-" -> build_sub hd (unbox_int (codegen_arith_op op tl)) "sub" builder
      | "*" -> build_mul hd (unbox_int (codegen_arith_op op tl)) "mul" builder
      | "/" -> build_fdiv hd (codegen_arith_op op tl) "div" builder
      | _ -> raise (Error "Unknown arithmetic operator")
    in box_value unboxed_value

and codegen_vector_op op args =
  let vec = List.hd args in
  let len = vector_size (type_of vec) in
  let idx0 = const_int i32_type 0 in
  match op with
    "head" -> build_extractelement vec idx0 "extract" builder
  | "rest" -> build_shufflevector vec (undef_vec len)
                                  (mask_vec len) "shuffle" builder
  | _ -> raise (Error "Unknown vector operator")

and codegen_string_op op s2 =
  match op with
    "str-split" -> let str = List.hd s2 in
                   let len = array_length (type_of str) in
                   let l = List.map
                             (fun i -> build_extractvalue
                                         str i "extract" builder)
                             (0--(len - 1))
                   in const_vector (Array.of_list l)
  | "str-join" -> let vec = List.hd s2 in
                  let len = vector_size (type_of vec) in
                  let idx i = const_int i32_type i in
                  let l = List.map
                            (fun i -> build_extractelement
                                        vec (idx i) "extract" builder)
                            (0--(len - 1)) in
                  const_array i8_type (Array.of_list l)
  | _ -> raise (Error "Unknown string operator")

and codegen_sexpr s = match s with
    Ast.Atom n -> codegen_atom n
  | Ast.DottedPair(s1, s2) ->
     begin match s1 with
             Ast.Atom(Ast.Symbol s) ->
             let args = extract_args s2 in
             if StringSet.mem s arith_ops then
               codegen_arith_op s args
             else if StringSet.mem s vector_ops then
               codegen_vector_op s args
             else if StringSet.mem s string_ops then
               codegen_string_op s args
             else
               raise (Error "Unknown operation")
           | _ -> raise (Error "Expected function call")
     end
  | Ast.Vector(qs) -> codegen_vector qs

and codegen_vector qs = const_vector (Array.map (fun se -> codegen_sexpr se) qs)

let codegen_proto = function
  | Ast.Prototype (name, args) ->
      let ints = Array.make (Array.length args) i64_type in
      let ft = function_type i64_type ints in
      let f =
        match lookup_function name the_module with
        | None -> declare_function name ft the_module

        (* If 'f' conflicted, there was already something named 'name'. If it
         * has a body, don't allow redefinition or reextern. *)
        | Some f ->
            (* If 'f' already has a body, reject this. *)
            if block_begin f <> At_end f then
              raise (Error "redefinition of function");

            (* If 'f' took a different number of arguments, reject. *)
            if element_type (type_of f) <> ft then
              raise (Error "redefinition of function with different # args");
            f
      in

      (* Set names for all arguments. *)
      Array.iteri (fun i a ->
        let n = args.(i) in
        set_value_name n a;
        Hashtbl.add named_values n a;
      ) (params f);
      f

let codegen_func = function
  | Ast.Function (proto, body) ->
      Hashtbl.clear named_values;
      let the_function = codegen_proto proto in

      (* Create a new basic block to start insertion into. *)
      let bb = append_block context "entry" the_function in
      position_at_end bb builder;

      try
        let ret_val = unbox_int (codegen_sexpr body) in

        (* Finish off the function. *)
        let _ = build_ret ret_val builder in

        the_function
      with e ->
        delete_function the_function;
        raise e
