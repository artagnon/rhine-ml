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

let atom_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "int?"; "dbl?"; "ar?" ]

let arith_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "+"; "-"; "*"; "/"; "%"; "^" ]

let logical_ops = List.fold_left (fun s k -> StringSet.add k s)
                                 StringSet.empty
                                 [ "and"; "or"; "not" ]

let cmp_ops = List.fold_left (fun s k -> StringSet.add k s)
                             StringSet.empty
                             [ "<"; ">"; "<="; ">="; "=" ]

let array_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "first"; "rest"; "cons"; "length" ]

let string_ops = List.fold_left (fun s k -> StringSet.add k s)
                                StringSet.empty
                                [ "str-split"; "str-join"; "str-length" ]

let cf_ops = List.fold_left (fun s k -> StringSet.add k s)
                            StringSet.empty
                            [ "if"; "when"; "dotimes" ]

let binding_ops = List.fold_left (fun s k -> StringSet.add k s)
                                 StringSet.empty
                                 [ "let"; "def" ]

let create_entry_block_alloca the_function var_name =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let builder = builder_at context (instr_begin (entry_block the_function)) in
  build_alloca value_t var_name builder

let build_malloc llsize llt id builder =
  let callee = match lookup_function "malloc" the_module with
      Some callee -> callee
    | None -> raise (Error "Unknown function referenced") in
  let raw_ptr = build_call callee [| llsize |] id builder in
  build_bitcast raw_ptr (pointer_type llt) "malloc_value" builder

let build_strlen llv =
  let callee = match lookup_function "strlen" the_module with
      Some callee -> callee
    | None -> raise (Error "strlen function undeclared") in
  build_call callee [| llv |] "strlen" builder

let build_memcpy src dst llsize =
  let callee = match lookup_function "llvm.memcpy.p0i8.p0i8.i64" the_module with
      Some callee -> callee
    | None -> raise (Error "memcpy function undeclared") in
  build_call callee [| dst; src; llsize;
                       const_int i32_type 0;
                       const_int i1_type 0 |] "" builder

let build_pow base exp =
  let callee = match lookup_function "llvm.pow.f64" the_module with
      Some callee -> callee
    | None -> raise (Error "pow function undeclared") in
  build_call callee [| base; exp |] "pow" builder

let idx n = [| const_int i32_type 0; const_int i32_type n |]

let undef_vec len =
  let undef_list = List.map (fun i -> undef i64_type) (0--(len - 1)) in
  const_vector (Array.of_list undef_list)

let box_value ?(lllen = const_null i32_type) llval =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let value_ptr = build_malloc (size_of value_t) value_t "value" builder in
  let match_pointer ty = match ty with
    | ty when ty = pointer_type (function_type (pointer_type value_t)
                                               [| (pointer_type value_t) |]) ->
       (7, llval)
    | _ ->
       match element_type ty with
         ty when ty = i8_type ->
         let len = if is_null lllen then build_strlen llval else lllen in
         let lenptr = build_in_bounds_gep value_ptr (idx 5) "lenptr" builder in
         ignore (build_store len lenptr builder);
         (3, llval)
       | ty when ty = pointer_type value_t ->
          let len = lllen in
          let lenptr = build_in_bounds_gep value_ptr (idx 5) "lenptr" builder in
          ignore (build_store len lenptr builder);
          (4, llval)
       | ty -> raise (Error ("Don't know how to box type: " ^
                               (string_of_lltype ty))) in
  let match_composite ty = match classify_type ty with
      TypeKind.Pointer -> match_pointer ty
    | _ -> raise (Error ("Don't know how to box type: " ^
                           (string_of_lltype ty))) in
  let (type_tag, llval) = match type_of llval with
      ty when ty = i64_type ->
       (1, llval)
    | ty when ty = i1_type ->
       (2, llval)
    | ty when ty = double_type ->
       (6, llval)
    | ty when ty = i8_type ->
       (8, llval)
    | ty -> match_composite ty
  in
  let type_dst = build_in_bounds_gep value_ptr (idx 0) "boxptr" builder in
  let dst = build_in_bounds_gep value_ptr (idx type_tag) "boxptr" builder in
  let lltype_tag = const_int i32_type type_tag in
  ignore (build_store lltype_tag type_dst builder);
  ignore (build_store llval dst builder);
  value_ptr

let get_type llval =
  let type_num = build_in_bounds_gep llval (idx 0) "boxptr" builder in
  build_load type_num "load" builder

let unbox_dbl llval =
  let dst = build_in_bounds_gep llval (idx 6) "boxptr" builder in
  build_load dst "load" builder

