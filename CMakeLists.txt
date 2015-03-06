cmake_minimum_required (VERSION 2.6)
project (Rhine)

set(CONFIG_OUTPUT)
find_program(LLVM_CONFIG "llvm-config")
if(LLVM_CONFIG)
  message(STATUS "Found LLVM_CONFIG as ${LLVM_CONFIG}")
  set(CONFIG_COMMAND ${LLVM_CONFIG}
    "--includedir"
    "--cxxflags"
    "--libdir")
  execute_process(
    COMMAND ${CONFIG_COMMAND}
    RESULT_VARIABLE HAD_ERROR
    OUTPUT_VARIABLE CONFIG_OUTPUT
    )
  if(NOT HAD_ERROR)
    string(REGEX REPLACE
      "[ \t]*[\r\n]+[ \t]*" ";"
      CONFIG_OUTPUT ${CONFIG_OUTPUT})
  else()
    string(REPLACE ";" " " CONFIG_COMMAND_STR "${CONFIG_COMMAND}")
    message(STATUS "${CONFIG_COMMAND_STR}")
    message(FATAL_ERROR "llvm-config failed with status ${HAD_ERROR}")
  endif()
else()
  message(FATAL_ERROR "llvm-config not found -- ${LLVM_CONFIG}")
endif()

list(GET CONFIG_OUTPUT 0 LLVM_INCLUDE_DIR)
list(GET CONFIG_OUTPUT 1 LLVM_CXX_FLAGS)
list(GET CONFIG_OUTPUT 2 LLVM_LIBDIR)

message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
include_directories(${LLVM_INCLUDE_DIR} "${PROJECT_SOURCE_DIR}/include")
link_directories(${LLVM_LIBDIR})
set(CMAKE_CXX_FLAGS ${LLVM_CXX_FLAGS})
add_subdirectory(Parse)
add_executable(Rhine
  "${PROJECT_SOURCE_DIR}/CodeGen.cpp"
  "${PROJECT_SOURCE_DIR}/IRBuilder.cpp"
  "${PROJECT_SOURCE_DIR}/TypeLowering.cpp")
target_link_libraries(Rhine
  Parse
  # System libs
  curses
  pthread
  z
  m
  # llvm-config --libs native mcjit
  LLVMMCJIT
  LLVMExecutionEngine
  LLVMRuntimeDyld
  LLVMX86Disassembler
  LLVMX86AsmParser
  LLVMX86CodeGen
  LLVMSelectionDAG
  LLVMAsmPrinter
  LLVMCodeGen
  LLVMTarget
  LLVMScalarOpts
  LLVMProfileData
  LLVMInstCombine
  LLVMTransformUtils
  LLVMipa
  LLVMAnalysis
  LLVMX86Desc
  LLVMObject
  LLVMMCParser
  LLVMBitReader
  LLVMMCDisassembler
  LLVMX86Info
  LLVMX86AsmPrinter
  LLVMMC
  LLVMX86Utils
  LLVMCore
  LLVMSupport)
