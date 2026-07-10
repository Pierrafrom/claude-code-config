# Python rules

See `rules/python/oop-idioms.md` for OOP-specific idioms (dataclasses,
properties, ABC/Protocol, dunders, exceptions) and
`rules/python/typing-strict.md` for the full mypy-strict typing baseline.
This file covers general style, naming, data/ML conventions, tests, and
environment management.

## Style

- Follow PEP 8, formatting via `ruff format` (mechanical rules — indentation,
  quotes, blank lines, line length — are enforced automatically, see
  `rules/python/lint-strict.md`)
- Type hints on every public function (full signature, not just internally) —
  mandatory baseline detailed in `rules/python/typing-strict.md`, not optional
- f-strings rather than `.format()` or `%`
- `pathlib.Path` rather than string manipulation for paths
- Method chains broken across lines when they stop fitting on one — readability
  over a single dense line
- One function = one level of abstraction. Splitting into sub-functions is
  justified when each sub-function has an autonomous, reusable meaning and
  name — not by a dogmatic line-count target. A linear, readable 30-line
  function beats 5 six-line functions the reader has to chase through to
  follow one flow (Ousterhout's "deep modules" critique of over-fragmented
  Clean Code — see `rules/common/coding-style.md`)

## Naming — Python specifics

General naming principles (clarity, no type-in-name, no abbreviations,
boolean-as-predicate, no boolean flag parameters) are in
`rules/common/coding-style.md` — apply them as-is. What's specifically
Python here:

- Casing: `snake_case` for variables/functions/modules, `PascalCase` for
  classes, `UPPER_SNAKE_CASE` for constants — mechanically enforced by
  ruff's `N` (pep8-naming) rule, see `rules/python/lint-strict.md`.
- Boolean prefix convention: `is_`, `has_`, `can_`, `should_`.
- `_attr` for "internal by convention"; `__attr` (name mangling) only when
  access from subclasses must genuinely be blocked — use sparingly.

## Data & ML (main use case)

- Prefer Polars over pandas when performance or data size justifies it; pandas is still fine for quick exploration
- Always check types and missing values after loading data (`.info()`, `.null_count()`, etc.) before continuing
- Data pipelines: clearly separate extraction / transformation / loading (not a single monolithic script once it exceeds ~50 lines)
- For Jupyter notebooks: exploratory code is fine without tests, but any reused logic must be extracted into a tested module

## Tests

- `pytest` by default
- Fixtures for test data, no repeated hardcoded data
- Mock network/external API calls (LLM, DB) in unit tests

## Dependencies & environment

- **Always uv, always an isolated environment** — see `rules/common/coding-style.md` for the general (any-language) rule. `uv` creates and manages the `.venv` automatically, no manual `venv`/`pip` dance.
- `uv add <pkg>` for runtime deps, `uv add --dev <pkg>` for dev-only tools (ruff, pytest, mdformat...) — recorded in `pyproject.toml`'s `[dependency-groups]` and pinned in `uv.lock` for reproducibility.
- `uv sync` to install everything from the lockfile (e.g. right after cloning), `uv run <command>` to run anything (`uv run pytest`, `uv run python -m src`) inside the project's environment without manually activating it.
- `uvx <tool>` for an occasional tool that doesn't need to be a project dependency (e.g. `uvx pip-audit`) — runs in an ephemeral environment, nothing added to `pyproject.toml`.
- `pip install --break-system-packages` only for a genuinely one-off script with no `pyproject.toml` — not for anything inside a real project.

## Common mistakes to avoid

See `rules/python/oop-idioms.md` ("Python-specific anti-patterns to avoid")
for `@staticmethod` excess, no-logic getters/setters, and `isinstance()`
cascades. Additional general mistakes:

- Mutable default arguments (`def f(x=[])`) — use `field(default_factory=list)`
  in a dataclass, or `None` + assignment in the function body
- `for` loops over a DataFrame when a vectorized operation exists
- Ignoring deprecation warnings (especially pandas/numpy)
- Mutable global variables — they create hidden dependencies and make
  debugging expensive
- The positional-only `/` marker on parameters that have no real need for it —
  a code smell outside a genuinely stable public API
- A list comprehension with multiple nested loops and multiple conditions —
  past that complexity, a plain loop is more readable
- A list comprehension over a large dataset where a generator expression
  would do — list comprehensions materialize the whole result in memory,
  generators don't
