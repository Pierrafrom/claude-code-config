---
name: write-docs
description: Actively writes and updates project documentation — scaffolds missing root files and docs/ structure following community conventions, writes complete Google-style English docstrings on undocumented public code, and rewrites stale doc sections to match the current code. This is not an opt-in cleanup pass — documentation is written incrementally as part of finishing any feature or change, the same way tests are written by default under TDD. Use right after implementing or modifying a feature, when audit-docs has listed gaps to fix, or whenever the user asks to write/update docs.
---

# Write Docs — incremental documentation, written as you go

> All commands below are calls to external tools (ruff, mdformat, grep) —
> identical regardless of the shell environment (Fish, Bash, PowerShell).

## Goal

Keep documentation a default, automatic part of finishing work — not a
separate task done later or only on request. Every time a feature is
implemented or existing code is changed, the docs describing that code
are written or updated in the same pass, per `rules/common/documentation.md`.

## Difference from audit-docs

`audit-docs` *diagnoses* gaps without touching any file. This skill
*writes*: it scaffolds missing structure, fills in missing docstrings,
and fixes stale sections — grounded in the actual code, never invented.

## Steps

### 1. Determine scope

- **After a feature/change** (default case): scope is the module(s) just
  written or modified — document them now, don't wait to be asked.
- **Full pass**: when explicitly requested, or following up on an
  `audit-docs` report — work through its list of gaps.

### 2. Docstrings — find gaps mechanically, don't guess

```fish
ruff check . --select D
```

For every flagged module/class/function, write a complete Google-style
docstring in English: one-line summary (imperative mood), longer
description only if the *why* isn't obvious, `Args`/`Returns`/`Raises`
as relevant, `Example` for non-trivial public API entry points. Skip
trivial private one-liners whose name is fully self-explanatory — see
`rules/common/coding-style.md` and `rules/common/documentation.md` for
the exact format and exceptions.

If `[tool.ruff.lint.pydocstyle] convention = "google"` and the `D` rule
category aren't yet enabled in `pyproject.toml`, add them — see
`rules/python/lint-strict.md` — so future gaps are caught automatically
rather than relying on remembering to check.

### 3. Root files — scaffold from the actual project, never a generic template

For each missing standard file (`README.md`, `CONTRIBUTING.md`,
`CHANGELOG.md`, `.env.example`), build it from what the project actually
contains:

```fish
cat pyproject.toml 2>/dev/null
git log --oneline -n 20
find . -name "*.py" -not -path "*/.venv/*" | head -20
```

A `README.md` always needs at minimum: one-liner, install steps, run
command, test command — see the checklist in `rules/common/documentation.md`.
Never fill a section with generic boilerplate that has nothing to do with
the actual project.

### 4. `docs/` — create files only when there's real content for them

Don't scaffold an empty `docs/architecture.md` just to match the standard
layout — create it once there's an actual architecture worth describing
(more than a handful of modules, non-obvious data flow, etc.). One topic
per file, following the layout in `rules/common/documentation.md`.

### 5. Fix stale sections

For any doc section flagged as outdated (by `audit-docs` or found while
working on related code), rewrite it to match the current behavior —
don't just patch the diff, reread the whole section to make sure the fix
doesn't leave the rest inconsistent.

### 6. Keep the README as a complete entry point

After adding or renaming any `docs/*.md` file, confirm the README links
it — an unlinked doc file is effectively invisible to a developer or an
AI assistant starting from the README.

```fish
grep -L "$(basename docs/some-file.md)" README.md
```

### 7. Final verification

```fish
ruff check . --select D
mdformat --check docs/ README.md 2>/dev/null
```

Both should come back clean for what was just touched. If something
can't be fixed (e.g. a `D` rule conflicting with a real constraint),
say so explicitly rather than silently leaving it.

### 8. Report

Short summary of what was created vs updated — file list, not a
restatement of the full content (the diff already shows that).

## Guardrails

- Never invent content not grounded in the actual code/config — if information needed to document something isn't available, ask rather than guessing
- Never pad a file with generic sections that have nothing project-specific to say
- Always in English, always Google-style for Python docstrings (see `rules/common/coding-style.md` for the language rule and `rules/common/documentation.md` for the format)
- If a well-established existing README/doc needs more than a small fix, propose the restructuring plan before rewriting it wholesale rather than overwriting silently
