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
