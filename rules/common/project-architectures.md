# Project architectures — directory trees by stack

Companion to `rules/common/config-standards.md`: that file covers tool
*configs* (lint/type/format), this one covers project *directory
structure* — how to lay out folders for a given stack so the result is
legible to any reader, human or AI, without re-deriving the layout from
scratch each time.

## Governing rule — these are guidelines, not mandates

**These are patterns worth converging toward for readability, not rules
to force onto a project that doesn't fit them.** Every tree in this file
and its per-stack companions is a common, well-understood shape — useful
precisely because a reader (or Claude) who already knows the pattern
doesn't have to re-learn the project's layout from zero. But a real
project's constraints (team size, existing code, a genuinely different
access pattern) can justify deviating from it.

The goal is the right compromise, not dogmatic compliance:
- Don't force a feature-based split on a project with 3 routes and one
  developer — that's over-engineering in the other direction.
- Don't force the hexagonal FastAPI layout (`rules/python/fastapi-architecture.md`)
  on a small internal tool — it's justified for auditability/complexity,
  not by default.
- If a project already has an established, coherent layout that diverges
  from what's documented here, don't silently "fix" it to match — flag
  the divergence if it seems accidental, respect it if it's deliberate.

Approaching a common pattern is valuable because it makes the codebase
legible at a glance — not because deviation is inherently wrong. When in
doubt, prefer the simpler structure that fits the project's actual size
today over the more elaborate one sized for a hypothetical future project
(same YAGNI posture as `rules/common/coding-style.md`).

## Two competing philosophies

- **Feature-based / domain-based**: files grouped by business capability
  (`users/`, `billing/`, `orders/`). Each folder holds everything related
  to that feature — routes, services, models, tests. Navigation is "what
  does this do," not "what kind of file is this."
- **Layer-based / technical**: files grouped by technical role
  (`controllers/`, `services/`, `models/`). Readable for small projects,
  collapses at scale — changing one feature means touching every layer
  folder.

**2026 consensus**: feature-based first, with technical-layer subfolders
*inside* each feature. Shared infrastructure (DB client, global config,
auth) stays in a global folder. Decision rule: if changing one feature
requires touching 5+ different top-level folders, the project is
layer-based and that's a problem worth fixing.

## Colocation rule

A file lives as close as possible to where it's used:
- Used in one feature only → lives inside that feature's folder.
- Shared by 2+ features → moves up one level to a shared folder scoped to
  those features.
- Genuinely global → `shared/` or `lib/`.

## Per-stack detail

| Stack | File |
|---|---|
| Next.js App Router (frontend/fullstack) | `rules/frontend/nextjs-architecture.md` |
| Turborepo monorepo (JS/TS fullstack) | `rules/frontend/monorepo-turborepo.md` |
| FastAPI (Python backend, 3 complexity levels) | `rules/python/fastapi-architecture.md` |
| Data science / MLOps (Python) | `rules/data/project-structure.md` |
| dbt data warehouse | `rules/data/sql-dbt.md` (architecture section) |

## Decision tree

```
This project is...
│
├── Frontend / fullstack React
│   ├── → Next.js App Router (rules/frontend/nextjs-architecture.md)
│   └── Multiple related apps? → Turborepo monorepo (rules/frontend/monorepo-turborepo.md)
│
├── Python backend / API
│   ├── MVP or small service (~10 routes, 2-3 devs) → FastAPI level 1 (layer-based)
│   ├── Production API → FastAPI level 2 (feature-based, the default)
│   └── Complex / audited / multi-backend system → FastAPI level 3 (hexagonal)
│
├── Data / ML
│   ├── Exploration / research → Cookiecutter Data Science v2 layout
│   └── Production pipeline → MLOps layout
│
└── Data warehouse / analytics
    └── → dbt three-layer structure (staging / intermediate / marts)
```

## `STRUCTURE.md` at the project root

Regardless of which layout is chosen, a short `STRUCTURE.md` at the
project root documenting the *decisions* — why a feature lives where it
does, where a new component should go, how the dependency graph is meant
to flow — is the single most useful onboarding document, for a new human
contributor and for Claude working on the project cold. It records the
*why* behind the layout, the same principle as
`rules/common/coding-style.md`'s "comment the why, never the what,"
applied at the folder level instead of the line level.
