OBJS = CodeGen.o IRBuilder.o TypeLowering.o
HEADERS = include/rhine/Type.h include/rhine/Ast.h include/rhine/Support.h
LLVM_CONFIG = llvm-build/bin/llvm-config --cxxflags
LLVM_CONFIG_LD = llvm-build/bin/llvm-config --cxxflags --system-libs --ldflags --libs
LLVMLIB = llvm-build/lib/libLLVMCore.a

rhine: $(LLVMLIB) $(OBJS)
	clang++ -g -O1 `$(LLVM_CONFIG_LD) native mcjit` $(OBJS) -o $@
%.o: %.cpp $(HEADERS)
	clang++ -c -g -O1 -I./include `$(LLVM_CONFIG)` $<
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
