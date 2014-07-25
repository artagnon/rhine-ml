OBJS = parser.cmo lexer.cmo main.cmo

rhine : $(OBJS)
	ocamlc -o rhine $(OBJS)
lexer.ml : lexer.mll
	ocamllex lexer.mll
parser.ml parser.mli : parser.mly
	ocamlyacc parser.mly
%.cmo : %.ml
	ocamlc -c $<
%.cmi : %.mli
	ocamlc -c $<
clean :
	rm -f rhine parser.ml parser.mli lexer.ml *.cmo *.cmi

lexer.cmo : parser.cmi
lexer.cmx : parser.cmx
main.cmo : parser.cmi lexer.cmo ast.cmi
main.cmx : parser.cmx lexer.cmx ast.cmi
parser.cmo : ast.cmi parser.cmi
parser.cmx : ast.cmi parser.cmi
ast.cmi :
parser.cmi : ast.cmi
