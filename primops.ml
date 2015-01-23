module StringSet = Set.Make(String)

let atom_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "bool?"; "int?"; "dbl?"; "ar?" ]

let arith_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "+"; "-"; "*"; "/"; "%"; "^" ]

let logical_ops = List.fold_left (fun s k -> StringSet.add k s)
                                 StringSet.empty
                                 [ "and"; "or"; "not" ]

let cmp_ops = List.fold_left (fun s k -> StringSet.add k s)
                             StringSet.empty
                             [ "<"; ">"; "<="; ">="; "=" ]

let array_ops = List.fold_left (fun s k -> StringSet.add k s)
                               StringSet.empty
                               [ "first"; "rest"; "cons"; "length" ]

let string_ops = List.fold_left (fun s k -> StringSet.add k s)
                                StringSet.empty
                                [ "str-split"; "str-join"; "str-length" ]

let cf_ops = List.fold_left (fun s k -> StringSet.add k s)
                            StringSet.empty
                            [ "if"; "when"; "dotimes" ]

let binding_ops = List.fold_left (fun s k -> StringSet.add k s)
                                 StringSet.empty
                                 [ "let"; "def" ]
