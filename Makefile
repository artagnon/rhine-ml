OBJS = parser.cmo lexer.cmo pretty.cmo cookast.cmo codegen.cmo toplevel.cmo main.cmo bindings.o
ocamlc = ocamlc -g -w @5@8@10@11@12@14@23@24@26@29@40

rhine : $(OBJS)
	ocamlfind $(ocamlc) -package llvm -package llvm.executionengine -package llvm.analysis -package llvm.target -package llvm.scalar_opts -linkpkg $(OBJS) -o rhine
lexer.ml : lexer.mll
	ocamllex lexer.mll
parser.ml parser.mli : parser.mly
	ocamlyacc parser.mly
codegen.cmo: codegen.ml
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
toplevel.cmo: toplevel.ml
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
%.cmo : %.ml
	$(ocamlc) -c $<
ast.cmi: ast.mli
	ocamlfind $(ocamlc) -c -package llvm -linkpkg $<
%.cmi : %.mli
	$(ocamlc) -c $<
%.o   : %.c
	cc -I`ocamlc -where` -c -o $@ $<
clean :
	rm -f rhine parser.ml parser.mli lexer.ml *.o *.cmo *.cmi *.cmx

codegen.cmo : ast.cmi
codegen.cmx : ast.cmi
cookast.cmo : pretty.cmo ast.cmi
cookast.cmx : pretty.cmx ast.cmi
lexer.cmo : parser.cmi
lexer.cmx : parser.cmx
main.cmo : toplevel.cmo pretty.cmo parser.cmi lexer.cmo ast.cmi
main.cmx : toplevel.cmx pretty.cmx parser.cmx lexer.cmx ast.cmi
parser.cmo : ast.cmi parser.cmi
parser.cmx : ast.cmi parser.cmi
pretty.cmo : ast.cmi
pretty.cmx : ast.cmi
toplevel.cmo : cookast.cmo codegen.cmo ast.cmi
toplevel.cmx : cookast.cmx codegen.cmx ast.cmi
ast.cmi :
parser.cmi : ast.cmi
