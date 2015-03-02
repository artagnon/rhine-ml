cmake_minimum_required (VERSION 2.6)
project (Rhine)

set(LLVM_DIR "${PROJECT_SOURCE_DIR}/llvm/cmake/modules")
find_package(LLVM REQUIRED CONFIG)
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")
include_directories(${LLVM_INCLUDE_DIRS} "${PROJECT_SOURCE_DIR}/include")
add_definitions(${LLVM_DEFINITIONS})
llvm_map_components_to_libnames(llvm_libs native mcjit)

include_directories()
add_subdirectory(Parse)
add_executable(Rhine
  "${PROJECT_SOURCE_DIR}/CodeGen.cpp"
  "${PROJECT_SOURCE_DIR}/IRBuilder.cpp"
  "${PROJECT_SOURCE_DIR}/TypeLowering.cpp")
target_link_libraries(Rhine ${llvm_libs} Parse)
