---
name: explore-project
description: Guided exploration phase for a project — analyzes existing features, identifies improvement directions (new features, spec evolutions, stack migrations when the current stack is too lightweight) by asking the user targeted questions to steer the research. Does NOT audit code quality. Use at the start of a session when the user wants to explore possible directions for a project, asks "what more could we do", or wants to assess whether their stack holds up against their ambitions.
---

# Explore Project — guided features/specs/stack exploration

> This skill is a **research phase**, not a code audit. It does not look at
> code quality — only at what the project does, what it could do, and whether
> the tools in place are suited to the ambitions.

## Steps

### 1. Read the project context without assuming

```fish
cat README.md 2>/dev/null | head -50
cat pyproject.toml 2>/dev/null
ls -la src/ 2>/dev/null
git log --oneline -n 15
```

Understand: what the project is for, which features already exist, which stack
is used, how long it has been active. Do not open code files — only the
structure and metadata.

### 2. Ask the framing questions BEFORE proposing anything

Never present directions without asking these questions first. Ask them
**one at a time or grouped by theme**, not all at once:

**Group A — General direction (always ask)**
- What frustrates you about the project as it is today?
- Are you looking to extend it (new features), make it more robust
  (reliability, performance, scale), or migrate it toward something more
  powerful?
- Is there a need or use case the project doesn't cover yet that you'd like it
  to cover?

**Group B — Stack and tools (ask if the stack seems constrained)**
- Does the current stack already feel at its limit on some points
  (performance, data volume, complexity)?
- Are there tools you use outside the project that you'd like to integrate into
  it?

**Group C — Constraints (ask if the direction isn't clear yet)**
- Is this a solo or collaborative project? Does the solution need to stay easy
  to maintain?
- Is it a personal/utility project or something meant to be shared/deployed
  seriously?

Adapt to what is already clear from the README and context. Do not ask
questions whose answer is obvious from the code/README already read.

### 3. Analyze along the expressed direction

Depending on the answers, steer the exploration along one or more axes:

#### Axis A — New features

Explore:
- What similar projects do that this one doesn't do yet
- Possible integrations with the existing stack (libs/APIs that add on without
  a rewrite)
- Common patterns/features in the domain (data pipeline, ML, web app...) the
  project doesn't have yet

Present: a list of concrete directions, ordered by effort vs value, each with:
short description, why it's relevant here, estimated effort (low/medium/high),
technical dependencies.

#### Axis B — Stack migration or replacement

Trigger when: the current stack seems too lightweight for the ambitions
(e.g. pandas on large volumes → Polars/DuckDB, SQLite → Postgres, monolithic
script → dbt pipeline, Flask → FastAPI, etc.)

Analyze:
- What the current stack does well and what it doesn't scale
- Modern alternatives that cover the use case with less friction
- The migration cost (rewrites needed, compatibility, learning curve)

Present: current vs alternative(s) comparison, with expected gains, migration
cost, and a direct recommendation (is the migration worth it now, or how far
out does it become necessary).

#### Axis C — Robustness and reliability

Trigger when: the project is functional but fragile, or the user mentions
reliability/debug problems.

Explore: monitoring, structured logging (if not yet in place), missing
integration tests, error handling, reproducibility.

### 4. Present the directions — concise format

```
# Exploration directions — [project name]

## Identified direction: [A / B / C / mixed]

## Priority directions

### 1. [Short title]
- What: [description, 2 lines max]
- Why now: [concrete reason tied to the project]
- Effort: [low / medium / high]
- Estimated impact: [short]

### 2. [...]
...

## To explore next (once the priority ones are done)
- [short, less detailed list]

## Open questions
- [what remains unclear and would need deeper work or a decision]
```

### 5. Propose the concrete next step

End with a simple question: "Which of these directions interests you most to
go further?" — and if the user chooses, chain directly into a deeper
exploration of that direction (specs, breakdown, prototyping) rather than
leaving the result hanging.

## Guardrails

- Never propose stack migrations just because it's "more modern" — only if the
  current stack genuinely hits a concrete limit on this project (volume,
  performance, complexity)
- Do not propose more than 5-6 directions at a time — the exploration must stay
  actionable, not become an exhaustive wishlist
- Stay within the project's domain: do not drift toward generic features if the
  project has a precise business scope
