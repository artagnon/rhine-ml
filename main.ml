open Ast
type action = Debug | Normal

let print_bool = function true -> print_string "true"
                        | false -> print_string "false"

(* pretty print atoms *)
let ppatom p a = match p with
    Symbol(s) -> (match a with
                    Debug -> print_string ("sym:" ^ s)
                   |Normal -> print_string s)
   |Int(i) -> (match a with
                 Debug -> print_string "int:"; print_int i
                |Normal -> print_int i)
   |Bool(i) -> (match a with
                 Debug -> print_string "bool:"; print_bool i
                |Normal -> print_bool i)
   |Double(d) -> (match a with
                    Debug -> print_string "dbl:"; print_float d
                   |Normal -> print_float d)
   |Nil -> (match a with
              Debug -> print_string "sym:nil"
             |Normal -> print_string "nil")

(* pretty print S-expressions *)
let rec ppsexpr p islist act = match p with
    Atom(a) -> ppatom a act
   |DottedPair(se1,se2) -> if islist then () else 
                             print_string "( ";
                           (match se1 with
                              Atom(a) -> ppatom a act
                             |_ -> ppsexpr se1 false act);
                           print_char ' ';
                           (match se2 with
                              Atom(Nil) -> print_char ')'
                             |Atom(_ as a) -> print_string ". ";
                                              ppatom a act;
                                              print_string " )"
                             |_ -> ppsexpr se2 true act)
(* pretty print the program *)
let pprint p a = match p with
    Prog(ss) -> List.iter (fun i -> ppsexpr i false a;
                                    print_newline ();
                                    print_newline ()) ss

(* starting point *)
let _ =
  let action = 
    if Array.length Sys.argv > 1 then
      try
        List.assoc Sys.argv.(1) [ ("-d", Debug) ]
      with Not_found -> Normal
    else
      Normal in
  let lexbuf = Lexing.from_channel stdin in
  let prog = Parser.prog Lexer.token lexbuf in
  pprint prog action
