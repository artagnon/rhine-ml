cmake_minimum_required (VERSION 2.6)
project (Rhine)

set(LLVM_ROOT_DIR "${PROJECT_SOURCE_DIR}/llvm")
set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/cmake/Modules")

include_directories("${PROJECT_SOURCE_DIR}/include")
add_subdirectory(Parse)
add_subdirectory(CodeGen)
add_subdirectory(Toplevel)
add_subdirectory(gtest)
add_subdirectory(unittest)
add_executable(rhine
  "${CMAKE_CURRENT_SOURCE_DIR}/Rhine.cpp"
  "${PROJECT_SOURCE_DIR}/include/rhine/Toplevel.h")
set_target_properties(rhine PROPERTIES
  COMPILE_FLAGS "-std=c++11")
target_link_libraries(rhine
  Toplevel)

add_custom_target(check
  COMMAND "${PROJECT_BINARY_DIR}/unittest/UnitTest"
  COMMENT "Running unittests ..."
  DEPENDS rhine)
