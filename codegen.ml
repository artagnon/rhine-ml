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

let cf_ops = List.fold_left (fun s k -> StringSet.add k s)
                            StringSet.empty
                            [ "if"; "dotimes" ]

let box_value llval =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
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

let codegen_atom atom =
    let unboxed_value = match atom with
        Ast.Int n -> const_int i64_type n
      | Ast.Bool n -> const_int i1_type (int_of_bool n)
      | Ast.Double n -> const_float double_type n
      | Ast.Nil -> const_null i1_type
      | Ast.String s -> const_string context s
      | Ast.Symbol n -> try Hashtbl.find named_values n with
                          Not_found -> raise (Error "Symbol not bound")
    in box_value unboxed_value

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

and codegen_cf_op op s2 =
  let cond_val = List.hd s2 in
  let true_val = List.hd (List.tl s2) in
  let false_val = List.hd (List.tl (List.tl s2)) in
  let start_bb = insertion_block builder in
  let the_function = block_parent start_bb in
  let truebb = append_block context "then" the_function in
  position_at_end truebb builder;
  let new_truebb = insertion_block builder in
  let falsebb = append_block context "else" the_function in
  position_at_end falsebb builder;
  let new_falsebb = insertion_block builder in
  let mergebb = append_block context "ifcont" the_function in
  position_at_end mergebb builder;
  let incoming = [(true_val, new_truebb); (false_val, new_falsebb)] in
  let phi = build_phi incoming "iftmp" builder in
  position_at_end start_bb builder;
  ignore (build_cond_br cond_val truebb falsebb builder);
  position_at_end new_truebb builder; ignore (build_br mergebb builder);
  position_at_end new_falsebb builder; ignore (build_br mergebb builder);
  position_at_end mergebb builder;
  box_value phi

and codegen_call_op f args =
  let callee =
    match lookup_function f the_module with
    | Some callee -> callee
    | None -> raise (Error "Unknown function referenced")
  in
  if Array.length (params callee) != List.length args then
    raise (Error "Incorrect # arguments passed");
  let args = Array.of_list (List.map unbox_int args) in
  build_call callee args "call" builder

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
             else if StringSet.mem s cf_ops then
               codegen_cf_op s args
             else
               codegen_call_op s args
           | _ -> raise (Error "Expected function call")
     end
  | Ast.Vector(qs) -> codegen_vector qs

and codegen_vector qs = const_vector (Array.map (fun se -> codegen_sexpr se) qs)

let codegen_proto p =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  match p with
    Ast.Prototype (name, args) ->
    let args_len = Array.length args in
    let ints = Array.make args_len i64_type in
    let ft = if args_len == 0 then
               function_type i64_type ints
             else
               function_type (pointer_type value_t) ints in
    let f =
      match lookup_function name the_module with
        None -> declare_function name ft the_module

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
        let ret_val =
          if Array.length (params the_function) == 0 then
            unbox_int (codegen_sexpr body)
          else
            codegen_sexpr body in

        (* Finish off the function. *)
        let _ = build_ret ret_val builder in

        the_function
      with e ->
        delete_function the_function;
        raise e
