# C rules — style, memory discipline, C-specific idioms

Scope: C has no classes, no inheritance, no exceptions, no RAII — the
industry has its own equivalent idioms instead, heavily documented in
firmware/embedded contexts (Memfault's Interrupt blog, the Linux kernel
source, LWN). For C++, see `rules/cpp/cpp-patterns.md` and
`rules/cpp/design-patterns-cpp.md` instead. Shared tooling (compiler
flags, sanitizers, CMake, `clang-format`) is in
`rules/cpp/lint-strict.md` and `rules/cpp/build-architecture.md`.

Context for this config (see the routing note at the end): general
application/systems C, not a safety-critical/automotive/aerospace/medical
target — MISRA C is scoped out by default here, see the last section.

## Style and naming

- `clang-format` handles formatting exactly as for C++ — same config,
  see `rules/cpp/lint-strict.md`.
- Naming: `snake_case` for functions and variables, `UPPER_SNAKE_CASE`
  for macros and constants, `PascalCase` for typedef'd struct names when
  the struct represents a distinct type the caller should treat
  opaquely. No `Hungarian notation` (`pInt`, `lpszName`) — the type
  system and the name itself should carry that information, same
  no-type-in-name principle as `rules/common/coding-style.md`.
- `#pragma once` over manual include guards, same as C++.

## Memory discipline — the core of "clean" C

C has no RAII, so ownership must be enforced by convention and
discipline instead of the compiler. This is the single most
consequential rule in a C codebase:

- **Every `malloc`/`calloc`/`realloc` has one clearly identified owner**
  responsible for the matching `free` — document it in the function's
  doc comment (`Doxygen` `@param`/`@return` — see
  `rules/common/documentation.md`) whenever ownership isn't obvious from
  the name (`create_*`/`destroy_*`, `*_new`/`*_free` naming pairs make
  this self-documenting and should be the default naming convention for
  any allocating/freeing function pair).
- **Never a naked pointer as a return value from an allocating function**
  without an equally naked, paired `_free`/`_destroy` function next to
  it in the same header.
- **Check every allocation's return value** — `NULL` on failure is not a
  theoretical case to skip; a missed check is a null-deref waiting for a
  low-memory condition to trigger it in the field.
- **Valgrind / AddressSanitizer / UndefinedBehaviorSanitizer** in the
  test build, same tools as C++ — see `rules/cpp/build-architecture.md`
  for wiring them into CMake. Non-negotiable for any C project in this
  config, same "uncompromising" bar as `ruff`/`mypy` for Python.

## Error handling — return codes, not sentinels buried in output params

- No exceptions in C — the standard idiom is an integer return code
  (`0` success, negative or an explicit enum for the failure kind) with
  the actual result written through an output pointer parameter, or a
  sentinel value (`NULL`, `-1`) on a function whose only output is the
  return value itself.
- Pick one convention per project and hold the line: either "0 is
  success, non-zero is an error code" (POSIX/kernel convention) or a
  dedicated result enum — never mix the two within the same codebase.
- `errno`-style thread-local error state is acceptable for a
  POSIX-facing API surface but should not be the *only* error signal for
  library-internal functions — return the failure explicitly so the
  caller can't forget to check `errno`.

## Portability

- Use `<stdint.h>` fixed-width types (`int32_t`, `uint8_t`, `size_t` for
  sizes/counts) — never assume `int`/`long` width, which varies across
  platforms and ABIs.
- Be explicit about endianness at any serialization/deserialization
  boundary (file format, network protocol) — never rely on the host's
  native byte order implicitly.
- `static_assert` on structure layout assumptions (size, alignment) that
  the code depends on, so a portability break fails at compile time
  rather than as a silent runtime corruption on a new target.

## C-specific patterns — the equivalents C++ gets from classes

| Pattern | C++ equivalent | Detail |
|---|---|---|
| **Opaque pointer** | PIMPL | Expose an incomplete `struct` in the public header, define its layout only in the `.c` file — hides implementation, protects ABI. Use sparingly (see caution below) — a plain, fully-visible struct is simpler to use and should be the default unless ABI stability or multiple implementations genuinely require hiding it. |
| **Struct of function pointers** ("manual vtable") | Abstract interface / virtual class | A struct whose fields are function pointers, used massively in the Linux kernel (`file_operations` and similar) to express a pluggable interface without C++ virtual dispatch. |
| **`void *ctx` as the first parameter** | Lambda capture / `this` | Standard convention for callbacks, observers, and strategy-style APIs in C — the context pointer carries whatever state the callback needs, cast back to its real type inside the callback. |
| **Table-driven dispatch / explicit state machines** | `switch`-based polymorphism simulation | A lookup table (array or struct-of-function-pointers indexed by state/event) is often clearer *and* faster than simulating OOP dispatch — the standard idiom in real-time/embedded systems. |
| **Arena / slab allocator** | Object pool | Replaces repeated dynamic allocation with one upfront block sliced into fixed-size (slab) or variable (arena) chunks — used where heap churn is unacceptable (real-time constraints, no dynamic heap at all on some embedded targets). |

```c
/* opaque pointer — public header exposes only a forward declaration */
typedef struct Widget Widget;

Widget *widget_new(void);
void widget_destroy(Widget *widget);
void widget_do_something(Widget *widget);
```

```c
/* struct of function pointers — pluggable interface, no vtable machinery needed */
typedef struct {
    int (*read)(void *ctx, char *buf, size_t len);
    int (*write)(void *ctx, const char *buf, size_t len);
    void (*close)(void *ctx);
} file_operations;
```

**Caution, documented and worth repeating**: simulating C++-style OOP in
C (a full vtable-plus-hierarchy scheme layered by hand) adds real
complexity without the compiler-checked safety or devirtualization
optimizations C++ gets natively. Reach for the struct-of-function
-pointers idiom when a genuinely pluggable interface is needed (multiple
backends behind one API, like the kernel's `file_operations`) — not as a
default way to "do OOP in C" for an ordinary module that doesn't need
runtime-swappable behavior.

## MISRA C / CERT C — scoped out by default in this config

This config's default context (per the routing decision made when this
file was created) is coursework and personal application/systems
projects — not automotive, aerospace, or medical safety-critical
targets. Concretely:

- **MISRA C is not applied by default.** It requires a paid checker
  (Parasoft, PC-lint, Cppcheck Premium) and a discipline calibrated for
  certification contexts — disproportionate outside a genuine
  safety-critical requirement.
- **SEI CERT C Coding Standard** is a free, lighter-weight reference
  worth consulting for the categories that matter regardless of context
  (integer overflow, buffer handling, format-string misuse) — `clang-tidy`
  can enforce a subset of CERT rules via its own `cert-*` check family
  (see `rules/cpp/lint-strict.md`).
- **If a project's context changes** (a client/course requirement turns
  out to be genuinely safety-critical), flag it explicitly rather than
  silently continuing under the default posture — same "flag a
  constraint that can't be respected" rule as
  `rules/common/coding-style.md`'s permanent guardrails.
