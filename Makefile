OBJS = parser.cmo main.cmo lexer.cmo

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
	rm -f rhine parser.ml parser.mli scanner.ml *.cmo *.cmi