let unbox_int llval =
  let dst = build_in_bounds_gep llval (idx 1) "boxptr" builder in
  build_load dst "load" builder

let unbox_bool llval =
  let dst = build_in_bounds_gep llval (idx 2) "boxptr" builder in
  build_load dst "load" builder

let unbox_function llval =
  let dst = build_in_bounds_gep llval (idx 7) "boxptr" builder in
  build_load dst "load" builder

let unbox_str llval =
  let dst = build_in_bounds_gep llval (idx 3) "boxptr" builder in
  build_load dst "load" builder

let unbox_length llval =
  let dst = build_in_bounds_gep llval (idx 5) "boxptr" builder in
  build_load dst "load" builder

let unbox_ar llval =
  let dst = build_in_bounds_gep llval (idx 4) "boxptr" builder in
  build_load dst "load" builder

let codegen_atom atom =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  let unboxed_value = match atom with
      Ast.Int n -> const_int i64_type n
    | Ast.Bool n -> const_int i1_type (int_of_bool n)
    | Ast.Double n -> const_float double_type n
    | Ast.Char c -> const_int i8_type (int_of_char c)
    | Ast.Nil -> const_null (pointer_type value_t)
    | Ast.String s -> build_global_stringptr s "string" builder
    | Ast.Symbol n -> match lookup_global n the_module with
                        Some v -> v
                      | None ->
                         match lookup_function n the_module with
                           Some f -> box_value f
                         | None ->
                            try Hashtbl.find named_values n with
                              Not_found -> raise (Error ("Symbol unbound:" ^ n))
  in match atom with
       Ast.Symbol n -> unboxed_value
     | Ast.Nil -> unboxed_value
     | _ -> box_value unboxed_value

let rec extract_args s =
  match s with
    Ast.List(se) -> List.map codegen_sexpr se
  | _ -> raise (Error "Expected list")

and is_int el =
  build_icmp Icmp.Eq (get_type el) (const_int i32_type 1) "int?" builder

and is_dbl el =
  build_icmp Icmp.Eq (get_type el) (const_int i32_type 6) "is_dbl" builder

and is_ar el =
  build_icmp Icmp.Eq (get_type el) (const_int i32_type 4) "ar?" builder

and codegen_atom_op op args =
  let hd = List.hd args in
  let unboxed_value = match op with
      "int?" -> is_int hd
    | "dbl?" -> is_dbl hd
    | "ar?" -> is_ar hd
    | _ -> raise (Error "Unknown atom op") in
  box_value unboxed_value

and to_dbl el =
  let condf () = is_dbl el in
  let truef () = unbox_dbl el in
  let falsef () = let iel = unbox_int el in
                  build_sitofp iel double_type "sitofp" builder in
  codegen_if condf truef falsef

and to_int el =
  let condf () = is_int el in
  let truef () = unbox_int el in
  let falsef () = let del = unbox_dbl el in
                  build_fptosi del i64_type "fptosi" builder in
  codegen_if condf truef falsef

and codegen_arith_op op args =
  let hd = List.hd args in
  let tl = List.tl args in
  if tl == [] then hd else
    let snd = List.nth args 1 in
    let is_dbl_list = List.map (fun i -> box_value (is_dbl i)) args in
    let condf () = unbox_bool (codegen_logical_op "or" is_dbl_list) in
    let trueff f () = let dhd = to_dbl hd in
                      let dsnd = to_dbl (codegen_arith_op op tl) in
                      box_value (f dhd dsnd "fop" builder) in
    let falseff f () = let ihd = unbox_int hd in
                       let isnd = unbox_int (codegen_arith_op op tl) in
                       box_value (f ihd isnd "iop" builder) in
    match op with
      "+" -> let truef = trueff build_fadd in
             let falsef = falseff build_add in
             codegen_if condf truef falsef
    | "-" -> let truef = trueff build_fsub in
             let falsef = falseff build_sub in
             codegen_if condf truef falsef
    | "/" -> trueff build_fdiv ()
    | "*" -> let truef = trueff build_fmul in
             let falsef = falseff build_mul in
             codegen_if condf truef falsef
    | "%" -> let ihd = to_int hd in
             let isnd = to_int snd in
             box_value (build_udiv ihd isnd "iop" builder)
    | "^" -> let dhd = to_dbl hd in
             let dsnd = to_dbl snd in
             box_value (build_pow dhd dsnd)
    | _ -> raise (Error "Unknown arithmetic operator")

