OBJS = location.cmo ast_helper.cmo parser.cmo lexer.cmo pretty.cmo cookast.cmo \
	primops.cmo codegen.cmo mlunbox.cmo toplevel.cmo main.cmo bindings.o rgc.o
ocamlc = ocamlc -g 
llvm-config = llvm-build/bin/llvm-config
LLVMLIB = llvm-build/lib/ocaml/libllvm.a

rhine: export OCAMLPATH = llvm-build/lib/ocaml
rhine: export OCAMLPARAM = cclib=-Lllvm-build/lib,_
rhine: $(LLVMLIB) $(OBJS)
	ocamlfind $(ocamlc) -package llvm -package llvm.executionengine \
	-package llvm.analysis -package llvm.target -package llvm.scalar_opts \
	-package core -thread -package textutils -package bytes -linkpkg \
	$(OBJS) -o rhine
lexer.ml: lexer.mll
	ocamllex $<
parser.ml parser.mli: parser.mly
	menhir $<
codegen.cmo: codegen.ml
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
toplevel.cmo: toplevel.ml
	ocamlfind $(ocamlc) -c -package llvm -package llvm.executionengine \
	-package ctypes $<
location.cmo: location.ml
	ocamlfind $(ocamlc) -c -package core -thread -package textutils \
	 -package bytes $<
mlunbox.cmo: mlunbox.ml
	ocamlfind $(ocamlc) -c -package ctypes -linkpkg $<
%.cmo: %.ml
	$(ocamlc) -c $<
parsetree.cmi: parsetree.mli
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
%.cmi: %.mli
	$(ocamlc) -c $<
bindings.o: bindings.c
	clang -I`ocamlc -where` -c -o $@ $<
rgc.o: rgc.cpp
	clang++ `$(llvm-config) --cxxflags` -c -o $@ $<
$(LLVMLIB): llvm-build/Makefile
	$(MAKE) -C llvm-build -j8
llvm-build/Makefile: llvm/CMakeLists.txt
	mkdir -p llvm-build; cd llvm-build; cmake -DCMAKE_BUILD_TYPE=Debug ../llvm
llvm/CMakeLists.txt:
	git submodule update --init
test:
	./run_tests.py
clean:
	rm -f rhine parser.ml parser.mli lexer.ml *.o *.cmo *.cmi *.cmx
.PHONY: test clean

ast_helper.cmo : parsetree.cmi location.cmo
ast_helper.cmx : parsetree.cmi location.cmx
codegen.cmo : primops.cmo pretty.cmo parsetree.cmi
codegen.cmx : primops.cmx pretty.cmx parsetree.cmi
cookast.cmo : pretty.cmo parsetree.cmi ast.cmi
cookast.cmx : pretty.cmx parsetree.cmi ast.cmi
infer.cmo : ast.cmi
infer.cmx : ast.cmi
lexer.cmo : parser.cmi
lexer.cmx : parser.cmx
location.cmo :
location.cmx :
main.cmo : toplevel.cmo pretty.cmo parsetree.cmi parser.cmi lexer.cmo
main.cmx : toplevel.cmx pretty.cmx parsetree.cmi parser.cmx lexer.cmx
mlunbox.cmo : parsetree.cmi
mlunbox.cmx : parsetree.cmi
parser.cmo : parsetree.cmi location.cmo ast_helper.cmo parser.cmi
parser.cmx : parsetree.cmi location.cmx ast_helper.cmx parser.cmi
pretty.cmo : parsetree.cmi
pretty.cmx : parsetree.cmi
primops.cmo :
primops.cmx :
toplevel.cmo : pretty.cmo parsetree.cmi mlunbox.cmo cookast.cmo codegen.cmo
toplevel.cmx : pretty.cmx parsetree.cmi mlunbox.cmx cookast.cmx codegen.cmx
ast.cmi : parsetree.cmi
parser.cmi : parsetree.cmi
parsetree.cmi : location.cmo
