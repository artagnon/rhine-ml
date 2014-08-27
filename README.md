# Rhine

Rhine is a dynamically typed Lisp-1 on LLVM, inspired by Clojure. All
values are boxed/unboxed from a `value_t` structure at runtime:

```
%value_t = type {
	 i32,                                ; type of data
	 i64,                                ; integer
	 i1,                                 ; bool
	 i8*,                                ; string
	 %value_t**,                         ; array
	 i64,                                ; array/string length
	 double,                             ; double
	 %value_t* (i32, %value_t**, ...)*,  ; function
	 i8                                  ; char
}
```

Note that LLVM arrays and vectors cannot be used since they are
fixed-length. Instead, we have to malloc, getelementptr and store by
hand.

The function type is especially interesting: the first argument is the
number of arguments, and the second argument is the closure
environment (which has the same type as an array). It takes variable
number of arguments primarily to make the type uniform, so as to
implement first-class functions (function pointers).

Rhine does automatic type conversions, so `(+ 3 4.2)` will do the
right thing. To implement this, IR is generated to inspect the types
of the operands (first member of `value_t`), and a br is used to take
the right codepath.

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

- Implementing complex functions as builtins (by directly generating
  IR) is perhaps more efficient than implementing them in Rhine, but
  the gap is very small due to optimization passes applied on the
  Rhine-generated IR. The marginal benefit outweighs the cost of
  correctly weaving complex IR.
