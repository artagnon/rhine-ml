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

let array_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "first"; "rest" ]

let string_ops = List.fold_left (fun s k -> StringSet.add k s)
                                StringSet.empty
                                [ "str-split"; "str-join" ]

let cf_ops = List.fold_left (fun s k -> StringSet.add k s)
                            StringSet.empty
                            [ "if"; "dotimes" ]

let binding_ops = List.fold_left (fun s k -> StringSet.add k s)
                                 StringSet.empty
                                 [ "let"; "def" ]

let idx n = [| const_int i32_type 0; const_int i32_type n |]

let undef_vec len =
  let undef_list = List.map (fun i -> undef i64_type) (0--(len - 1)) in
  const_vector (Array.of_list undef_list)

let box_value llval =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let rhstring_type size = array_type i8_type size in
  let rharray_type size = array_type (pointer_type value_t) size in
  let value_ptr = build_alloca value_t "value" builder in
  let match_pointer ty = match element_type ty with
      ty when ty = i8_type ->
      let ptr = build_in_bounds_gep value_ptr (idx 3) "boxptr" builder in
      let str_ptr = build_in_bounds_gep ptr [| const_int i32_type 0 |]
                                        "strptr" builder in
      let new_str = build_alloca (rhstring_type 10) "str" builder in
      let new_str_ptr = build_in_bounds_gep new_str (idx 0) "strptr" builder in
      ignore (build_store new_str_ptr str_ptr builder);
      (3, llval)
    | ty when ty = rharray_type 10 ->
       (4, build_in_bounds_gep llval (idx 0) "llval" builder)
    | ty -> raise (Error "Don't know how to box type") in
  let match_composite ty = match classify_type ty with
      TypeKind.Pointer -> match_pointer ty
    | _ -> raise (Error "Don't know how to box type") in
  let (type_tag, llval) = match type_of llval with
      ty when ty = i64_type ->
      (1, llval)
    | ty when ty = i1_type ->
       (2, llval)
    | ty -> match_composite ty
  in
  let type_dst = build_in_bounds_gep value_ptr (idx 0) "boxptr" builder in
  let dst = build_in_bounds_gep value_ptr (idx type_tag) "boxptr" builder in
  let lltype_tag = const_int i32_type type_tag in
  ignore (build_store lltype_tag type_dst builder);
  ignore (build_store llval dst builder);
  value_ptr

let unbox_int llval =
  let dst = build_in_bounds_gep llval (idx 1) "boxptr" builder in
  build_load dst "load" builder

let unbox_bool llval =
  let dst = build_in_bounds_gep llval (idx 2) "boxptr" builder in
  build_load dst "load" builder

let unbox_str llval =
  let ptr = build_in_bounds_gep llval (idx 3) "boxptr" builder in
  let el = build_load ptr "el" builder in
  let rhstring_type size = pointer_type (array_type i8_type size) in
  let str n = build_bitcast el (rhstring_type n) "strptr" builder in
  let strload n = build_load (str n) "load" builder in
  strload 10

let unbox_ar llval =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let ptr = build_in_bounds_gep llval (idx 4) "boxptr" builder in
  let el = build_load ptr "el" builder in
  let rharray_type size = pointer_type (array_type
                                          (pointer_type value_t) size) in
  let vec n = build_bitcast el (rharray_type n) "arptr" builder in
  let arload n = build_load (vec n) "load" builder in
  arload 10

let codegen_atom atom =
  let unboxed_value = match atom with
      Ast.Int n -> const_int i64_type n (*i32*)
    | Ast.Bool n -> const_int i1_type (int_of_bool n)
    | Ast.Double n -> const_float double_type n
    | Ast.Nil -> const_null i1_type
    | Ast.String s -> build_global_stringptr s "string" builder
    | Ast.Symbol n -> try Hashtbl.find named_values n with
                        Not_found -> raise (Error "Symbol not bound")
  in match atom with
       Ast.Symbol n -> unboxed_value
     | _ -> box_value unboxed_value

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
             (codegen_array qs)::(extract_args s2)
          | (Ast.Vector(qs), Ast.Atom(Ast.Nil)) -> [codegen_array qs]
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

