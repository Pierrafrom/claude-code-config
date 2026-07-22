# C++ architectural patterns and idioms — shared vocabulary, not obligations

Concrete C++ instantiation of `rules/common/oop-design.md`'s "design
patterns are welcome" principle, one level above `rules/cpp/cpp-patterns.md`'s
day-to-day style. Everything below is a well-documented industry pattern
(Klaus Iglberger's *C++ Software Design*, O'Reilly 2021; CppCon's annual
"Modern C++ Design Patterns" talks; softwarepatternslexicon.com/cpp) —
not a mandate to use all of them. Several trade off against each other
(perf vs flexibility vs testability); the right choice depends on the
actual problem, same YAGNI posture as everywhere else in this config
(`rules/common/coding-style.md`). The value of knowing this vocabulary is
that the resulting code is *recognizable and discussable* by another
experienced C++ developer — that is the point, not pattern-count.

## The "top 6" idioms every senior C++ dev recognizes

| Pattern | Purpose | Reach for it when |
|---|---|---|
| **RAII** | Bind a resource's lifetime to an object's — see `cpp-patterns.md` | Always — this one is not optional, see `cpp-patterns.md` |
| **PIMPL** (Pointer to Implementation) | Hide a class's implementation behind an opaque pointer — cuts compile-time dependencies, stabilizes ABI | A widely-included header whose implementation changes often, or a public library boundary where ABI stability matters |
| **Type Erasure** | Combine polymorphism with value semantics, no inheritance hierarchy (`std::function`, `std::any` are std examples) | An interface needs polymorphic behavior but a hierarchy would force unwanted coupling or heap-allocated, reference-semantic objects |
| **CRTP** | Static (compile-time) polymorphism, no vtable cost; also used for mixins | A hot path needs polymorphic-like dispatch with zero runtime cost — but see the Concepts note below, it's not the only modern option anymore |
| **Policy-Based Design** | Inject behavior via template parameters instead of inheritance | A generic, high-performance library needs several independently swappable behaviors (allocation strategy, threading model) |
| **`std::expected`** (C++23) | Explicit, non-exceptional error handling | See `cpp-patterns.md`'s error-handling section for the full decision rule |

**PIMPL — source**: Iglberger's *C++ Software Design*, Guideline 28,
"Build Bridges to Remove Physical Dependencies" — frames PIMPL as an
application of the Bridge pattern specifically for compile-time decoupling.

```cpp
// widget.h — public header, no dependency on the implementation's internals
class Widget {
public:
    Widget();
    ~Widget();  // must be declared here, defined where Impl is complete
    void do_something();
private:
    class Impl;
    std::unique_ptr<Impl> pimpl_;
};
```

**CRTP vs C++20 Concepts**: the two overlap for "constrain/customize
behavior at compile time without a vtable." Concepts are generally the
better default for *new* code — they give clearer error messages, don't
require inheriting from a template of yourself, and integrate with
overload resolution directly. CRTP remains the right tool when the
target compiler doesn't support Concepts, or when the pattern is
genuinely about injecting a shared implementation into a hierarchy of
otherwise-unrelated types (a mixin), not just constraining a template
parameter — a job Concepts don't do.

**Type Erasure vs a classic hierarchy**: Iglberger presents it as an
*alternative to consider*, not a default replacement for inheritance —
reach for it when value semantics and avoiding forced heap allocation
matter more than the simplicity of a plain virtual interface.

## C++23 additions worth knowing

- **Deducing This** (explicit object parameter): collapses `&`/`const&`/
  `&&`/`const&&`-qualified overload sets into a single templated method,
  and simplifies some CRTP use cases (a method can refer to the derived
  type via the deduced `self` parameter instead of `static_cast<Derived*>(this)`).
  Compiler support is still catching up as of mid-2026 (GCC 13+/Clang 16+
  have it for the common cases, MSVC substantially caught up from 19.34+)
  — verify against the project's actual target compiler before relying on
  it in a public API.
- **`std::variant` + `std::visit`** as a modern, exhaustively-checked
  alternative to the classic GoF Visitor pattern for closed sets of
  types — the compiler flags a missing case in the visitor at compile
  time, where a GoF Visitor hierarchy only fails at runtime (a missed
  override) or needs a separate mechanism to enforce exhaustiveness.

## Architectural patterns — above the single-class level

These structure a whole system, not one class — same role as
`rules/typescript/design-patterns.md`'s repository/DI patterns for a
TS/Node backend, or `rules/python/fastapi-architecture.md`'s layering.

- **Layers**: split the system into layers where each layer only talks
  to the one immediately below it — the classic separation of business
  logic / infrastructure / presentation. See
  `rules/common/project-architectures.md`'s feature-based-vs-layered
  discussion — the same trade-off applies to C++ modules as to a backend
  API's folder structure.
- **Pipes-and-Filters**: decompose a complex task into composable
  elementary stages, each transforming data and passing it to the next —
  the natural fit for data/stream processing pipelines (mirrors
  `rules/data/data-engineering.md`'s Extract/Transform/Load separation,
  applied inside a single C++ process instead of across pipeline steps).
- **MVC**: separate state, presentation, and interaction control — not
  exclusive to GUI code; the same split clarifies any system where
  "what the data is," "how it's shown," and "how input changes it" would
  otherwise tangle into one class.

## Concurrency patterns (modern C++)

- **Active Object**: decouple a method call from its execution — the
  call enqueues a request that runs asynchronously on the object's own
  thread/executor, the caller gets a future/promise back.
- **Thread pool**: reuse a fixed set of worker threads instead of
  creating/destroying threads per task — standard technique to bound
  thread-creation overhead and resource usage under load.
- **`std::call_once`** (with a `std::once_flag`) or a function-local
  `static` for thread-safe one-time initialization of a shared resource —
  replaces manual double-checked locking, a pattern with well-documented,
  easy-to-get-wrong memory-ordering pitfalls.
- **Event loop / dataflow patterns**: for reactive systems where work is
  driven by incoming events rather than a linear call sequence.

## Reading this file correctly

- CRTP vs Concepts, Type Erasure vs inheritance: genuinely open trade
  -offs, not settled answers — the table and notes above give the
  starting bias, not a rule to apply blindly.
- Opaque-pointer-style patterns (PIMPL here, its C equivalent in
  `rules/cpp/c-patterns.md`) are documented as "use with parcimony" —
  they add a compile-time indirection and a heap allocation; reach for
  them when the benefit (ABI stability, compile-time decoupling) is
  actually needed, not on every class by default.

## Sources

- Klaus Iglberger, *C++ Software Design* (O'Reilly, 2021) — the current
  reference for these patterns, including the PIMPL/Bridge guideline
  numbering cited above.
- CppCon — "Modern C++ Design Patterns" talks, updated yearly; re-check
  before trusting an older recording's compiler-support claims.
- [C++23 status — Clang](https://clang.llvm.org/cxx_status.html),
  [C++23 support in MSVC Build Tools — Microsoft C++ Team Blog](https://devblogs.microsoft.com/cppblog/c23-support-in-msvc-build-tools-14-51/)
  — check before committing to a C++23 feature as a public API surface.
- [C++23's Deducing this — Microsoft C++ Team Blog](https://devblogs.microsoft.com/cppblog/cpp23-deducing-this/)
- softwarepatternslexicon.com/cpp — extended pattern catalogue, concurrency included.

This whole file carries a freshness signal (compiler-support claims,
yearly-updated talks) — see `rules/common/rule-freshness.md` before
trusting the compiler-support notes above on a new project; re-verify
rather than assuming they still hold.
