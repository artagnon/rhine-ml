open Codegen
open Llvm

let rec parse_sexpr s = match s with
    Ast.Atom n -> codegen_atom n
  | Ast.DottedPair(s1, s2) -> begin match s1 with
                                      Ast.Atom n -> codegen_atom n
                                    | _ -> parse_sexpr s1
                              end;
                              begin match s2 with
                                      Ast.Atom n -> codegen_atom n
                                    | _ -> parse_sexpr s2
                              end

let main_loop ss = List.iter (fun i -> dump_value (parse_sexpr i)) ss