and codegen_array_op op args =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let arg = List.hd args in
  match op with
    "first" ->
    let ar = unbox_ar arg in
    build_extractvalue ar 0 "extract" builder
  | "rest" ->
     let ptr = build_in_bounds_gep arg (idx 4) "boxptr" builder in
     let el = build_load ptr "el" builder in
     let rharray_type size = pointer_type (array_type
                                             (pointer_type value_t) size) in
     let ar = build_bitcast el (rharray_type 10) "arptr" builder in
     let new_ptr = build_in_bounds_gep ar (idx 1) "rest" builder in
     let new_ar = build_bitcast new_ptr (rharray_type 10) "newar" builder in
     box_value new_ar
  | _ -> raise (Error "Unknown array operator")

and codegen_string_op op s2 =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  let rharray_type size = array_type (pointer_type value_t) size in
  let rhstring_type size = array_type i8_type size in
  let nullterm = const_int i8_type 0 in
  let unboxed_value = match op with
      "str-split" ->
      let str = unbox_str (List.hd s2) in
      let len = array_length (type_of str) in
      let l = List.map (fun i -> build_extractvalue
                                   str i "extract" builder) (0--(len - 1)) in
      let store_char c =
        let strseg = build_alloca (rhstring_type 2) "strseg" builder in
        let strseg0 = build_in_bounds_gep strseg (idx 0) "strseg0" builder in
        let strseg1 = build_in_bounds_gep strseg (idx 1) "strseg1" builder in
        ignore (build_store c strseg0 builder);
        ignore (build_store nullterm strseg1 builder);
        box_value strseg0 in
      let splits = List.map store_char l in
      let new_array = build_alloca (rharray_type 10) "ar" builder in
      let ptr n = build_in_bounds_gep new_array (idx n) "arptr" builder in
      List.iteri (fun i m ->
                  dump_type (type_of m);
                  dump_type (type_of (ptr i));
                  ignore (build_store m (ptr i) builder)) splits;
      new_array
    | _ -> raise (Error "Unknown string operator")
  in box_value unboxed_value

and codegen_cf_op op s2 =
  let cond_val = unbox_bool (List.hd s2) in
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
  phi

and codegen_call_op f args =
  let callee =
    match lookup_function f the_module with
    | Some callee -> callee
    | None -> raise (Error "Unknown function referenced")
  in
  if Array.length (params callee) != List.length args then
    raise (Error "Incorrect # arguments passed");
  let args = Array.of_list args in
  build_call callee args "call" builder;

and codegen_binding_op f s2 =
  match f with
    "let" ->
    let bindlist, body = match s2 with
        Ast.DottedPair(Ast.Vector(qs), next) -> qs, next
      | _ -> raise (Error "Malformed let") in
    let len = Array.length bindlist in
    if len mod 2 != 0 then
      raise (Error "Malformed binding form in let");
    let bind n a =
      let s = match n with
          Ast.Atom(Ast.Symbol(s)) -> s
        | _ -> raise (Error "Malformed binding form in let") in
      let lla = codegen_sexpr a in
      set_value_name s lla;
      Hashtbl.add named_values s lla in
    Array.iteri (fun i m ->
                 if (i mod 2 == 0) then
                   bind m (bindlist.(i+1))) bindlist;
    codegen_sexpr body
    | _ -> raise (Error "Unknown binding operator")

and codegen_sexpr s = match s with
    Ast.Atom n -> codegen_atom n
  | Ast.DottedPair(s1, s2) ->
     begin match s1 with
             Ast.Atom(Ast.Symbol s) ->
             let args = extract_args s2 in
             if StringSet.mem s arith_ops then
               codegen_arith_op s args
             else if StringSet.mem s array_ops then
               codegen_array_op s args
             else if StringSet.mem s string_ops then
               codegen_string_op s args
             else if StringSet.mem s cf_ops then
               codegen_cf_op s args
             else if StringSet.mem s binding_ops then
               codegen_binding_op s s2
             else
               codegen_call_op s args;
           | _ -> raise (Error "Expected function call")
     end
  | Ast.Vector(qs) -> codegen_array qs

and codegen_array qs =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  let rharray_type size = array_type (pointer_type value_t) size in
  let new_array = build_alloca (rharray_type 10) "ar" builder in
  let ptr n = build_in_bounds_gep new_array (idx n) "arptr" builder in
  let llqs = Array.map codegen_sexpr qs in
  Array.iteri (fun i m -> ignore (build_store m (ptr i) builder)) llqs;
  box_value new_array

let codegen_proto p =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  match p with
    Ast.Prototype (name, args) ->
    let args_len = Array.length args in
    let argt = Array.make args_len (pointer_type value_t)  in
    let ft = if args_len == 0 then
               function_type i64_type argt
             else
               function_type (pointer_type value_t) argt in
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
