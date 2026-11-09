---
name: spec-tasks
description: Breaks an approved spec and plan into ordered, test-first tasks in tasks.md, each small, with files, dependencies, parallel marks, a runnable verification command and the requirement ids it satisfies. Use after spec-plan when the user wants an implementation task list, or asks to break a spec down into tasks.
---

# Spec Tasks — ordered, test-first task list

Doctrine: `rules/common/spec-driven-development.md`. Template:
`templates/tasks.md` (next to this file). Test-first discipline:
`rules/common/coding-style.md` (TDD).

## Preconditions

`spec.md` and `plan.md` exist, no `[NEEDS CLARIFICATION]` remains. Tier L
only; tier M keeps its tasks inline in the spec.

## Steps

1. Read `spec.md` and `plan.md`.
2. For each requirement, derive the smallest sequence: **failing test ->
   minimal implementation -> refactor**. One behavior per task.
3. Order by dependency (shared types and data model first, then logic, then
   interface layers). Mark independent tasks `[P]`.
4. Give each task: the requirement id(s), files touched, dependencies, and
   a **runnable verification command** with its expected result.
5. End with the spec's end-to-end verification as the final task.
6. Check coverage: every `R<n>` appears in at least one task; list any
   that do not and ask the user.
7. Write `docs/specs/<NNN-slug>/tasks.md` from the template.
8. Hand off: propose `spec-review` (consistency across the three files),
   then implementation in a **fresh session**
   (`implement @docs/specs/<slug>/tasks.md following the spec and plan`).

## Guardrails

- A task that cannot be verified by a command is not a task; rewrite it.
- No task outside the spec's scope; extras go to open questions.
- Keep tasks small enough to review as one commit (see the git workflow in
  `rules/common/coding-style.md`).
