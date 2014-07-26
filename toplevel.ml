open Codegen
open Llvm

let emit_anonymous_f s =
  codegen_func(Ast.Function(Ast.Prototype("", [||]), s))

let main_loop ss = List.iter (fun i -> dump_value (emit_anonymous_f i)) ss
