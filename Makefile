OBJS = parser.cmo lexer.cmo codegen.cmo main.cmo

rhine : $(OBJS)
	ocamlfind ocamlc -package llvm -linkpkg $(OBJS) -o rhine
lexer.ml : lexer.mll
	ocamllex lexer.mll
parser.ml parser.mli : parser.mly
	ocamlyacc parser.mly
codegen.cmo: codegen.ml
	ocamlfind ocamlc -c -package llvm -linkpkg codegen.ml
%.cmo : %.ml
	ocamlc -c $<
%.cmi : %.mli
	ocamlc -c $<
clean :
	rm -f rhine parser.ml parser.mli lexer.ml *.cmo *.cmi *.cmx

codegen.cmo : ast.cmi
codegen.cmx : ast.cmi
lexer.cmo : parser.cmi
lexer.cmx : parser.cmx
main.cmo : parser.cmi lexer.cmo ast.cmi
main.cmx : parser.cmx lexer.cmx ast.cmi
parser.cmo : ast.cmi parser.cmi
parser.cmx : ast.cmi parser.cmi
ast.cmi :
parser.cmi : ast.cmi
