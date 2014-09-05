# Rhine

Rhine is a Clojure-inspired Lisp on LLVM JIT featuring variable-length
untyped arrays, first-class functions, closures, and macros. While
Clojure hides the lower-level details by running atop the JVM, Rhine
aims to expose how common Lisp constructs map to hardware.

## Building

`brew install llvm` and `opam install llvm` before invoking `make`.

## How it works

An untyped system means that all values are boxed/unboxed from a
`value_t` structure at runtime:

```llvm
%value_t = type {
	 i32,                                ; type of data
	 i64,                                ; integer
	 i1,                                 ; bool
	 i8*,                                ; string
	 %value_t**,                         ; array/fenv
	 i64,                                ; array/string length
	 double,                             ; double
	 %value_t* (i32, %value_t**, ...)*,  ; function
	 i8                                  ; char
}
```

The overhead of boxing/unboxing is paid by all dynamic languages,
although multiple optimizations (including speculative optimization)
can reduce the overhead. Rhine currently only implements the basic
optimizations bundled with LLVM.

Rhine does automatic type conversions, so `(+ 3 4.2)` will do the
right thing. To implement this, IR is generated to inspect the types
of the operands (zeroth member of `value_t`), and a br (branch) is
used to take the right codepath. A possible optimization is to
generate a branchless codepath for all-integer arguments.

LLVM provides the [array
type](http://llvm.org/docs/LangRef.html#array-type) and [vector
type](http://llvm.org/docs/LangRef.html#vector-type). They cannot be
used since they are fixed-length; i.e. the length must be known at
compile-time. The problem is that a construct like `(cons 8 coll)`
generates a runtime length which is equal to the `(length coll)` + 1.
So, we malloc, getelementptr, and store by hand. It has the type
specified by the fourth member of `value_t`.

To implement first-class functions, note that all functions must have
the same type; i.e. the type of the function pointer (the seventh
member of `value_t`). How else would you implement:

```clojure
(defn map
  [f coll]
  (if (not (= [] coll))
    (cons (f (first coll))
          (map f (rest coll)))
    []))

(defn map2
  [f c1 c2]
  (if (not (or (= [] c1) (= [] c2)))
    (cons (f (first c1) (first c2))
          (map2 f (rest c1) (rest c2)))
    []))

```

Here, `f` takes one argument in `map`, but takes two arguments in
`map2`. A function pointer type embracing variable arguments is
implemented using the [varargs
framework](http://llvm.org/docs/LangRef.html#variable-argument-handling-intrinsics)
of LLVM. Note that `va_arg` doesn't work on x86, so Rhine extracts the
values by hand. The first argument gives the number of arguments, and
this can be used to implement varargs in the Rhine language. The
second argument is the closure environment (which has the same type as
an array).

Closures are simple to implement with this framework in place. First,
when a function is declared, parse out all the unbound variable names
(not present in arguments or `let`), sort the names, put it in a
hashtable for later reference, and codegen the code required to bind
the names from the `env` argument in order. At the callsite, look up
this hashtable, and pack all the corresponding environment variables
into the `env` argument. So, stuff like this will work:

```clojure
(defn quux [] (let [a aenv] (println a) (println env)))
(let [env 12 aenv 17] (quux))
```

But there's a problem because we have first-class functions. What
happens to this?

```clojure
(defn t [y] (+ x y))
(defn f [x] t)
(let [g (f 3)] (println (g 4)))
```

Here, the callsite for `t` is not in `f`, but in the anonymous
function at the end. But the anonymous function doesn't have the
environment variable `x` that `t` requires, `f` does. So, we have to
augment function pointers with the environment (resuing the fourth
argument of `value_t`).

It's important to realize that macros require that we go
back-and-fourth between LLVM values and the OCaml codegen engine. How
else would you evaluate something like:

```clojure
(defmacro baz [x]
  `[1 2 ~x])
(baz (+ 2 2))
```

Note that macro arguments must be passed unevaluated at the
callsite. The maco-expand stage now needs to codegen `[1 2
<something>]`, where that `<something>` itself needs to be codegen'ed
by evaluating the argument: the result from the compiler must be
returned as an AST object to OCaml. This requires some involved
construction of OCaml objects from C.

Another subtle point to note is that macros must be lifted out of the
program and macro-expanded at the beginning of the program. This is
because we can't suddenly codegen segments required for macroexpansion
in the middle of codegen'ing another function.

## Todo

- Variable number of arguments for functions using `&rest`
  notation. This should be relatively straightforward.

- Lambdas. Requires lifting them out and codegen'ing them first.

- Garbage collection. LLVM provides several garbage collection
  intrinsincs, but the main challenge is to make sure that the C
  bindings don't leak memory.

- Custom optimizations.

- Lots of little language features to turn it into a real usable
  language.

## Notes

- LLVM codegen statements all have side-effects. In most places, order
  in which variables are codegen'ed are unimportant, and lets can be
  moved around; but in conditionals, statements must be codegen'ed
  exactly in order: this means let statements can't be permuted,
  leading to imperative-style OCaml code.

- Since LLVM IR is strongly typed, it is possible to inspect the
  _types_ of llvales from OCaml at generation-time. However, there is
  no way for the codegen-stage to inspect the _values_ of variables
  while the program is running. This has the consequence that a loop
  hinged upon an llvalue must be implemented in LLVM IR; hence, for
  functions that require iterating on variable-length arrays, we end
  up writing tedious LLVM IR generation code instead of an equivalent
  OCaml code.

- Debugging errors from LLVM bindings is hard. Using ocamldebug does
  not work, since the callstack leading up to an LLVM call in C++ is
  not owned by OCaml. The alternative is to use lldb, but matching up
  the C++ call with a line in the OCaml code is non-trivial.

- Implementing complex functions as builtins (by directly generating
  IR) is perhaps more efficient than implementing them in Rhine, but
  the gap is very small due to optimization passes applied on the
  Rhine-generated IR. The marginal benefit outweighs the cost of
  correctly weaving complex IR.
