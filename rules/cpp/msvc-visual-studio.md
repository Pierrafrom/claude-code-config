# MSVC / Visual Studio native profile — C++/CLI, WinForms, COM

Companion to `rules/cpp/build-architecture.md`'s "Toolchain routing"
section — read that first to confirm this file actually applies. This
profile is for a project that **cannot** be built by CMake + a portable
compiler (MinGW-w64/GCC/Clang), not a stylistic preference for MSVC.

## When this profile applies

- A `.sln`/`.vcxproj` already exists — typically a starter/skeleton
  provided by a course or a teammate. Never wrap it in a fresh CMake
  setup; MSBuild through the `.sln` is the build system, full stop.
- The project uses **C++/CLI** (`<CLRSupport>true</CLRSupport>` in the
  `.vcxproj`, `ref class`, `gcnew`, `^` handles, a WinForms `.resx` UI) —
  a Microsoft-only language extension. GCC/Clang/MinGW cannot compile
  this under any configuration; it is not a missing flag, it is an
  unimplemented language.
- The project needs COM interop or another hard MSVC/Windows-SDK-only
  dependency.

If none of these signals is present, stay on the portable profile —
don't reach for this one preemptively.

## Visual Studio setup

Reference config confirmed on Visual Studio Community 2026, 2026-09-01.

- Workload: **"Desktop development with C++"**, with the individual
  component **"C++/CLI support"** (`Microsoft.VisualStudio.Component.VC.CLI.Support`)
  checked — this is the one piece a default C++ workload install misses
  for a CLI/WinForms project.
- Modifying an existing VS install from the command line
  (`setup.exe modify --passive`) requires the process to already be
  elevated — a non-elevated `--passive`/`--quiet` call fails with exit
  code 5007 ("Commands with --quiet or --passive should be run elevated
  from the beginning"). From an unelevated shell, use the Visual Studio
  Installer GUI's "Modify" button instead — it handles its own UAC
  prompt.

## Shared style with the portable profile — same files, not a duplicate config

Point Visual Studio's **native** ClangFormat/clang-tidy integration at
the exact same `.clang-format`/`.clang-tidy` used by the portable
profile (`examples/.clang-format`, `examples/.clang-tidy`) — one style
source of truth regardless of which IDE opens the project:

- *Tools → Options → Text Editor → C/C++ → Formatting* → enable
  "Enable ClangFormat support", then set "Use custom clang-format.exe
  file" to the LLVM install already used by the portable profile's
  clangd (e.g. `C:\Program Files\LLVM\bin\clang-format.exe`).
- *Tools → Options → Text Editor → C/C++ → Code Style* → enable native
  clang-tidy the same way, pointed at the project's `.clang-tidy`.

**Known limitation, not a misconfiguration**: Clang's frontend does not
parse `/clr` syntax. clang-format will generally still format
CLI-flavored files reasonably (it's mostly token/brace-based), but
clang-tidy's checks will fail or silently skip any file using `ref
class`/`gcnew`/`^` (typically just the WinForms glue, e.g. `MainForm.cpp`/`.h`).
This is expected — apply clang-tidy's judgment to the plain-C++
algorithm files, not the UI glue.

## Debugging

Use Visual Studio's native debugger (`cppvsdbg`), not GDB/LLDB — it is
the only debugger that understands mixed managed/native (CLR) stack
frames. The GDB setup used by the portable profile's VS Code launch
config does not apply here.

## Editing in VS Code alongside Visual Studio

Reading/editing the plain-C++ files (anything with no `ref class`/`gcnew`)
in VS Code with clangd still works fine — those files are ordinary
standard C++. Expect clangd to show noisy false-positive diagnostics on
any file containing `/clr` syntax; that's cosmetic (clangd can't parse
it), not a real error — verify actual correctness by building in Visual
Studio, not by trusting clangd's squiggles on those specific files.

## Git hygiene — different artifacts than the CMake profile

`examples/.gitignore` is written for the CMake/vcpkg profile
(`build/`, `vcpkg_installed/`...) and doesn't cover MSBuild's output
layout. A project on this profile needs its own ignores instead:

```gitignore
# Visual Studio / MSBuild build artifacts
bin/
obj/
.vs/
*.user
*.suo
*.sdf
*.opensdf
ipch/
```

## Vendored dependencies

This profile has no vcpkg manifest to declare a dependency — a library
like Eigen is typically vendored by path (a folder referenced directly
in the `.vcxproj`'s include directories). If vendoring a header-only
library wholesale pulls in its own tests/benchmarks/docs/CI config
(often the bulk of its size), trim to just the headers actually
`#include`d before committing — e.g. for Eigen 3.x, keep `Eigen/` and
`unsupported/` (if used), drop `bench/`, `test/`, `doc/`, `ci/`,
`demos/`, `lapack/`, `blas/`, `failtest/`, `scripts/`, and the vendor's
own VCS metadata (`.gitlab-ci.yml`, `.hgeol`, etc.).
