include(FindFLEX)
include(FindBISON)
include_directories("/usr/local/opt/flex/include")
flex_target(Lexx
  "${PROJECT_SOURCE_DIR}/Parse/Lexer.ll"
  "${PROJECT_BINARY_DIR}/Parse/Lexer.cpp")
bison_target(Parseyy
  "${PROJECT_SOURCE_DIR}/Parse/Parser.yy"
  "${PROJECT_BINARY_DIR}/Parse/Parser.cpp")
include_directories("${PROJECT_SOURCE_DIR}/include")
include_directories("${PROJECT_BINARY_DIR}/Parse")
add_flex_bison_dependency(Lexx Parseyy)
add_library(Parse
  ${FLEX_Lexx_OUTPUTS}
  ${BISON_Parseyy_OUTPUTS}
  "${PROJECT_SOURCE_DIR}/Parse/ParseDriver.cpp")