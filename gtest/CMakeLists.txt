include_directories("${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
add_library(gtest_main
  "${CMAKE_CURRENT_SOURCE_DIR}/src/gtest-all.cc"
  "${CMAKE_CURRENT_SOURCE_DIR}/src/gtest_main.cc")