and codegen_logical_op op args =
  let hd = unbox_bool (List.hd args) in
  let tl = List.tl args in
  let unboxed_value =
    match op with
      "not" -> build_xor hd (const_int i1_type 1) "not" builder
    | _ ->
       if tl == [] then hd else
         match op with
           "and" -> build_and hd (unbox_bool (codegen_logical_op op tl))
                              "and" builder
         | "or" -> build_or hd (unbox_bool (codegen_logical_op op tl))
                            "or" builder
         | _ -> raise (Error "Unknown logical operator") in
  box_value unboxed_value

and codegen_cmp_op op args =
  let hd = List.hd args in
  let snd = List.nth args 1 in
  let uhd = to_int hd in
  let usnd = to_int snd in
  match op with
    "<" -> box_value (build_icmp Icmp.Slt uhd usnd "lt" builder)
  | ">" -> box_value (build_icmp Icmp.Sgt uhd usnd "gt" builder)
  | "<=" -> box_value (build_icmp Icmp.Sle uhd usnd "le" builder)
  | ">=" -> box_value (build_icmp Icmp.Sge uhd usnd "ge" builder)
  | "=" -> codegen_call_op "cequ" [hd;snd]
  | _ -> raise (Error "Unknown comparison operator")

and codegen_array_op op args =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  let arg = List.hd args in
  match op with
    "first" ->
    let first_el ar = build_load ar "first" builder in
    let condf () = unbox_bool (codegen_atom_op "ar?" [arg]) in
    let truef () = first_el (unbox_ar arg) in
    let falsef () = box_value (first_el (unbox_str arg)) in
    codegen_if condf truef falsef
  | "rest" ->
     let len = unbox_length arg in
     let newlen = build_sub len (const_int i64_type 1) "restsub" builder in
     let condf () = unbox_bool (codegen_atom_op "ar?" [arg]) in
     let truef () =
       let el = unbox_ar arg in
       let newptr = build_in_bounds_gep el [| const_int i64_type 1 |]
                                        "rest" builder in
       box_value ~lllen:newlen newptr in
     let falsef () =
       let el = unbox_str arg in
       let newptr = build_in_bounds_gep el [| const_int i64_type 1 |]
                                         "rest" builder in
       box_value ~lllen:newlen newptr in
     codegen_if condf truef falsef
  | "length" ->
     box_value (unbox_length arg)
  | "cons" ->
     let tail = List.nth args 1 in
     let lenptr = build_in_bounds_gep tail (idx 5) "boxptr" builder in
     let len_32 = build_load lenptr "lenptr" builder in
     let len = build_zext len_32 i64_type "len_64" builder in
     let sizeof = size_of value_t in
     let size = build_mul len sizeof "size" builder in
     let newlen = build_add len (const_int i64_type 1) "conslen" builder in
     let newsize = build_mul newlen sizeof "newsize" builder in
     let ptr = build_malloc newsize (pointer_type value_t) "malloc" builder in
     let ptrhead = build_in_bounds_gep ptr [| const_int i32_type 0 |]
                                       "ptrhead" builder in
     let ptrrest = build_in_bounds_gep ptr [| const_int i32_type 1 |]
                                       "ptrrest" builder in
     let tailptr = build_in_bounds_gep tail (idx 4) "ptrhead" builder in
     let tailel = build_load tailptr "tailptr" builder in
     let rawsrc = build_bitcast tailel (pointer_type i8_type)
                                "rawsrc" builder in
     let rawdst = build_bitcast ptrrest (pointer_type i8_type)
                                "rawdst" builder in
     ignore (build_store arg ptrhead builder);
     ignore (build_memcpy rawsrc rawdst size);
     box_value ~lllen:newlen ptr
  | _ -> raise (Error "Unknown array operator")

