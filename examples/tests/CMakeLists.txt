# Reference tests/CMakeLists.txt — GoogleTest + CTest wiring, see
# rules/cpp/build-architecture.md. Adjust target/library names to match
# the parent CMakeLists.txt (currently my_tool_lib).
find_package(GTest CONFIG REQUIRED)

add_executable(my_tool_tests test_widget.cpp)
target_link_libraries(my_tool_tests PRIVATE GTest::gtest GTest::gtest_main my_tool_lib)

include(GoogleTest)
gtest_discover_tests(my_tool_tests)
