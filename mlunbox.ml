open Ast

exception Error of string

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
