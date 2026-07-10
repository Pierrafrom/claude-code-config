---
name: lint-zero
description: Finds and fixes every lint and formatting warning in the project — Python code (ruff) and Markdown files (tables, spacing, structure), to reach zero warnings. Use when the user wants to clean up lint, fix formatting warnings, or explicitly asks for code/docs to have zero warnings.
---

# Lint Zero — exhaustive detection and fixing, zero warnings

> All commands below are calls to external tools (ruff,
> mdformat, markdownlint-cli2) — identical regardless of the shell
> environment (Fish, Bash, PowerShell).

## Goal

Reach zero warnings across the whole project — not just zero blocking
errors — covering both Python code and Markdown files (misaligned
tables, spacing, heading structure), per the project's uncompromising
rigor level (`rules/python/lint-strict.md`).

## Difference from audit-quality

`audit-quality` *diagnoses* and lists problems without fixing them.
This skill *actively fixes*, for the categories of problems that have a
reliable automatic fix. The two complement each other: audit-quality for
the status check, lint-zero for the actual reset to zero.

## Steps

### 1. Check available tools, install if missing

```fish
ruff --version
mdformat --version
```

If missing:

```fish
uv add --dev ruff mdformat mdformat-gfm
```

(see `rules/python/python-patterns.md` — project dev tools always go through `uv add --dev`, never a bare `pip install`)

`mdformat-gfm` adds support for GitHub specifics (tables, alerts)
beyond strict CommonMark — necessary for a project targeting GitHub.

### 2. Python — detect then fix

```fish
ruff check . --statistics
```

Look at the volume before fixing in bulk, then:

```fish
ruff check . --fix
ruff format .
```

Rerun `ruff check .` afterward to confirm zero results. If warnings
remain after `--fix` (some rules aren't auto-fixable, e.g. cyclomatic
complexity `C901`), handle them manually — never use
`--unsafe-fixes` without reviewing the resulting diff, some "unsafe"
fixes change behavior, not just style.

### 3. Markdown — detect then fix

```fish
mdformat --check .
```

If some files aren't compliant:

```fish
mdformat .
```

This automatically fixes: misaligned tables (columns not aligned on the
pipe `|`), multiple spacing, inconsistent line endings, list structure.
Reformats every `.md` in the project in one pass.

### 4. Markdown — complementary structural check (beyond formatting)

`mdformat` fixes *style*, but not certain *structural* issues
(heading hierarchy skipping a level, broken links, lines too
long per a defined limit). If `markdownlint-cli2` is available
(Node.js required, check before imposing it):

```fish
npx markdownlint-cli2 "**/*.md"
```

If Node.js isn't wanted on the project (consistent with the project's
Python scope), flag the limits of `mdformat` alone rather than
imposing a Node dependency — `mdformat` covers the essentials (tables,
spacing) without adding that dependency.

### 5. Final check — confirm zero warnings everywhere

```fish
ruff check .
mdformat --check .
```

Both commands must return exit code 0 with no output. If that's
not the case, list precisely what remains and why it couldn't be
fixed automatically (non-auto-fixable rule, style conflict,
etc.) rather than declaring the task half-done as complete.

### 6. Final report

```
# Lint Zero — [project] — [date]

## Before
- Python: N warnings
- Markdown: M non-compliant files

## Fixed automatically
- [summary of applied fixes]

## Remaining (manual fix needed)
- [if applicable: file, rule, why not auto-fixable]

## Final state
- ruff check . → 0 warnings
- mdformat --check . → compliant
```

## Guardrails

- Never use `ruff check --fix --unsafe-fixes` without reviewing the resulting diff — some "unsafe fixes" change runtime behavior, not just form
- Before running `mdformat .` on the whole repo, check that no Markdown file contains extended non-CommonMark syntax fragile to reformatting (e.g. MyST, certain MkDocs extensions) — if detected, handle that file separately rather than risking a silent break
- Always rerun tests (`pytest`) after a `ruff --fix` pass — a lint fix should never break a test, but verify it rather than assume it
- Don't impose Node.js/markdownlint-cli2 if the project is strictly Python/shell/Docker with no Node already present — propose it rather than installing a heavy dependency without asking
