open Format
open Parsetree

exception Error of string

let sprint_bool = function true -> "true"
                         | false -> "false"

(* pretty print atoms *)
let ppatom p = match p with
    Symbol(s) -> "sym:" ^ s
  | String(s) -> "str:" ^ s
  | Int(i) -> sprintf "int:%d" i
  | Char(i) -> sprintf "char:%c" i
  | Bool(i) -> sprintf "bool:%s" (sprint_bool i)
  | Double(d) -> sprintf "dbl:%f" d
  | RestArgs(s) -> "&" ^ s
  | Nil -> "nil"

(* pretty print S-expressions *)
let rec ppsexpr p =
  let lfolder i j = i ^ (match j with
                           Atom(a) -> ppatom a ^ " "
                         | _ -> ppsexpr j) in
  let vfolder i j = i ^ ppsexpr j ^ " " in
  match p with
    Atom(a) -> ppatom a
  | SQuote(se) -> sprintf "`%s" (ppsexpr se)
  | Unquote(se) -> sprintf "~%s" (ppsexpr se)
  | List(sel) -> sprintf "(%s)" (List.fold_left lfolder "" sel)
  | Array(qs) -> sprintf "[%s]" (List.fold_left vfolder "" qs)
  | _ -> raise (Error "Don't know how to print cooked AST")

let rec ppsexprl p =
  let lfolder i j = i ^ (ppsexpr j) ^ "\n" in
  List.fold_left lfolder "" p

(* pretty print the program *)
let pprint p = match p with
    Prog(ss) -> List.iter (fun i -> print_string (ppsexpr i.lsexpr_desc);
                                    print_newline ();
                                    print_newline ()) ss
