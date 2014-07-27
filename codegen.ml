open Llvm

module StringSet = Set.Make(String)

exception Error of string

let context = global_context ()
let the_module = create_module context "Rhine JIT"
let builder = builder context
let named_values:(string, llvalue) Hashtbl.t = Hashtbl.create 10
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
                                [ "head"; "tail" ]

let undef_vec len =
  let undef_list = List.map (fun i -> undef i64_type) (0--(len - 1)) in
  const_vector (Array.of_list undef_list)

let mask_vec len =
  let mask_list = List.map (fun i -> const_int i32_type i) (1--(len - 1)) in
  const_vector (Array.of_list mask_list)

let typeconvert_atom = function
    Ast.Int n -> Ast.Double (float_of_int n)

let codegen_atom = function
    Ast.Int n -> const_int i64_type n
  | Ast.Bool n -> const_int i1_type (int_of_bool n)
  | Ast.Double n -> const_float double_type n
  | Ast.Nil -> const_null i1_type
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

and extract_vec s = match s with
    Ast.DottedPair(s1, s2) ->
    begin match (s1, s2) with
          | (Ast.Vector(qs), Ast.Atom(Ast.Nil)) -> qs
    end
  | _ -> raise (Error "Expected sexp")

and codegen_arith_op op args =
  let hd = List.hd args in
  let tl = List.tl args in
  if tl == [] then hd else
    match op with
      "+" -> build_add hd (codegen_arith_op op tl) "addtmp" builder
    | "-" -> build_sub hd (codegen_arith_op op tl) "subtmp" builder
    | "*" -> build_mul hd (codegen_arith_op op tl) "multmp" builder
    | "/" -> build_fdiv hd (codegen_arith_op op tl) "divtmp" builder
    | _ -> raise (Error "Unknown arithmetic operator")

and codegen_vector_op op vec =
  let llvec = codegen_vector vec in
  let len = Array.length vec in
  let idx0 = const_int i32_type 0 in
  match op with
    "head" -> build_extractelement llvec idx0 "extracttmp" builder
  | "tail" -> build_shufflevector llvec (undef_vec len)
                                  (mask_vec len) "shuffletmp" builder
  | _ -> raise (Error "Unknown vector operator")

and codegen_sexpr s = match s with
    Ast.Atom n -> codegen_atom n
  | Ast.DottedPair(s1, s2) ->
     begin match s1 with
             Ast.Atom(Ast.Symbol s) ->
             if StringSet.mem s arith_ops then
               let args = extract_args s2 in
               codegen_arith_op s args
             else if StringSet.mem s vector_ops then
               let vec = extract_vec s2 in
               codegen_vector_op s vec
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
        let ret_val = codegen_sexpr body in

        (* Finish off the function. *)
        let _ = build_ret ret_val builder in

        the_function
      with e ->
        delete_function the_function;
        raise e
