OBJS = location.cmo ast_helper.cmo parser.cmo lexer.cmo pretty.cmo cookast.cmo \
	primops.cmo codegen.cmo mlunbox.cmo toplevel.cmo main.cmo bindings.o rgc.o
ocamlc = ocamlc -g -w @5@8@10@11@12@14@23@24@26@29@40
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

ast_helper.cmo : location.cmo parsetree.cmi
ast_helper.cmx : location.cmx parsetree.cmi
codegen.cmo : pretty.cmo primops.cmo parsetree.cmi
codegen.cmx : pretty.cmx primops.cmx parsetree.cmi
cookast.cmo : pretty.cmo parsetree.cmi
cookast.cmx : pretty.cmx parsetree.cmi
lexer.cmo : parser.cmi
lexer.cmx : parser.cmx
location.cmo :
location.cmx :
main.cmo : toplevel.cmo pretty.cmo parser.cmi lexer.cmo parsetree.cmi
main.cmx : toplevel.cmx pretty.cmx parser.cmx lexer.cmx parsetree.cmi
mlunbox.cmo : parsetree.cmi
mlunbox.cmx : parsetree.cmi
primops.cmo :
primops.cmx :
parser.cmo : location.cmo ast_helper.cmo parsetree.cmi parser.cmi
parser.cmx : location.cmx ast_helper.cmx parsetree.cmi parser.cmi
pretty.cmo : parsetree.cmi
pretty.cmx : parsetree.cmi
toplevel.cmo : pretty.cmo mlunbox.cmo cookast.cmo codegen.cmo parsetree.cmi
toplevel.cmx : pretty.cmx mlunbox.cmx cookast.cmx codegen.cmx parsetree.cmi
parsetree.cmi : location.cmo
parser.cmi : parsetree.cmi
