cmake_minimum_required (VERSION 2.6)
project (Rhine)
include_directories("${PROJECT_SOURCE_DIR}/include")
add_subdirectory(Parse)
add_executable(Rhine
  CodeGen.cpp
  IRBuilder.cpp
  TypeLowering.cpp)
target_link_libraries(Rhine Parse)
