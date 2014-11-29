OBJS = location.cmo ast_helper.cmo parser.cmo lexer.cmo pretty.cmo cookast.cmo codegen.cmo mlunbox.cmo toplevel.cmo main.cmo bindings.o rgc.o rgc_printer.o
ocamlc = ocamlc -g -w @5@8@10@11@12@14@23@24@26@29@40

rhine: export OCAMLPATH = ./llvm/Debug+Asserts/lib/ocaml
rhine: $(OBJS)
	ocamlfind $(ocamlc) -package llvm -package llvm.executionengine \
	-package llvm.analysis -package llvm.target -package llvm.scalar_opts \
	-package core -thread -package textutils -package bytes \
	-linkpkg $(OBJS) -o rhine
lexer.ml: lexer.mll
	ocamllex lexer.mll
parser.ml parser.mli: parser.mly
	menhir parser.mly
codegen.cmo: codegen.ml
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
toplevel.cmo: toplevel.ml
	ocamlfind $(ocamlc) -c -package llvm -package llvm.executionengine \
	-package ctypes $<
location.cmo: location.ml
	ocamlfind $(ocamlc) -c -package core -thread -package textutils \
	 -package bytes $<
%.cmo: %.ml
	$(ocamlc) -c $<
ast.cmi: ast.mli
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
%.cmi: %.mli
	$(ocamlc) -c $<
bindings.o: bindings.c
	clang -I`ocamlc -where` -c -o $@ $<
rgc.o: rgc.cc
	clang++ `llvm-config --cxxflags` -c -o $@ $<
rgc_printer.o: rgc_printer.cc
	clang++ `llvm-config --cxxflags` -c -o $@ $<
clean:
	rm -f rhine parser.ml parser.mli lexer.ml *.o *.cmo *.cmi *.cmx

ast_helper.cmo : location.cmo ast.cmi
ast_helper.cmx : location.cmx ast.cmi
codegen.cmo : pretty.cmo ast.cmi
codegen.cmx : pretty.cmx ast.cmi
cookast.cmo : pretty.cmo ast.cmi
cookast.cmx : pretty.cmx ast.cmi
location.cmo :
location.cmx :
main.cmo : toplevel.cmo pretty.cmo parser.cmi ast.cmi
main.cmx : toplevel.cmx pretty.cmx parser.cmx ast.cmi
mlunbox.cmo : ast.cmi
mlunbox.cmx : ast.cmi
parser.cmo : location.cmo ast_helper.cmo ast.cmi parser.cmi
parser.cmx : location.cmx ast_helper.cmx ast.cmi parser.cmi
pretty.cmo : ast.cmi
pretty.cmx : ast.cmi
toplevel.cmo : pretty.cmo mlunbox.cmo cookast.cmo codegen.cmo ast.cmi
toplevel.cmx : pretty.cmx mlunbox.cmx cookast.cmx codegen.cmx ast.cmi
ast.cmi : location.cmo
parser.cmi : ast.cmi
