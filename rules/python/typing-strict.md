# Python typing — STRICT level

Typing is a design tool, not decoration (see "Strict typing as an OOP
discipline" in `rules/python/oop-idioms.md`). This file is the mechanical
baseline: what `mypy` config to use, which syntax is mandatory, and how to
handle the cases that resist typing cleanly.

## Baseline: mypy strict, not optional

`mypy --strict` (via `[tool.mypy] strict = true` in `pyproject.toml`) is
the default for every Python project, not a "nice to have for big
modules". Minimal config (see `examples-perso/pyproject.toml`):

```toml
[tool.mypy]
python_version = "3.11"
strict = true
warn_return_any = true
warn_unused_ignores = true
ignore_missing_imports = true
```

- `strict = true` enables the full bundle (`disallow_untyped_defs`,
  `disallow_incomplete_defs`, `check_untyped_defs`,
  `disallow_untyped_decorators`, `no_implicit_optional`,
  `warn_redundant_casts`, `strict_equality`, etc.) — don't enable a subset
  by hand, it drifts out of sync with mypy's own definition of "strict".
- `warn_return_any = true`: catches a function silently returning `Any`
  when the signature promises a concrete type — the most common way type
  safety leaks through a codebase.
- `warn_unused_ignores = true`: a `# type: ignore` that's no longer needed
  (because the lib shipped types, or the code changed) must be removed,
  not left as silent clutter.
- `ignore_missing_imports = true`: pragmatic default for third-party libs
  with no stubs — don't block the whole strict baseline on one untyped
  dependency. Add a proper override per-module if a specific lib turns out
  to matter for type safety.

## Type hints are mandatory, not optional, on public functions

- Every public function/method: full signature typed (parameters + return
  type). An untyped function is treated by mypy as having the most
  general possible type for every parameter — i.e. no guarantee at all,
  even with `strict = true` elsewhere in the file.
- Private helpers can stay untyped only during fast exploration —
  **graduated typing is acceptable as a migration path** (start with
  public/critical functions, expand outward), never as a final state for
  a module that's actually shipped.
- Typing complements tests, it doesn't replace them — a function can be
  perfectly typed and still wrong; keep both disciplines (see
  `rules/common/coding-style.md` → Tests).

## Modern syntax only — no legacy `typing` aliases

- `list[str]`, `dict[str, int]`, `tuple[int, ...]`, `X | None` — never
  `List`, `Dict`, `Optional`, `Union` from `typing` (legacy pre-3.10
  syntax), unless the project has an explicit, stated constraint to
  support Python < 3.10.
- `Self` (3.11+) as the return type for methods that return the instance
  (builder pattern, fluent/chained methods) instead of a manual `TypeVar`
  bound to the class.

```python
from typing import Self


class QueryBuilder:
    def where(self, clause: str) -> Self:
        self._clauses.append(clause)
        return self
```

## Read-only parameters: `Sequence`/`Mapping` over concrete containers

When a function only reads a list/dict parameter and never mutates it,
type it with the abstract read-only interface — it documents the
contract and lets callers pass any compatible container, not just the
exact concrete type:

```python
from collections.abc import Mapping, Sequence


def total_price(items: Sequence[Item]) -> float: ...
def labels_by_code(table: Mapping[str, str]) -> None: ...
```

Use the concrete `list[T]`/`dict[K, V]` only when the function actually
needs list/dict-specific behavior (appending, mutating in place).

## `None` narrowing — explicit, never implicit

Never call a method on a `str | None` (or any `X | None`) without a prior
explicit check — mypy strict mode will already reject this, but the
discipline matters even where mypy can't fully verify it (e.g. data
crossing an untyped boundary):

```python
def shout(name: str | None) -> str:
    if name is None:
        return ""
    return name.upper()
```

## `TypedDict` for fixed-shape dictionaries

If a dict has a known, stable set of keys (e.g. a JSON payload, a config
block), use `TypedDict` instead of `dict[str, Any]` — it gives field-level
type checking instead of erasing all structure:

```python
from typing import TypedDict


class UserPayload(TypedDict):
    id: int
    email: str
    is_active: bool
```

## `Protocol` vs `Generic`/`TypeVar`

- **Protocol**: see `rules/python/oop-idioms.md` for the full rationale —
  structural typing for duck-typed interfaces you don't own end-to-end.
- **Generics** (`TypeVar`, or the 3.12+ `class Stack[T]` syntax): reserve
  for genuinely reusable container/utility classes with more than one
  concrete use case already in hand (YAGNI applies to generics too — see
  `rules/common/coding-style.md`). A generic class justified by a single
  call site is premature abstraction, not type safety.

## `# type: ignore` — last resort, always justified

- Never used to silence a real type error out of convenience. Acceptable
  only when mypy is genuinely wrong or the situation is a known limitation
  (e.g. an untyped third-party API, a dynamic pattern mypy can't model).
- Always paired with the specific error code and a one-line reason:

```python
result = legacy_api.call()  # type: ignore[no-any-return] — untyped vendor SDK, no stubs available
```

- `warn_unused_ignores = true` (above) ensures a stale `# type: ignore`
  gets flagged and removed once it's no longer needed.

## Expected behavior from Claude

- Write full type hints on every public function/method as the code is
  written — not as a follow-up pass.
- Run `mypy` (or `uv run mypy src`) alongside `ruff check .` before
  presenting Python code as done; treat a strict-mode mypy error the same
  way as a ruff warning — fix it, don't suppress it.
- If a third-party lib has no stubs and genuinely blocks strict typing for
  one module, flag it explicitly rather than silently loosening
  `strict = true` project-wide.
