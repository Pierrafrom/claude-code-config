# C/C++ lint & static analysis — STRICT level

Shared tooling for both `rules/cpp/cpp-patterns.md` (C++) and
`rules/cpp/c-patterns.md` (C) — the idioms diverge by language, the
tooling doesn't. See `rules/common/config-standards.md` for the general
"extend an official baseline, don't hand-pick from scratch" principle
this file follows, same posture as `rules/python/lint-strict.md` and
`rules/typescript/lint-strict.md`.

## Toolchain: clang-format + clang-tidy + cppcheck

- **`clang-format`**: formatting only (indentation, braces, line length,
  include sorting). Mechanical, zero judgment calls once configured.
- **`clang-tidy`**: the main static-analysis/lint tool — bug patterns,
  Core Guidelines violations, readability, performance, and
  modernization checks, plus naming enforcement (see below). Unlike
  ruff/eslint, clang-tidy has no single official "recommended" preset —
  the equivalent discipline is to explicitly extend a known check-family
  list rather than hand-picking individual checks one by one.
- **`cppcheck`**: a second, independent static analyzer — different
  detection engine than clang-tidy's, catches a partially overlapping
  but distinct set of issues (particularly around unused code paths and
  certain classes of undefined behavior). Run both; they're
  complementary, not redundant.

## `.clang-format` — extend a named base style

```yaml
# .clang-format
# Base: clang.llvm.org/docs/ClangFormatStyleOptions.html — BasedOnStyle: Google
# Re-check before trusting on a clang-format major version bump.
BasedOnStyle: Google
ColumnLimit: 100
IndentWidth: 4
AccessModifierOffset: -2
IncludeBlocks: Regroup
IncludeCategories:
  - Regex: '^<(gtest|gmock)/'
    Priority: 5
  - Regex: '^<[a-z_]+\.h>'        # C standard library
    Priority: 1
  - Regex: '^<'                    # other system/third-party headers
    Priority: 2
  - Regex: '^"'                    # project headers
    Priority: 3
```

`IncludeCategories` sorts std headers, third-party headers, and project
headers into separate groups automatically — same "std → third-party →
project" convention already enforced for TS/JS imports in
`rules/typescript/lint-strict.md`.

## `.clang-tidy` — extend explicit check families, never hand-pick single checks

```yaml
# .clang-tidy
# Base: clang.llvm.org/extra/clang-tidy/checks/list.html — check families,
# not a single official preset (unlike ruff/eslint). Re-verify the family
# list against a fresh LLVM release before trusting an older copy.
Checks: >
  -*,
  bugprone-*,
  cppcoreguidelines-*,
  performance-*,
  modernize-*,
  readability-*,
  cert-*,
  -modernize-use-trailing-return-type,
  -readability-identifier-length

WarningsAsErrors: '*'

CheckOptions:
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.StructCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: lower_case
  - key: readability-identifier-naming.VariableCase
    value: lower_case
  - key: readability-identifier-naming.PrivateMemberPrefix
    value: m_
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
  - key: readability-identifier-naming.MacroDefinitionCase
    value: UPPER_CASE
  - key: cppcoreguidelines-avoid-do-while.IgnoreMacros
    value: true
```

- `bugprone-*` / `cppcoreguidelines-*` / `performance-*` / `readability-*`
  / `modernize-*`: the standard combination — matches the family list
  `rules/cpp/cpp-patterns.md` and `c-patterns.md` already assume when
  they mention "clang-tidy catches this."
- `cert-*`: the free CERT C/C++ subset clang-tidy implements — see
  `rules/cpp/c-patterns.md`'s MISRA/CERT section for when this matters.
- `readability-identifier-naming.*`: the mechanical enforcement of the
  naming convention fixed in `rules/cpp/cpp-patterns.md` and
  `c-patterns.md` — this is clang-tidy's equivalent of ruff's `N`
  (pep8-naming) category.
- `WarningsAsErrors: '*'`: every enabled check is a hard error, not a
  suggestion — same "zero tolerance on warnings" bar as
  `rules/python/lint-strict.md` and `rules/typescript/lint-strict.md`.
