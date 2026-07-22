# Reference CMakeLists.txt — level 1 project structure, see
# rules/cpp/build-architecture.md. Copy and adapt target/module names.
cmake_minimum_required(VERSION 3.25)
project(my_tool LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(ENABLE_SANITIZERS "Build with ASan + UBSan" OFF)

add_library(my_tool_lib src/widget.cpp)
target_include_directories(my_tool_lib PUBLIC include)
target_compile_options(my_tool_lib PRIVATE
  -Wall -Wextra -Wpedantic -Werror -Wshadow -Wconversion -Wsign-conversion
)
if(ENABLE_SANITIZERS)
  target_compile_options(my_tool_lib PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(my_tool_lib PRIVATE -fsanitize=address,undefined)
endif()

add_executable(my_tool src/main.cpp)
target_link_libraries(my_tool PRIVATE my_tool_lib)

enable_testing()
add_subdirectory(tests)
