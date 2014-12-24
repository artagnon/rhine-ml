open Ast
open Ctypes

exception Error of string

let (--) i j =
    let rec aux n acc =
      if n < i then acc else aux (n-1) (n :: acc)
    in aux j []

type lang_value = LangInt of int
                | LangBool of bool
                | LangString of string
                | LangArray of lang_value array
                | LangDouble of float
                | LangChar of char
                | LangNil

external unbox_value: 'a -> lang_value = "unbox_value"

let string_of_bool = function true -> "true" | false -> "false"
let bool_of_int = function 0 -> false | 1 -> true
			   | x -> raise (Error ("Invalid input: " ^
						  string_of_int x))
let string_of_charp obj len =
  let rec implode = function
      []       -> ""
    | charlist -> (Char.escaped (List.hd charlist)) ^
                    (implode (List.tl charlist)) in
  implode (List.map (fun idx -> !@(obj +@ idx)) (0--(len - 1)))

let rec print_value v =
  let arelprint a = print_value a; print_char ';' in
  match v with
    LangInt n -> print_int n
  | LangBool n -> print_string (string_of_bool n)
  | LangString s -> print_string s
  | LangArray a -> print_char '['; Array.iter arelprint a; print_char ']'
  | LangDouble d -> print_float d
  | LangChar c -> print_char c
  | LangNil -> print_string "(nil)"

let rec lang_val_to_ast lv =
  match lv with
    LangInt n -> Ast.Atom(Ast.Int n)
  | LangBool n -> Ast.Atom(Ast.Bool n)
  | LangString s -> Ast.Atom(Ast.String s)
  | LangArray a -> Ast.List(Array.to_list (Array.map lang_val_to_ast a))
  | LangDouble d -> Ast.Atom(Ast.Double d)
  | LangChar c -> Ast.Atom(Ast.Char c)
  | LangNil -> Ast.Atom Ast.Nil