- Two checks disabled by default above (`modernize-use-trailing-return-type`,
  `readability-identifier-length`) are pure style preferences that
  conflict with this config's own naming/formatting choices — document
  any further disable the same way, with a one-line reason, never a bare
  suppression.

## Compiler warning flags — the first line of defense

Independent of clang-tidy, the compiler's own warnings must be on and
treated as errors, wired once in CMake (see
`rules/cpp/build-architecture.md` for the actual `CMakeLists.txt`
snippet):

```
-Wall -Wextra -Wpedantic -Werror -Wshadow -Wconversion -Wsign-conversion
```

## Sanitizers — mandatory in test builds, not opt-in

`clang-tidy` and `cppcheck` are static analysis — they can't catch a
real use-after-free or data race at runtime. AddressSanitizer and
UndefinedBehaviorSanitizer must run as part of the test build, same
non-negotiable bar as `mypy --strict` for Python:

- `-fsanitize=address` — catches use-after-free, buffer overflow,
  double-free.
- `-fsanitize=undefined` — catches signed overflow, misaligned access,
  null-pointer UB, and other undefined-behavior classes the compiler
  won't otherwise flag.
- Valgrind as a complementary, slower deep check when a sanitizer build
  isn't available for the target platform.

See `rules/cpp/build-architecture.md` for wiring these into a CMake
preset rather than passing the flags by hand.

## CI policy — blocking from day one, no legacy carve-out

This config's default context is new projects scaffolded via
`init-project` — there is no pre-existing technical debt to protect CI
from. Unlike the common industry advice to make `clang-tidy` blocking
"only on new files" when adopting it into a legacy codebase,
**`clang-tidy`, `cppcheck`, and the sanitizer test run are all full,
project-wide CI gates from the first commit** — same posture as
`ruff check .` being a hard gate for Python, not a report-only step. If
this config is ever pointed at an existing legacy C/C++ codebase with
real accumulated debt, the "new files only" leniency is the documented
industry fallback — flag that context explicitly rather than silently
softening the gate.

## Pre-commit — always present, mirrors the Python/TS baseline

Add to the project's `.pre-commit-config.yaml` (see
`examples/.pre-commit-config.yaml` and
`rules/common/repo-structure.md`'s "always present" rule):

```yaml
  - repo: https://github.com/pre-commit/mirrors-clang-format
    rev: v0.0.0  # placeholder — run `pre-commit autoupdate`
    hooks:
      - id: clang-format

  # Local hook, not a pre-commit mirror: clang-tidy needs the project's
  # real compile_commands.json (include paths, defines) to analyze
  # correctly — a mirror running in an isolated environment can't see
  # the actual build configuration. Same rationale as the local mypy
  # hook in examples/.pre-commit-config.yaml.
  - repo: local
    hooks:
      - id: clang-tidy
        name: clang-tidy
        entry: clang-tidy -p build --warnings-as-errors='*'
        language: system
        types_or: [c, c++]
      - id: cppcheck
        name: cppcheck
        entry: cppcheck --enable=all --error-exitcode=1 --suppress=missingIncludeSystem
        language: system
        types_or: [c, c++]
```

## Sources to watch (best-practice drift)

| Domain | Canonical source | Change signal |
|---|---|---|
| `clang-format` options | clang.llvm.org/docs/ClangFormatStyleOptions.html | LLVM release notes on major version bumps |
| `clang-tidy` checks | clang.llvm.org/extra/clang-tidy/checks/list.html | Same LLVM release notes — check families/options do change |
| C++ Core Guidelines | isocpp.github.io/CppCoreGuidelines | Ongoing revisions, watch for new/retired guidelines |
| SEI CERT C/C++ | wiki.sei.cmu.edu/confluence/display/c and /cplusplus | CERT wiki revision history |
| Compiler C++ standard support | clang.llvm.org/cxx_status.html, devblogs.microsoft.com/cppblog | Per-release compiler notes — check before relying on a C++20/23 feature |

A config generated today is a snapshot of current best practice, not a
permanent truth — re-check the relevant source above before assuming an
older `.clang-tidy`/`.clang-format` is still idiomatic, same discipline
as `rules/common/rule-freshness.md`.
