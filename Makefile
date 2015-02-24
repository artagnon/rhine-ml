OBJS = Parser/Lexer.o CodeGen.o IRBuilder.o TypeLowering.o
HEADERS = include/rhine/Ast.h include/rhine/Support.h include/rhine/Lexer.h include/rhine/Parser.h
LLVM_CONFIG = llvm-build/bin/llvm-config --cxxflags
LLVM_CONFIG_LD = llvm-build/bin/llvm-config --cxxflags --system-libs --ldflags --libs
LLVMLIB = llvm-build/lib/libLLVMCore.a

rhine: $(LLVMLIB) $(OBJS)
	clang++ -g -O0 -ll `$(LLVM_CONFIG_LD) native mcjit` $(OBJS) -o $@
%.o: %.cpp $(HEADERS)
	clang++ -c -g -O0 -Iinclude `$(LLVM_CONFIG)` $<
CodeGen.o: CodeGen.cpp $(HEADERS)
	clang++ -c -g -O0 -Iinclude -IParser `$(LLVM_CONFIG)` $<
Parser/Parser.o: Parser/Parser.cpp Parser/Lexer.h Parser/Parser.h
	clang -c -g -O0 -Iinclude -o $@ $<
Parser/Parser.cpp Parser/Parser.h: Parser/Parser.yy
	bison $<
Parser/Lexer.o: Parser/Lexer.cpp Parser/Lexer.h Parser/Parser.h
	clang -c -g -O0 -Iinclude -IParser -o $@ $<
Parser/Lexer.cpp Parser/Lexer.h: Parser/Lexer.ll
	flex $<
$(LLVMLIB): llvm-build/Makefile
	$(MAKE) -C llvm-build -j8
llvm-build/Makefile: llvm/CMakeLists.txt
	mkdir -p llvm-build; cd llvm-build; cmake -DCMAKE_BUILD_TYPE=Debug ../llvm
llvm/CMakeLists.txt:
	git submodule update --init
test:
	./run_tests.py
clean:
	rm -f rhine $(OBJS)
.PHONY: test clean
