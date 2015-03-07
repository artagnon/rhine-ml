cmake_minimum_required (VERSION 2.6)
project (Rhine)

set(LLVM_ROOT_DIR "${PROJECT_SOURCE_DIR}/llvm")
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")
message(STATUS "${CMAKE_MODULE_PATH}")
find_package(LLVM REQUIRED native mcjit)
include_directories(${LLVM_INCLUDE_DIRS} "${PROJECT_SOURCE_DIR}/include")
link_directories(${LLVM_LIBRARY_DIRS})
add_subdirectory(Parse)
add_executable(Rhine
  "${PROJECT_SOURCE_DIR}/CodeGen.cpp"
  "${PROJECT_SOURCE_DIR}/IRBuilder.cpp"
  "${PROJECT_SOURCE_DIR}/TypeLowering.cpp")
set_target_properties(Rhine PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS ${LLVM_CXXFLAGS})
target_link_libraries(Rhine
  Parse
  ${LLVM_LDFLAGS}
  ${LLVM_LIBRARIES})
