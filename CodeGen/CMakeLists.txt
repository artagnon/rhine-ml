include_directories("${PROJECT_SOURCE_DIR}/include")
find_package(LLVM REQUIRED native mcjit)
include_directories("${LLVM_INCLUDE_DIRS}")
link_directories(${LLVM_LIBRARY_DIRS})
add_library(CodeGen
  "${CMAKE_CURRENT_SOURCE_DIR}/CodeGen.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/IRBuilder.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/IR.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/Externals.cpp"
  "${PROJECT_SOURCE_DIR}/include/rhine/Externals.h"
  "${PROJECT_SOURCE_DIR}/include/rhine/Ast.h")
set_target_properties(CodeGen PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS ${LLVM_CXXFLAGS})
target_link_libraries(CodeGen
  ${LLVM_LDFLAGS}
  ${LLVM_LIBRARIES})
