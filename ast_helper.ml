open Parsetree

let default_loc = ref Location.none;;

module Lsexpr = struct
  let mk ?(loc = !default_loc) d = { lsexpr_desc = d; lsexpr_loc = loc }
end