and codegen_string_op op s2 =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  let rharel_type = pointer_type value_t in
  match op with
    "str-join" ->
      let arg = List.hd s2 in
        codegen_call_op "cstrjoin" [arg]
    | "str-split" ->
      let arg = List.hd s2 in
      let str = unbox_str arg in
      let len = unbox_length arg in
      let size = build_mul (size_of rharel_type)
                         len "size" builder in
      let newar = build_malloc size rharel_type "newar" builder in

      let var_name = "i" in
      let loop_lim = box_value len in
      let start_val = codegen_sexpr (Ast.Atom(Ast.Int(0))) in
      let start_bb = insertion_block builder in
      let the_function = block_parent start_bb in
      let loop_bb = append_block context "loop" the_function in
      ignore (build_br loop_bb builder);
      position_at_end loop_bb builder;
      let variable = build_phi [(start_val, start_bb)] var_name builder in
      let old_val =
        try Some (Hashtbl.find named_values var_name) with Not_found -> None
      in
      Hashtbl.add named_values var_name variable;
      (* start body *)
      let loopidx = unbox_int variable in
      let ptr = build_in_bounds_gep str [| loopidx |]
                                    "extract" builder in
      let el = build_load ptr "extractload" builder in
      let newptr = build_in_bounds_gep newar [| loopidx |] "arptr" builder in
      ignore (build_store (box_value el) newptr builder);
      (* end body *)
      let next_var = build_add (unbox_int variable)
                             (const_int i64_type 1) "nextvar" builder in
      let next_var = box_value next_var in
      let end_cond = build_icmp Icmp.Slt (unbox_int next_var)
                              (unbox_int loop_lim) "end_cond" builder in
      let loop_end_bb = insertion_block builder in
      let after_bb = append_block context "after_loop" the_function in
      ignore (build_cond_br end_cond loop_bb after_bb builder);
      position_at_end after_bb builder;
      add_incoming (next_var, loop_end_bb) variable;
      begin match old_val with
            Some old_val -> Hashtbl.add named_values var_name old_val
          | None -> ()
      end;
      box_value ~lllen:len newar
  | "str-length" ->
     box_value (unbox_length (List.hd s2))
  | _ -> raise (Error "Unknown string operator")

and codegen_if condf truef falsef =
  let cond_val = condf () in
  let start_bb = insertion_block builder in
  let the_function = block_parent start_bb in
  let truebb = append_block context "then" the_function in
  position_at_end truebb builder;
  let true_val = truef () in
  let new_truebb = insertion_block builder in
  let falsebb = append_block context "else" the_function in
  position_at_end falsebb builder;
  let false_val = falsef () in
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

and codegen_cf_op op s2 =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  match op with
    "if" ->
    let condse, truese, falsese = match s2 with
        Ast.List([c; t; f]) -> c, t, f
      | _ -> raise (Error "Malformed if expression") in
    let condf () = unbox_bool (codegen_sexpr condse) in
    let truef () = codegen_sexpr truese in
    let falsef () = codegen_sexpr falsese in
    codegen_if condf truef falsef
  | "when" ->
     let condse, truese = match s2 with
         Ast.List([c; t]) -> c, t
       | _ -> raise (Error "Malformed when expression") in
     let condf () = unbox_bool (codegen_sexpr condse) in
     let truef () = codegen_sexpr truese in
     let falsef () = const_null (pointer_type value_t) in
     codegen_if condf truef falsef
  | "dotimes" ->
     let qs, body = match s2 with
         Ast.List(Ast.Vector(qs)::body) -> qs, body
       | _ -> raise (Error "Malformed dotimes expression") in
     let var_name = match List.hd qs with
         Ast.Atom(Ast.Symbol(s)) -> s
       | _ -> raise (Error "Expected symbol in dotimes") in
     let loop_lim = codegen_sexpr (List.nth qs 1) in
     let start_val = codegen_sexpr (Ast.Atom(Ast.Int(0))) in
     let start_bb = insertion_block builder in
     let the_function = block_parent start_bb in
     let loop_bb = append_block context "loop" the_function in
     ignore (build_br loop_bb builder);
     position_at_end loop_bb builder;
     let variable = build_phi [(start_val, start_bb)] var_name builder in
     let old_val =
       try Some (Hashtbl.find named_values var_name) with Not_found -> None
     in
     Hashtbl.add named_values var_name variable;
     ignore (codegen_sexpr_list body);
     let next_var = build_add (unbox_int variable)
                              (const_int i64_type 1) "nextvar" builder in
     let next_var = box_value next_var in
     let end_cond = build_icmp Icmp.Slt (unbox_int next_var)
                               (unbox_int loop_lim) "end_cond" builder in
     let loop_end_bb = insertion_block builder in
     let after_bb = append_block context "after_loop" the_function in
     ignore (build_cond_br end_cond loop_bb after_bb builder);
     position_at_end after_bb builder;
     add_incoming (next_var, loop_end_bb) variable;
     begin match old_val with
             Some old_val -> Hashtbl.add named_values var_name old_val
           | None -> ()
     end;
     box_value (const_int i64_type 0)
  | _ -> raise (Error "Unknown control flow operation")

and codegen_call_op f args =
  let callee = match lookup_function f the_module with
      Some callee -> callee
    | None ->
       let v = try Hashtbl.find named_values f with
                 Not_found -> raise (Error ("Unknown function: " ^ f)) in
       unbox_function v
  in
  let args = Array.of_list args in
  build_call callee args "call" builder;

