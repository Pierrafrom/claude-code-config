# C++ rules — style, memory, error handling

Scope: modern C++ (target C++20 by default, see `rules/cpp/lint-strict.md`
for the compiler flags that enforce it). For C, see `rules/cpp/c-patterns.md`
instead — the two languages diverge enough (no RAII, no exceptions, no
classes in C) that they get separate rule files, sharing only the build
and lint tooling (`rules/cpp/lint-strict.md`, `rules/cpp/build-architecture.md`).
Advanced/architectural idioms (PIMPL, Type Erasure, CRTP, concurrency
patterns) are in `rules/cpp/design-patterns-cpp.md` — this file is the
day-to-day style guide, that one is the vocabulary for structuring larger
designs.

## Style

- Formatting is `clang-format`'s job entirely — see `rules/cpp/lint-strict.md`
  for the config. Never hand-format what the tool already normalizes.
- `#pragma once` over manual include guards — supported by every modern
  compiler (GCC/Clang/MSVC), no risk of a guard-name collision across
  files.
- One class per header/source pair where reasonable; a header exposes
  only what callers need — see PIMPL in `design-patterns-cpp.md` when a
  class's implementation details must be fully hidden.

## Naming

Mechanically enforced via `clang-tidy`'s `readability-identifier-naming`
— see the full config in `rules/cpp/lint-strict.md`. Convention:

- `PascalCase` for classes, structs, enums, and type aliases.
- `snake_case` for functions, methods, and variables — same casing as
  the project's Python code, keeps naming consistent when switching
  stacks.
- `UPPER_SNAKE_CASE` for constants and macros.
- `m_` prefix for private/protected data members — makes member access
  visually distinct from locals and parameters at a glance, no need to
  chase the declaration to know which is which.

## RAII and ownership — the foundation, not a suggestion

RAII (binding a resource's lifetime to an object's lifetime) is not
optional or contextual — every resource (memory, file handle, mutex,
socket) must be owned by an object whose destructor releases it. This is
the C++ instantiation of `rules/common/oop-design.md`'s Design by
Contract invariants: an object that holds a raw resource with no RAII
wrapper cannot guarantee it's ever released, especially across an
exception.

- **No raw `new`/`delete`** in application code. Ownership is always
  expressed through a smart pointer or a container.
- **`std::unique_ptr` by default.** It's free (no refcount overhead) and
  makes single ownership explicit. Reach for `std::shared_ptr` only when
  shared ownership is a genuine requirement (the object's lifetime is
  not tied to a single owner) — not as a default "safe choice", since it
  hides the real ownership graph and adds atomic refcounting cost.
- **`std::weak_ptr`** to break a reference cycle between two
  `shared_ptr`-owned objects, or to observe an object without extending
  its lifetime.
- Prefer a container (`std::vector`, `std::array`, `std::string`) over
  manual buffer management every time one fits — they're RAII wrappers
  around a raw buffer with bounds-aware operations.
- `clang-tidy`'s `cppcoreguidelines-owning-memory` and
  `cppcoreguidelines-no-malloc` catch violations of both rules
  mechanically — see `rules/cpp/lint-strict.md`.

## Rule of 0 / 3 / 5

- **Rule of 0 is the default**: a class that owns no raw resource
  directly (only smart pointers and RAII members) needs no user-declared
  destructor, copy/move constructor, or copy/move assignment — let the
  compiler generate all five as trivial member-wise operations.
- **Rule of 5** applies only to the rare class that manages a resource
  directly (writing a smart-pointer-like wrapper, a low-level RAII
  primitive): if any of destructor/copy-ctor/copy-assign/move-ctor/
  move-assign is user-declared, declare all five explicitly, even if one
  is `= delete`.
- Never the old "Rule of 3" alone in new code — a class needing custom
  copy semantics almost certainly needs custom move semantics too, or it
  silently falls back to an expensive copy where a move was intended.
- `clang-tidy`'s `cppcoreguidelines-special-member-functions` checks this
  automatically once a project's actual policy is known.

## Error handling — pick once per project, stay consistent

- **Exceptions are the default** for application-level C++ code: they
  compose with RAII (a thrown exception still runs destructors along the
  unwind path) and keep the success path free of error-checking noise.
  Mark a function `noexcept` only when it genuinely cannot throw —a
  false `noexcept` that throws anyway calls `std::terminate`, which is
  worse than not annotating it at all.
- **`std::expected<T, E>`** (C++23) is the modern alternative for
  explicit, non-exceptional error paths — a function whose failure is a
  normal, expected outcome (parsing, validation, a lookup that can
  legitimately miss) rather than a bug. Reach for it on a hot path where
  exception cost is unacceptable, or at an API boundary that must not
  throw across a module/ABI edge. Compiler support: solid on GCC/Clang as
  of mid-2026; full MSVC support lands with the VS "2026" toolset — check
  the target compiler before committing to it as a public API surface.
- Never mix exceptions and error-code returns for the same kind of
  failure within one component — pick one strategy per error category and
  keep it consistent, so callers don't have to remember which functions
  throw and which return a sentinel.
- `assert()` for programmer errors / broken invariants (debug builds
  only, compiled out via `NDEBUG` in release) — never for input
  validation on data that can legitimately be malformed at runtime; that
  goes through the exception/`expected` path instead.

## Modern idioms by standard — adopt deliberately, not by default

- **C++20 baseline** (see `rules/cpp/lint-strict.md` for the compiler
  flag): concepts to constrain templates instead of SFINAE tricks,
  ranges/views for composable data pipelines instead of raw iterator
  pairs, `std::span` for a non-owning view over a contiguous buffer
  instead of a raw pointer + length pair.
- **C++23 opt-in per project**, once the target compiler supports it:
  `std::expected` (above), *Deducing This* (see
  `design-patterns-cpp.md`) to collapse ref-qualified overload sets and
  simplify CRTP-like patterns.
- `clang-tidy`'s `modernize-*` checks flag code that could adopt a newer
  idiom (`typedef` → `using`, index-based loop → range-`for`) — see
  `rules/cpp/lint-strict.md`.
- Adopting a feature because it's new is not a goal in itself — same
  YAGNI posture as `rules/common/coding-style.md`. Adopt it when it
  actually simplifies the code at hand.

## Value semantics

- Prefer passing and returning by value for small, cheap-to-move types
  (RVO/move semantics make this free in the common case) over an
  out-parameter or a raw pointer.
- Avoid raw pointers in public interfaces except as a non-owning,
  optional "borrow" (and even then, prefer a reference or `std::span`
  when the parameter can't be null). A raw pointer in a signature should
  answer "who owns this and for how long" unambiguously — if it can't,
  it's the wrong type for the job.

## Common mistakes to avoid

- Manual `new`/`delete` pairs "because it's simple" — it's exactly the
  pattern RAII exists to eliminate; one missed `delete` on an exception
  path is a leak that's hard to reproduce.
- `shared_ptr` used as a default "just in case something else needs it
  later" — YAGNI applies to ownership too; start with `unique_ptr`,
  widen to `shared_ptr` only when a second owner is real.
- Catching `...` or a broad `std::exception` to swallow an error
  silently — same anti-pattern as an empty `catch {}` in any language
  (see `rules/typescript/design-patterns.md`'s error-handling section for
  the general principle).
- Writing a custom RAII wrapper for a resource the standard library
  already wraps (`std::unique_ptr` with a custom deleter for a C handle,
  `std::lock_guard`/`std::scoped_lock` for a mutex) instead of hand
  -rolling one.
