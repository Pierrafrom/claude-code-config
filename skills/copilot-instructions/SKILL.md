---
name: copilot-instructions
description: Generates or updates the .github/copilot-instructions.md file for GitHub Copilot, based on the project's actual code standards, conventions, and context — designed to maximize the reliability of Copilot's inline completions in the editor. Use when the user wants to configure/generate/update a project's Copilot instructions, or mentions wanting Copilot to know its conventions.
---

# Copilot Instructions — generation for reliable completions

> All commands below are calls to external tools or file reads —
> identical regardless of the shell environment.

## Goal

Produce a `.github/copilot-instructions.md` that makes Copilot's **inline
completions** consistent with the project's actual standards — not a
generic document copied from a template, but extracted from the real
context (stack, conventions already in place, actual structure).

## Difference from an audit or an agent

This skill fixes nothing and reviews nothing — it produces a single artifact:
the instructions file. It builds on what `rules/` and `CLAUDE.md`
already define for Claude, transposed into the format Copilot understands.

## Steps

### 1. Inventory the actual project (never guess)

```fish
find . -name "*.py" -not -path "*/.venv/*" | head -20
cat pyproject.toml 2>/dev/null
cat README.md 2>/dev/null | head -30
git log --oneline -n 20
```

Identify: the actual stack (versions in `pyproject.toml`), folder
structure (`src/`, `tests/`, naming conventions already in place), lint/test
tools already configured, commit style already used.

### 2. Never duplicate what the linter already enforces

Per Copilot best practices: focus on rules that are
**non-trivial and not automatically detectable** by `ruff`/a formatter.
No point writing "use 4-space indentation" if `ruff format` already
enforces it — Copilot doesn't need that restated, it wastes the
instruction budget for no gain.

Focus on:
- The project's business context (what the app does, why)
- Architecture conventions (where things go, why this split)
- Preferred lib/pattern choices with their justification (the *why*
  improves Copilot's decisions in ambiguous cases, not just the raw
  rule)
- Concrete examples of preferred vs avoided patterns — Copilot responds
  better to examples than to abstract rules

### 3. Build the file — required structure

Always follow this structure, staying under ~1000 lines (quality
degrades beyond that):

```markdown
# Copilot Instructions — [project name]

## Project summary
[One or two sentences: what the app does, for whom]

## Tech stack
- Language: Python [exact version from pyproject.toml]
- Key dependencies: [list main libs with their role, not just names]
- Tools: ruff (lint+format), mypy --strict (typing), pytest (tests), [Docker if present]

## Code conventions
[Non-trivial rules only — not what ruff already enforces]
- [Convention] — because [reason]
- Preferred example:
  ```python
  [short snippet illustrating the good pattern]
  ```
- Avoid:
  ```python
  [snippet of the corresponding anti-pattern]
  ```

## Project structure
[Annotated layout — where things go and why]

## Tests
- Framework: pytest
- Naming convention: test_<behavior>_<condition>
- Expected coverage: 80%+ on business logic

## Security
- Never a hardcoded secret — environment variables only
- [Other project-specific constraints if relevant]
```

Adapt the sections if a category has nothing specific to say (don't
fill in a section just for the sake of it — an empty or generic
section doesn't help Copilot and just bloats the file).

### 4. File-type-specific rules

If the project has different conventions depending on file type (e.g.
tests vs business code, or a submodule with particular rules),
propose an additional `.github/instructions/<name>.instructions.md`
file with an `applyTo` frontmatter:

```markdown
---
applyTo: "tests/**/*.py"
---
## Test-specific conventions
[rules specific to test files]
```

Only create this additional file if a real distinction exists — not
by default.

### 5. Write the file

```fish
mkdir -p .github
```

Create `.github/copilot-instructions.md` with the content built in step 3.

### 6. Final check

- Reread the produced file: every line should provide information Copilot
  wouldn't guess on its own from the code — otherwise cut it
- Confirm no sensitive data (key, identifier, non-public personal info)
  was included in the examples or context
- Remind the user to commit the file — an uncommitted file only
  helps on their own machine, not for the rest of the project

## Guardrails

- Never invent a convention that doesn't actually exist in the project — extract it from existing code/config, ask if a needed piece of information can't be found
- Never exceed ~1000 lines — cut rather than expand
- Never include real sensitive data in examples (always generic, example-style values)
- If the file already exists, read it first and propose a targeted update rather than blindly rewriting everything
