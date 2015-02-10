OBJS = codegen.o
LLVM_CONFIG = llvm-build/bin/llvm-config --cxxflags
LLVM_CONFIG_LD = llvm-build/bin/llvm-config --cxxflags --system-libs --ldflags --libs
LLVMLIB = llvm-build/lib/libLLVMCore.a

rhine: $(LLVMLIB) $(OBJS)
	clang++ -g -O1 `$(LLVM_CONFIG_LD) native mcjit` $(OBJS) -o $@
codegen.o: codegen.cpp
	clang++ -c -g -O1 `$(LLVM_CONFIG)` $<
test:
	./run_tests.py
clean:
	rm -f rhine $(OBJS)
.PHONY: test clean
