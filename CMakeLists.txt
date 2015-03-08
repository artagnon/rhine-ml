cmake_minimum_required (VERSION 2.6)
project (Rhine)

set(LLVM_ROOT_DIR "${PROJECT_SOURCE_DIR}/llvm")
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

include_directories("${PROJECT_SOURCE_DIR}/include")
SET(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11")
add_subdirectory(Parse)
add_subdirectory(CodeGen)
add_subdirectory(gtest)
add_subdirectory(unittest)
add_executable(Rhine
  "${PROJECT_SOURCE_DIR}/Rhine.cpp")
target_link_libraries(Rhine
  Parse
  CodeGen)
