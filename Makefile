OBJS = Parse/Lexer.o Parse/Parser.o CodeGen.o IRBuilder.o TypeLowering.o
HEADERS = include/rhine/Ast.h include/rhine/Support.h include/rhine/Lexer.h include/rhine/Parser.h
LLVM_CONFIG = llvm-build/bin/llvm-config --cxxflags
LLVM_CONFIG_LD = llvm-build/bin/llvm-config --cxxflags --system-libs --ldflags --libs
LLVMLIB = llvm-build/lib/libLLVMCore.a

rhine: $(LLVMLIB) $(OBJS)
	clang++ -g -O0 -L/usr/local/opt/flex/lib \
	-L/usr/local/opt/bison/lib `$(LLVM_CONFIG_LD) native mcjit` $(OBJS) -o $@
%.o: %.cpp $(HEADERS)
	clang++ -c -g -O0 -Iinclude `$(LLVM_CONFIG)` $<
CodeGen.o: CodeGen.cpp $(HEADERS)
	clang++ -c -g -O0 -Iinclude -IParse `$(LLVM_CONFIG)` $<
Parse/Parser.o: Parse/Parser.cpp Parse/Lexer.h Parse/Parser.h
	clang++ -c -g -O0 -Iinclude -Iinclude/rhine -IParse -I/usr/local/opt/flex/include -o $@ $<
Parse/Parser.cpp Parse/Parser.h: Parse/Parser.yy
	bison $<
Parse/Lexer.o: Parse/Lexer.cpp Parse/Lexer.h Parse/Parser.h
	clang++ -c -g -O0 -Iinclude -IParse -I/usr/local/opt/flex/include -o $@ $<
Parse/Lexer.cpp Parse/Lexer.h: Parse/Lexer.ll
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
