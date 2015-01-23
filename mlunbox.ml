open Parsetree
open Ctypes

exception Error of string

let (--) i j =
    let rec aux n acc =
      if n < i then acc else aux (n-1) (n :: acc)
    in aux j []

type cvalue_t
let cvalue_t : cvalue_t structure typ = structure "cvalue_t"
let lang_type = field cvalue_t "lang_type" int32_t
let lang_int = field cvalue_t "lang_int" int64_t
let lang_bool = field cvalue_t "lang_bool" char
let lang_string = field cvalue_t "lang_string" (ptr char)
let lang_array = field cvalue_t "lang_array" (ptr (ptr_opt cvalue_t))
let arraysz = field cvalue_t "arraysz" int64_t
let lang_double = field cvalue_t "lang_double" double
let functionptr = field cvalue_t "functionptr" double
let lang_char = field cvalue_t "lang_char" char
let () = seal cvalue_t

type lang_value = LangInt of int
                | LangBool of bool
                | LangString of string
                | LangArray of lang_value list
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

let rec unbox_value value =
  let t = Int32.to_int (getf value lang_type) in
  match t with
    1 -> LangInt (Int64.to_int (getf value lang_int))
  | 2 -> LangBool (bool_of_int (Char.code (getf value lang_bool)))
  | 3 -> LangString (string_of_charp (getf value lang_string)
				     (Int64.to_int (getf value arraysz)))
  | 4 -> LangArray (array_of_cvaluep (getf value lang_array)
				     (Int64.to_int (getf value arraysz)))
  | 6 -> LangDouble (getf value lang_double)
  | 8 -> LangChar (getf value lang_char)
  | _ -> raise (Error ("Invalid type " ^ (string_of_int t)))

and array_of_cvaluep obj len =
  List.map (fun idx -> let box = !@(obj +@ idx) in
		       match box with
			 None -> LangNil
		       | Some v -> unbox_value !@v) (0--(len - 1))

let rec print_value v =
  let arelprint a = print_value a; print_char ';' in
  match v with
    LangInt n -> print_int n
  | LangBool n -> print_string (string_of_bool n)
  | LangString s -> print_string s
  | LangArray a -> print_char '['; List.iter arelprint a; print_char ']'
  | LangDouble d -> print_float d
  | LangChar c -> print_char c
  | LangNil -> print_string "(nil)"

let rec lang_val_to_ast lv =
  match lv with
    LangInt n -> Parsetree.Atom(Parsetree.Int n)
  | LangBool n -> Parsetree.Atom(Parsetree.Bool n)
  | LangString s -> Parsetree.Atom(Parsetree.String s)
  | LangArray a -> Parsetree.List(List.map lang_val_to_ast a)
  | LangDouble d -> Parsetree.Atom(Parsetree.Double d)
  | LangChar c -> Parsetree.Atom(Parsetree.Char c)
  | LangNil -> Parsetree.Atom Parsetree.Nil
