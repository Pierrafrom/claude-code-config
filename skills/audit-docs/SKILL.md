---
name: audit-docs
description: Exhaustive audit of project documentation — checks that README/CONTRIBUTING/CHANGELOG/docs are present and complete, that nothing is stale versus the actual code, that docstrings are complete and Google-style, and that the doc structure stays easily ingestible by AI assistants (single source of truth, self-contained files, clear entry point from the README). Use periodically, before a release, or when the user explicitly asks for a "doc audit". Diagnoses only — see write-docs to actively fix what's found.
---

# Audit Docs — exhaustive documentation status check

> All commands below are calls to external tools (ruff, grep, find) —
> identical regardless of the shell environment (Fish, Bash, PowerShell).

## Difference from write-docs

This skill *diagnoses* and lists documentation gaps without fixing them.
`write-docs` *actively writes/fixes* them. The two complement each other:
audit-docs for the status check, write-docs for the actual fix — same
relationship as `audit-quality` / `lint-zero`.

## Steps

### 1. Inventory existing docs

```fish
find . -maxdepth 2 -iname "README.md" -o -iname "CONTRIBUTING.md" -o -iname "CHANGELOG.md" -o -iname ".env.example"
find docs -name "*.md" 2>/dev/null
```

Compare against the standard root files and `docs/` layout defined in
`rules/common/documentation.md`. Flag missing ones — but use judgment: a
throwaway script doesn't need a `CONTRIBUTING.md`, a project with no
releases yet doesn't need a `CHANGELOG.md`.

### 2. Check the README quickstart actually works

Cross-check every command in the README's install/run section against
what the project actually exposes (`pyproject.toml` entry points, actual
CLI/script names) — a documented command that no longer exists is worse
than no documentation.

### 3. Check `docs/` organization

- One topic per file, no monolithic dump — flag any `docs/*.md` mixing unrelated topics
- No orphan files: every file under `docs/` should be linked from the README or another doc — files nobody links to are invisible to a dev or an AI assistant browsing from the README
  ```fish
  for f in docs/*.md; do grep -q "$(basename "$f")" README.md || echo "orphan: $f"; done
  ```

### 4. Docstring completeness and format — mechanical check

```fish
ruff check . --select D
```

Ruff's `D` (pydocstyle) rules catch missing docstrings on public
modules/classes/functions and format violations against the configured
convention. If `[tool.ruff.lint.pydocstyle] convention = "google"` isn't
set in `pyproject.toml` yet, flag it as missing config rather than
skipping the check — see `rules/python/lint-strict.md`.

### 5. Staleness check — docs vs actual code

For the project's main public functions/classes, spot-check that the
docstring's `Args`/`Returns` still match the current signature (parameter
names/count, return type) — a docstring that documents a removed
parameter or misses a new one is stale.

```fish
git log -p --since="30 days ago" -- '*.py' | grep -E "^\+def |^\+class " 
```

Use recent changes as a starting point for what's most likely to have
drifted, rather than checking every function blindly.

### 6. AI-readability check

- Single source of truth: grep for near-duplicate explanations across
  multiple doc files (same topic explained twice, possibly diverging)
- Entry point completeness: confirm the README links every `docs/*.md`
  file that exists (see step 3)
- Project `CLAUDE.md` (if present) doesn't repeat the global one and
  reflects the project's actual current state, not an outdated snapshot

### 7. Final report

```
# Doc audit — [project] — [date]

## Summary
- Root files: present / missing (list)
- docs/: N files, M orphans
- Docstrings: ruff --select D → X issues
- Staleness: Y suspect sections found

## Issues by severity

### Blocking (breaks onboarding or is actively wrong)
- [missing quickstart step, stale doc contradicting the code]

### Important
- [missing docstrings on public API, orphan docs files]

### Minor
- [missing CHANGELOG, missing Example sections]

## Recommendations
1. [highest-impact fix first — hand off to write-docs to execute]
```

## Guardrails

- This skill never edits or creates a file — it only lists and reports
- Don't demand a full `docs/` tree for a project too small to need one — judge based on actual project size/complexity, not a fixed checklist applied blindly
- Don't re-run a full audit immediately after a recent one with no significant change since — check `git log` first
