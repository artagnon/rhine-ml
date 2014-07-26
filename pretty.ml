open Ast

let print_bool = function true -> print_string "true"
                        | false -> print_string "false"

(* pretty print atoms *)
let ppatom p = match p with
    Symbol(s) -> print_string ("sym:" ^ s)
   |Int(i) -> print_string "int:"; print_int i
   |Bool(i) -> print_string "bool:"; print_bool i
   |Double(d) -> print_string "dbl:"; print_float d
   |Nil -> print_string "nil"

(* pretty print S-expressions *)
let rec ppsexpr p islist = match p with
    Atom(a) -> ppatom a
   |DottedPair(se1,se2) -> if islist then () else 
                             print_string "( ";
                           (match se1 with
                              Atom(a) -> ppatom a
                             |_ -> ppsexpr se1 false);
                           print_char ' ';
                           (match se2 with
                              Atom(Nil) -> print_char ')'
                             |Atom(_ as a) -> print_string ". ";
                                              ppatom a;
                                              print_string " )"
                             |_ -> ppsexpr se2 true)
(* pretty print the program *)
let pprint p = match p with
    Prog(ss) -> List.iter (fun i -> ppsexpr i false;
                                    print_newline ();
                                    print_newline ()) ss
