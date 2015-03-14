find_package(LLVM REQUIRED)
include_directories("${PROJECT_SOURCE_DIR}/include")
include_directories("${PROJECT_SOURCE_DIR}/gtest/include")
include_directories("${LLVM_INCLUDE_DIRS}")

add_executable(ToLLTest
  "${CMAKE_CURRENT_SOURCE_DIR}/ToLLTest.cpp")
set_target_properties(ToLLTest PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS ${LLVM_CXXFLAGS})
target_link_libraries(ToLLTest
  gtest_main
  CodeGen
  Toplevel)

add_executable(ParseTest
  "${CMAKE_CURRENT_SOURCE_DIR}/ParseTest.cpp")
set_target_properties(ParseTest PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS ${LLVM_CXXFLAGS})
target_link_libraries(ParseTest
  gtest_main
  CodeGen
  Toplevel)