(* first-class functions: functions are also values *)
type valuety =
  (* Symbol to be bound^Wreplaced at the lookup stage: could be a
   * plain value or a function *)
  | Symbol of string
  (* Bound symbol, like function argument: used in the name
   * binding-propagation stage *)
  | Variable of varty
  (* Literal values *)
  | Int of int
  | Bool of bool
  | Double of float
  | Char of char
  | String of string
  | Array of valuety list
  | Nil
  (* Functions *)
  | Isbool of isboolty
  | Isint of isintty
  | Defn of defnty
  | Def of defty
  | Defmacro of defmacroty

and varty =
  {
    var_name : string;
    var_value : valuety;
  }

and isboolty =
  {
    isbool_argument : valuety;
    isbool_return : bool;
  }

and isintty =
  {
    isint_argument : valuety;
    isint_return : bool;
  }

and defnty =
  {
    defn_name : string;
    defn_arguments : varty list;
    defn_return : valuety;
    defn_restplaceholder : valuety list option;
    (* temporary reprise *)
    defn_sexpr : Parsetree.sexpr;
  }

and defty =
  {
    def_name : string;
    def_body : valuety;
    (* temporary reprise *)
    def_sexpr : Parsetree.sexpr;
  }

(* exact same type as defnty, except that it has "eval" instead of "return" *)
and defmacroty =
  {
    defmacro_name : string option;
    defmacro_arguments : varty list;
    defmacro_return : valuety;
    defmacro_restplaceholder : valuety list option;
    (* temporary reprise *)
    defmacro_sexpr : Parsetree.sexpr;
  }

and anonfunty =
  {
    anonfn_return : valuety;
    (* temporary reprise *)
    anonfn_sexpr : Parsetree.sexpr;
  }

