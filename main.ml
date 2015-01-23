open Parsetree
type action = Pprint | Normal

let main () =
  let action = 
    if Array.length Sys.argv > 1 then
      try
        List.assoc Sys.argv.(1) [ ("-p", Pprint) ]
      with Not_found -> Normal
    else
      Normal
  in
  let lexbuf = Lexing.from_channel stdin in
  let prog = Parser.prog Lexer.token lexbuf in
  match action with
    Normal -> (match prog with
                 Prog(ss) -> Toplevel.main_loop ss)
  | Pprint -> Pretty.pprint prog
;;

main ()
