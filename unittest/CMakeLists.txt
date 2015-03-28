find_package(LLVM REQUIRED)
include_directories("${PROJECT_SOURCE_DIR}/include")
include_directories("${PROJECT_SOURCE_DIR}/gtest/include")
include_directories("${LLVM_INCLUDE_DIRS}")

add_executable(UnitTest
  "${CMAKE_CURRENT_SOURCE_DIR}/CodeGenTest.cpp"
  "${CMAKE_CURRENT_SOURCE_DIR}/IRTest.cpp")
set_target_properties(UnitTest PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS ${LLVM_CXXFLAGS})
target_link_libraries(UnitTest
  gtest_main
  CodeGen
  Toplevel)