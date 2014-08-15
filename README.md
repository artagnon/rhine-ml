# Rhine

Rhine is a dynamically typed Lisp-1 on LLVM. It intends to be a
language for a programmable editor and is a recursive acronym for
"Rhine is not Emacs". All values are boxed/ unboxed from a value_t
structure at runtime. The structure can represent the fundamental
types Int, String, and Array. Array is implemented as a const-size
array of value_t* in the IR; this is because LLVM does not support
arrays of variable size.

## Builtins

`+`, `-`, `*` work on N integers. `head` and `rest` work on
arrays. `str-split` works on a string, `str-join` works on an array of
strings.

## Building

`brew install llvm` and `opam install llvm` before invoking `make`.

## Notes

- LLVM codegen statements all have side-effects. In most places, order
  in which variables are codegen'ed are unimportant, and lets can be
  moved around; but in conditionals, statements must be codegen'ed
  exactly in order: this means let statements can't be permuted,
  leading to ugly imperative-style OCaml code.

- Since LLVM IR is strongly typed, it is possible to inspect the
  _types_ of llvales from OCaml at generation-time. However, there is
  no way for the codegen-stage to inspect the _values_ of variables
  while the program is running. This has the unfortunate consequence
  that a loop hinged upon an llvalue must be implemented in LLVM IR;
  hence, for functions that require iterating on variable-length
  arrays, we end up writing tedious LLVM IR generation code instead of
  an equivalent OCaml code.

- Debugging errors from LLVM bindings is hard. Using ocamldebug does
  not work, since the callstack leading up to an LLVM call in C++ is
  not owned by OCaml. The alternative is to use lldb, but matching up
  the C++ call with a line in the OCaml code is non-trivial.
