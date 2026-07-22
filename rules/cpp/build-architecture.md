# C/C++ build & project structure — CMake, vcpkg, sanitizers, tests

See `rules/common/project-architectures.md` for the governing rule: pick
the level matching the project's actual size today, same YAGNI posture
as `rules/python/fastapi-architecture.md`'s three levels. Shared between
C and C++ projects — the idiom files (`rules/cpp/cpp-patterns.md`,
`rules/cpp/c-patterns.md`) diverge, the build tooling doesn't.

## Build system: CMake, no alternative considered by default

CMake is the de facto standard for C/C++ — cross-platform, the only
build system with first-class IDE/tooling support (CLion, VS Code
CMake Tools, Visual Studio) and native `vcpkg`/`Conan`/`CTest`
integration. Not a decision to revisit per project.

## Package manager: vcpkg, manifest mode

- **Manifest mode** (a `vcpkg.json` at the project root) is the
  equivalent of `uv`'s `pyproject.toml`/`uv.lock` or `pnpm`'s
  `package.json`/lockfile — declares dependencies once, `vcpkg install`
  (triggered automatically by the CMake toolchain file) resolves and
  builds them into an isolated, project-local install tree. Same
  dependency-isolation principle as `rules/common/coding-style.md` —
  never a project dependency installed system-wide (`apt install
  libfoo-dev` for a project dependency is the C/C++ equivalent of a bare
  `pip install` outside a venv).
- Wire it via `CMAKE_TOOLCHAIN_FILE` pointing at
  `$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake` — must be set **before**
  the first `project()` call, since the toolchain file is evaluated at
  that point.
- Prefer setting this through `CMakePresets.json` (see below) over
  passing `-DCMAKE_TOOLCHAIN_FILE=...` by hand on every `cmake` invocation
  — the modern, reproducible way to wire vcpkg in, and it doubles as the
  place to declare the sanitizer-enabled test preset.

```json
// vcpkg.json — manifest mode, project root
{
  "name": "my-project",
  "version": "0.1.0",
  "dependencies": [
    "gtest",
    "spdlog"
  ]
}
```

## `CMakePresets.json` — reproducible configure/build/test

```jsonc
// CMakePresets.json
// Base: cmake.org/cmake/help/latest/manual/cmake-presets.7.html
{
  "version": 6,
  "configurePresets": [
    {
      "name": "default",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_TOOLCHAIN_FILE": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "sanitized",
      "inherits": "default",
      "binaryDir": "${sourceDir}/build-sanitized",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "ENABLE_SANITIZERS": "ON"
      }
    }
  ],
  "buildPresets": [
    { "name": "default", "configurePreset": "default" },
    { "name": "sanitized", "configurePreset": "sanitized" }
  ],
  "testPresets": [
    { "name": "sanitized", "configurePreset": "sanitized", "output": { "outputOnFailure": true } }
  ]
}
```

`CMAKE_EXPORT_COMPILE_COMMANDS` generates `compile_commands.json`, which
`clang-tidy` needs to analyze the project correctly (see
`rules/cpp/lint-strict.md`'s pre-commit hook, which reads it via `-p build`).

## Warnings and sanitizers — wired once in `CMakeLists.txt`

```cmake
# CMakeLists.txt (excerpt)
target_compile_options(my_target PRIVATE
  -Wall -Wextra -Wpedantic -Werror -Wshadow -Wconversion -Wsign-conversion
)

option(ENABLE_SANITIZERS "Build with ASan + UBSan" OFF)
if(ENABLE_SANITIZERS)
  target_compile_options(my_target PRIVATE -fsanitize=address,undefined -fno-omit-frame-pointer)
  target_link_options(my_target PRIVATE -fsanitize=address,undefined)
endif()
```

`ENABLE_SANITIZERS` is driven by the `sanitized` preset above, not a flag
developers remember to pass by hand — the whole point of
`rules/cpp/lint-strict.md`'s "sanitizers are mandatory in test builds,
not opt-in" rule is that CI always builds and runs the `sanitized`
preset, never only the plain `default` one.

## Testing: GoogleTest + CTest

```cmake
# CMakeLists.txt (excerpt) — GoogleTest via vcpkg, not FetchContent:
# keeps the dependency in the same manifest-managed, version-pinned tree
# as every other dependency instead of a separate ad hoc fetch mechanism.
find_package(GTest CONFIG REQUIRED)
enable_testing()

add_executable(my_tests test_widget.cpp)
target_link_libraries(my_tests PRIVATE GTest::gtest GTest::gtest_main my_lib)

include(GoogleTest)
gtest_discover_tests(my_tests)
```

`ctest --preset sanitized` then runs the full suite under
ASan/UBSan — this is the CI gate referenced in `rules/cpp/lint-strict.md`.

## Project structure by complexity level

### Level 1 — small tool / single library (default starting point)

```
my-tool/
├── CMakeLists.txt
├── CMakePresets.json
├── vcpkg.json
├── .clang-format
├── .clang-tidy
├── .pre-commit-config.yaml
├── include/
│   └── my_tool/
│       └── widget.h
├── src/
│   ├── main.cpp
│   └── widget.cpp
├── tests/
│   ├── CMakeLists.txt
│   └── test_widget.cpp
└── docs/
```

### Level 2 — larger application, multiple internal modules

Justified once a single `src/`/`include/` pair no longer reflects the
project's real internal boundaries (several independent components, a
public API vs internal implementation split worth enforcing at the
build-target level, not just the folder level).

```
my-app/
├── CMakeLists.txt              # top-level: add_subdirectory per module
├── CMakePresets.json
├── vcpkg.json
├── cmake/                       # shared CMake helper modules
│   └── CompilerWarnings.cmake
├── modules/
│   ├── core/
│   │   ├── CMakeLists.txt       # defines the `core` target
│   │   ├── include/core/
│   │   └── src/
│   ├── networking/
│   │   ├── CMakeLists.txt
│   │   ├── include/networking/
│   │   └── src/
│   └── app/
│       ├── CMakeLists.txt       # depends on core + networking, builds the binary
│       └── src/main.cpp
├── tests/
│   ├── core/
│   └── networking/
└── docs/
```

Each module is its own CMake target with an explicit
`target_link_libraries` dependency graph — the same "colocation rule"
and "changing one feature shouldn't touch 5 unrelated folders" principle
from `rules/common/project-architectures.md`, instantiated as CMake
targets instead of Next.js route folders or FastAPI feature packages.

## Rules specific to this structure

- Public headers live under `include/<project-name>/` (namespaced by
  project name) so an installed/exported library doesn't collide with
  another project's headers — private headers stay next to their `.cpp`
  in `src/`.
- `tests/` mirrors the module layout it tests, same convention as the
  Python/TS test-layout rules elsewhere in this config.
- `cmake/` holds reusable CMake modules (warning flag sets, sanitizer
  wiring) shared across targets — same "no duplicated config" principle
  as `rules/common/repo-structure.md`, instantiated for CMake instead of
  `pyproject.toml`.
