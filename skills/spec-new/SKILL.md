---
name: spec-new
description: Guides the user through creating a high-quality project or feature spec by interview — reads the project context first, triages the size, asks non-obvious questions in themed rounds with AskUserQuestion, then writes docs/specs/<NNN-slug>/spec.md from a template with testable acceptance criteria, non-goals and a verification step. Use when the user wants to write a spec, start a new feature or project spec-first, do spec-driven development, or says "let's spec this".
---

# Spec New — interview-driven spec creation

Doctrine, quality bar and anti-patterns: `rules/common/spec-driven-development.md`.
Read it before starting. Template: `templates/spec.md` (next to this file).

## Language

Converse in the user's language; write the spec file in English (code and
docs are English per `rules/common/coding-style.md`).

## Steps

### 1. Read the context — no obvious questions

Read `README.md`, the project `CLAUDE.md`, `docs/specs/` (existing specs and
the next free `NNN`), `docs/decisions/`, and the top-level layout. If the
brief refers to existing code, find it (CodeGraph if `.codegraph/` exists,
otherwise `rg`). Never ask what these files already answer.

### 2. Triage the tier

State the tier (S / M / L, see the rule) in one line with the reason.
- **S**: say no spec is needed and offer to go straight to TDD. Stop.
- **M / L**: continue. If unsure, ask once.

### 3. Interview in themed rounds

Use `AskUserQuestion` (2-4 questions per round, concrete options with a
recommended default, user can answer "Other"). Stop a round early when the
answers are clear. Skip rounds that do not apply. Rounds, in order:

1. **Problem and users** — who, what pain, what happens today.
2. **Scope and non-goals** — what is in, and what must explicitly not be built.
3. **Behavior** — main flows, rules, outputs; turn each into an acceptance
   criterion (EARS or Given/When/Then).
4. **Edge cases and failures** — invalid input, concurrency, partial failure,
   empty/loading/error states, abuse.
5. **Non-functional** — volumes, latency, security, accessibility, with numbers.
6. **Data and contracts** — interfaces involved at the shape level; which
   existing code to reuse.
7. **Risks and dependencies** — external services, unknowns, reversibility.
8. **Verification** — how will we know it works end to end.

Rules for questions: dig into hard, non-obvious points; one decision per
question; propose a default and say why; never invent facts — when the user
does not know, record a `[NEEDS CLARIFICATION]` instead of guessing.
A typical tier M interview is 10-25 questions; tier L may need more.

### 4. Confirm the outline

Before writing, present a compact outline: goals, non-goals, the numbered
acceptance criteria (one line each), open questions. Get explicit approval or
adjust.

### 5. Write the spec

Create `docs/specs/<NNN-slug>/spec.md` from `templates/spec.md`. Respect the
length budget (tier M at most ~150 lines). No code, no invented context, cite
existing files by path. For tier M include the inline task list; for tier L
leave tasks to `spec-tasks`.

### 6. Hand off

Report: file path, tier, number of requirements, remaining
`[NEEDS CLARIFICATION]`. Then propose, in order: `spec-review`
(pre-implementation), then `spec-plan` + `spec-tasks` for tier L, or
implementation in a **fresh session** referencing the spec by path for
tier M. Do not start implementing in this session.

## Guardrails

- Never write the spec before the outline is approved.
- Never leave `[NEEDS CLARIFICATION]` unmentioned in the hand-off.
- Do not create plan.md or tasks.md here.
- Link the new spec from the README or `docs/` index (propose the edit).
