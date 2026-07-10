---
name: audit-quality
description: Exhaustive code quality audit across the whole project (not just recent changes) — technical debt, project-wide duplication, complexity, strict typing (mypy), test coverage, convention consistency. Use for a periodic project status check, before a release, or when the user explicitly asks for a "quality audit" or "code audit". Different from the code-reviewer agent, which focuses on a one-off diff before a commit.
---

# Audit Quality — exhaustive project status check

> All commands below are calls to external tools (git, ruff, mypy,
> pytest, grep, uv) — identical regardless of the shell environment
> (Fish, Bash, PowerShell). See `rules/common/shell-fish.md` if a command
> needs adapting for use outside a Claude Code session.

## Difference from code-reviewer (agent)

`code-reviewer` examines a one-off change before a commit. This skill examines
**the whole project** at a given point in time — useful periodically (before a
release, at the end of a sprint, after a long series of changes), not on
every commit.

## Steps

### 1. Project overview

```fish
find . -name "*.py" -not -path "*/.venv/*" -not -path "*/node_modules/*" | xargs wc -l | tail -1
ruff check . --statistics
```

Get the code volume and an initial quantitative signal of lint issues
before digging deeper.

### 2. Exhaustive lint

```fish
ruff check . --output-format=concise
```

Unlike a pre-commit check (which only looks at modified files), this
audits the entire project — including legacy code never touched recently.

### 3. Strict typing

```fish
uv run mypy src
```

Unlike the per-commit pre-commit hook (which only sees staged files at
commit time), this is a full-project run — catches typing debt in legacy
modules nobody has touched since the `mypy --strict` baseline
(`rules/python/typing-strict.md`) was adopted. Count errors per module to
spot where typing was never retrofitted, and grep for unjustified escape
hatches across the whole project, not just recent files:

```fish
grep -rn "type: ignore" src/ --include="*.py"
```

### 4. Test coverage

```fish
pytest --cov=src --cov-report=term-missing
```

Identify modules below the 80% threshold (see `rules/common/coding-style.md`)
and list them explicitly, not just the overall percentage.

### 5. Project-wide duplication and complexity

- Spot duplicated logic blocks across files (not just within a single file) — `ruff check . --select C90` for cyclomatic complexity
- Identify files > 300 lines or functions > 40 lines (thresholds from `rules/common/coding-style.md`) across all of `src/`

### 6. Convention consistency

- Check that modules follow the same structure (e.g. all `io/` modules expose a similar pattern)
- Spot naming inconsistencies (mixed snake_case vs camelCase, etc.)
- Check consistent use of structured logging (`rules/common/logging.md`) — spot leftover `print()` calls across the whole project, not just recent files:
  ```fish
  grep -rn "print(" src/ --include="*.py"
  ```

### 7. Dependencies

```fish
uv pip list --outdated
uvx pip-audit
```

Flag outdated or unmaintained dependencies, and known CVEs via
`pip-audit` (see `rules/common/coding-style.md` → Security), without
updating them automatically. Always through `uv`/`uvx`, never a bare
`pip` — a bare `pip list` can silently target the wrong interpreter
instead of the project's `uv`-managed `.venv`.

### 8. Final report

Output format:

```
# Quality audit — [project] — [date]

## Summary
- N lines of code, M files
- Lint: X warnings (vs the expected zero-tolerance)
- Typing: Z mypy errors (vs the expected zero, strict baseline)
- Coverage: Y% (target 80%+)

## Issues by severity

### Blocking
- [list]

### Important
- [list]

### Minor / technical debt
- [list]

## Prioritized recommendations
1. [highest-impact action first]
2. ...
```

## Guardrails

- This skill fixes nothing automatically — it diagnoses and lists, the user decides what to address
- Don't duplicate a recent audit without significant change since then — check `git log` since the last audit before rerunning everything from scratch
