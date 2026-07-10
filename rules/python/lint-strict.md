# Python lint — STRICT level

## Tool: ruff (linter + formatter, replaces flake8/black/isort/pyupgrade)

Chosen for speed (Rust) and because a single tool covers lint + format +
import sorting + syntax modernization — less config to maintain, fewer
tokens spent reading 4 different config files.

## Installing in a project

```bash
uv add --dev ruff
```

(see `rules/python/python-patterns.md` for the general uv/dependency-isolation rule — never a bare `pip install` inside a project)

Config in `pyproject.toml` (see the `examples-perso/pyproject.toml` provided with this config) —
never a separate `.flake8`/`setup.cfg`.

## Enabled rules (strict level, not the permissive default)

Minimum enabled ruff categories:
- `E`, `W` — pycodestyle (PEP8 style, including `E711`/`E712` forcing `is`/`is not` against `None`/`True`/`False` rather than `==`)
- `F` — pyflakes (dead code, unused imports, unused variables, bans `from module import *`)
- `I` — isort (import sorting: stdlib → third-party → local, blank line between groups)
- `N` — pep8-naming (naming conventions: `snake_case` functions/variables/modules, `PascalCase` classes, `UPPER_SNAKE_CASE` constants)
- `UP` — pyupgrade (modern syntax, no Python 2/legacy patterns)
- `B` — bugbear (common bugs: mutable default args, broken comparisons)
- `SIM` — simplify (simplification of redundant code, including falsy-empty-sequence checks rather than `len(x) == 0`)
- `C90` — cyclomatic complexity (detects overly complex functions)
- `ARG` — unused arguments
- `RET` — `return` consistency (poorly handled early return)
- `PTH` — pathlib (forces `pathlib.Path` rather than `os.path`)
- `LOG` — best practices for the `logging` module (consistent with rules/common/logging.md)
- `D` — pydocstyle (enforces docstring presence and format on public modules/classes/functions — the mechanical enforcement of the docstring rule in `rules/common/documentation.md`)
- `TID` — tidy-imports: bans relative imports (`ban-relative-imports = "all"`) in favor of absolute imports everywhere
- `ANN` — flake8-annotations: flags missing type hints on function signatures — the lint-side enforcement that pairs with the mypy strict baseline below

Formatting specifics handled automatically by `ruff format` (no manual
enforcement needed, but worth knowing what's covered): 4-space
indentation, no tabs, one consistent quote style project-wide
(`quote-style = "double"`), no semicolons / no two statements on one
line, 2 blank lines before top-level `def`/`class`, 1 blank line between
methods. Line length: **88 characters** (`line-length = 88` —
Black/Ruff-era default, more realistic than the historical PEP 8 79).

`D` requires a convention to be set, otherwise ruff defaults to a generic
check:

```toml
[tool.ruff.lint.pydocstyle]
convention = "google"
```

This is the project's chosen docstring style (see `rules/common/documentation.md`)
— never switch to numpy/pep257 convention without an explicit reason, to
keep one consistent format across every project.

## Expected behavior from Claude

- **Zero tolerance on warnings, not just errors.** `ruff check .` must come back empty before any commit.
- Run `ruff check . --fix` automatically for safe fixes before presenting the code as done.
- Never add a `# noqa` to silence the linter without an explicit justification in the message — an unjustified `# noqa` is a signal that the code should be fixed, not hidden.
- If a ruff rule conflicts with a real project constraint (e.g. justified high complexity), document why in a `# noqa: <code> — <short reason>` comment.
- Cyclomatic complexity: if `C901` triggers, split the function rather than disabling the rule.

## Type checking — mypy strict, mandatory baseline

Strict typing is not reserved for large modules — `mypy --strict` is part
of the non-negotiable baseline for every Python project, same status as
`ruff check .`. Full rules, `pyproject.toml` config, modern syntax
(`list[str]`, `X | None`, `Self`, `Protocol`, `TypedDict`,
`Sequence`/`Mapping`), and the `# type: ignore` policy are in
`rules/python/typing-strict.md` — read that file before typing anything
non-trivial.

- Run `mypy` (or `uv run mypy src`) alongside `ruff check .` before
  presenting Python code as done.
- A strict-mode mypy error is treated exactly like a ruff warning: fix it,
  never suppress it without the documented `# type: ignore[<code>]`
  justification described in `rules/python/typing-strict.md`.

## Pre-commit — always present, not optional

`.pre-commit-config.yaml` (ruff check + ruff format + mdformat + mypy on
`src/`) is part of the non-negotiable baseline for every project,
regardless of size — see `rules/common/repo-structure.md`. The mypy hook
makes the strict-typing baseline in `rules/python/typing-strict.md` an
actual commit-time gate, not just something Claude is trusted to run
manually. Set up via the `init-project` skill; `uv add --dev pre-commit
&& uv run pre-commit install` if added to an existing project that
doesn't have it yet.
