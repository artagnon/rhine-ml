find_package(FLEX 2.5.39 REQUIRED)
find_package(BISON 3.0.2 REQUIRED)
include_directories("/usr/local/opt/flex/include")
flex_target(Lexx
  "${CMAKE_CURRENT_SOURCE_DIR}/Lexer.ll"
  "${CMAKE_CURRENT_BINARY_DIR}/Lexer.cpp")
bison_target(Parseyy
  "${CMAKE_CURRENT_SOURCE_DIR}/Parser.yy"
  "${CMAKE_CURRENT_BINARY_DIR}/Parser.cpp")
include_directories("${PROJECT_SOURCE_DIR}/include")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")
add_flex_bison_dependency(Lexx Parseyy)

find_package(LLVM REQUIRED native mcjit)
include_directories(${LLVM_INCLUDE_DIRS})
link_directories(${LLVM_LIBRARY_DIRS})
add_library(Parse
  ${FLEX_Lexx_OUTPUTS}
  ${BISON_Parseyy_OUTPUTS}
  "${CMAKE_CURRENT_SOURCE_DIR}/ParseDriver.cpp")
set_target_properties(Parse PROPERTIES
  LINKER_LANGUAGE CXX
  COMPILE_FLAGS "${LLVM_CXXFLAGS} -Wno-deprecated-register -Wno-sign-compare")