and codegen_binding_op f s2 =
  let old_bindings = ref [] in
  match f with
    "let" ->
    let bindlist, body = match s2 with
        Ast.List(l) ->
        begin match l with
                Ast.Vector(qs)::next -> qs, next
              | _ -> raise (Error "Malformed let")
        end
      | _ -> raise (Error "Malformed let") in
    let len = List.length bindlist in
    if len mod 2 != 0 then
      raise (Error "Malformed binding form in let");
    let bind n a =
      let s = match n with
          Ast.Atom(Ast.Symbol(s)) -> s
        | _ -> raise (Error "Malformed binding form in let") in
      let llaptr = codegen_sexpr a in
      let lla = build_load llaptr "load" builder in
      let the_function = block_parent (insertion_block builder) in
      let alloca = create_entry_block_alloca the_function s in
      ignore (build_store lla alloca builder);
      begin try let old_value = Hashtbl.find named_values s in
                old_bindings := (s, old_value) :: !old_bindings;
            with Not_found -> ()
      end;
      Hashtbl.add named_values s alloca in
    List.iteri (fun i m ->
                 if (i mod 2 == 0) then
                   bind m (List.nth bindlist (i+1))) bindlist;
    let llbody = codegen_sexpr_list body in
    List.iter (fun (s, old_value) ->
               Hashtbl.add named_values s old_value
              ) !old_bindings;
    llbody
    | _ -> raise (Error "Unknown binding operator")

and match_action s s2 =
  if StringSet.mem s binding_ops then
    codegen_binding_op s s2
  else if StringSet.mem s cf_ops then
    codegen_cf_op s s2
  else
    let args = extract_args s2 in
    if StringSet.mem s atom_ops then
      codegen_atom_op s args
    else if StringSet.mem s arith_ops then
      codegen_arith_op s args
    else if StringSet.mem s logical_ops then
      codegen_logical_op s args
    else if StringSet.mem s cmp_ops then
      codegen_cmp_op s args
    else if StringSet.mem s array_ops then
      codegen_array_op s args
    else if StringSet.mem s string_ops then
      codegen_string_op s args
    else
      codegen_call_op s args

and codegen_sexpr s = match s with
    Ast.Atom n -> codegen_atom n
  | Ast.Vector(qs) -> codegen_array qs
  | Ast.List(Ast.Atom(Ast.Symbol s)::s2) ->
     match_action s (Ast.List s2)
  | _ -> raise (Error "Expected atom, vector, or function call")

and codegen_sexpr_list sl =
  let r = List.map (fun se ->
                    match se with
                      Ast.List(l2) ->
                      begin match l2 with
                              Ast.Atom(Ast.Symbol s)::s2 ->
                              match_action s (Ast.List s2)
                            | _ -> raise (Error "Expected symbol")
                      end
                    | Ast.Atom n -> codegen_atom n
                    | Ast.Vector(qs) -> codegen_array qs
                    | _ -> raise (Error ("Can't codegen that"))) sl in
  List.hd (List.rev r)

and codegen_array qs =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t") in
  let len = List.length qs in
  let rharray_type size = array_type (pointer_type value_t) size in
  let new_array = build_alloca (rharray_type len) "ar" builder in
  let ptr n = build_in_bounds_gep new_array (idx n) "arptr" builder in
  let llqs = List.map codegen_sexpr qs in
  let lllen = const_int i64_type len in
  List.iteri (fun i m -> ignore (build_store m (ptr i) builder)) llqs;
  box_value ~lllen:lllen (ptr 0)

let codegen_proto ?(main_p = false) p =
  let value_t = match type_by_name the_module "value_t" with
      Some t -> t
    | None -> raise (Error "Could not look up value_t")
  in
  match p with
    Ast.Prototype (name, args) ->
    let args_len = Array.length args in
    let argt = Array.make args_len (pointer_type value_t)  in
    let ft = if main_p then
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

let codegen_func ?(main_p = false) f = match f with
    Ast.Function (proto, body) ->
    Hashtbl.clear named_values;

    let the_function = codegen_proto ~main_p:main_p proto in
    (* Create a new basic block to start insertion into. *)
    let bb = append_block context "entry" the_function in
    position_at_end bb builder;

    try
      let ret_val =
        if main_p then
          unbox_int (codegen_sexpr_list body)
        else
          codegen_sexpr_list body in

      (* Finish off the function. *)
      let _ = build_ret ret_val builder in
      the_function
    with e ->
      delete_function the_function;
      raise e
