# Spec-driven development — lightweight, interview-first

Doctrine behind the `spec-new`, `spec-plan`, `spec-tasks` and `spec-review`
skills and the `spec-reviewer` agent. The goal is a spec that makes
implementation (by Claude, in a fresh session) unambiguous — not
paperwork. Scale the ceremony to the size of the work.

## Tiers — decide before writing anything

| Tier | Trigger | Artifacts |
|---|---|---|
| S | The diff fits in one sentence; a bug with a clear repro | None — TDD directly |
| M | One feature touching a few files | `docs/specs/<NNN-slug>/spec.md`, with an inline task list |
| L | New project, multi-component, or hard-to-reverse choices | `spec.md` + `plan.md` + `tasks.md`, ADRs in `docs/decisions/` |

Over-specifying small work is a failure mode, not rigor: published
experiments with heavy pipelines produced thousands of lines of Markdown
for hundreds of lines of code, slower than iterating on code directly.

## Spec level

- **Spec-first** (default): the spec guides one change; it is correct at
  merge time and may then go stale.
- **Spec-anchored**: only for durable behavior that outlives a change
  (economy rules, public API contracts, permissions). The spec is then
  updated in the same change as the code, per
  `rules/common/documentation.md`.
- Never spec-as-source (generating code from specs only) — non-determinism
  makes it unreliable.

## Layout

```
docs/specs/<NNN-slug>/
├── spec.md     # what and why — behavior and contracts, no implementation
├── plan.md     # tier L: how — approach, components, reuse, risks
└── tasks.md    # tier L: ordered, test-first, each with a verification command
```

The project's `CLAUDE.md` plus this global config already play the role of
a "constitution"; do not create a separate one. Link every spec from the
README or `docs/` index.

## Quality bar for `spec.md`

- **Problem and users**: who needs this and why, in a few lines.
- **Goals and explicit non-goals**: out-of-scope items are as important as
  scope; they stop over-engineering.
- **Acceptance criteria**: one atomic, testable statement each, with an id
  (`R1`, `R2`...). Use EARS patterns (`The system shall...`, `WHEN <event>
  the system shall...`, `WHILE <state>...`, `IF <unwanted condition> THEN...`)
  or Given/When/Then. Quantify anything measurable.
- **Edge cases and failure modes**: invalid input, concurrency, partial
  failure, empty/loading/error states.
- **Non-functional requirements** with numbers (latency, volume, limits).
- **Contracts at interface level**: names, shapes, error cases of the
  interfaces involved — not implementation. Reference existing files and
  patterns by path instead of redescribing them.
- **Open questions** marked `[NEEDS CLARIFICATION]`; none may remain when
  planning or coding starts.
- **End-to-end verification step**: a command or scenario that proves the
  feature works.
- **Self-contained**: a fresh session reading only the spec and the repo
  can implement it.
- **Length budget**: tier M spec at most ~150 lines, one line per
  requirement.

## Anti-patterns

- Inventing context, users or constraints nobody stated.
- Code, schemas or pseudo-code in the spec (belongs in the plan, and only
  when it clarifies an interface).
- Duplicating what the code or another doc already says (single source of
  truth).
- Plans that recreate classes the repo already has — the plan must cite what
  it reuses.
- Treating spec approval as a waterfall gate on small changes.
- Checklists nobody can verify; the AI may skip or over-follow them, so
  rely on executable checks.

## Workflow

1. **Interview** (`spec-new`): Claude reads project context first, then
   asks non-obvious questions with `AskUserQuestion` in themed rounds, and
   confirms an outline before writing.
2. **Review** (`spec-review`, pre-implementation): ambiguity, untestable
   criteria, missing non-goals, invented context.
3. **Plan and tasks** (tier L): `spec-plan`, then `spec-tasks`.
4. **Implement in a fresh session** with the spec referenced by path
   (`@docs/specs/<slug>/spec.md`), TDD per `rules/common/coding-style.md`:
   each requirement id maps to at least one test.
5. **Review against the spec** (`spec-review`, post-implementation) in a
   fresh context; fix only gaps that affect correctness or stated
   requirements.

Relationship to other tools: plan mode remains the default for ordinary
implementation (`rules/common/reasoning-planning-routing.md`); a spec
comes first when the feature is large, ambiguous or new-project scale.

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| Claude Code best practices (interview, verification) | code.claude.com/docs/en/best-practices | Doc updates |
| Spec levels and tool critique | martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html | New SDD analyses |
| spec-kit workflow | github.com/github/spec-kit | Command set changes |
| EARS | secondary blogs only | Treat as convention, not standard |
