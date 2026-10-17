---
name: spec-plan
description: Turns an approved spec into a technical plan.md (tier L) — explores the codebase for reuse, picks an approach with the main rejected alternative, defines components and interfaces, risks, a global-rules check, ADR candidates and a requirement coverage table. Use after spec-new and spec-review when the user wants to plan the implementation of a spec, or asks for a technical plan from docs/specs/.
---

# Spec Plan — from spec to technical plan

Doctrine: `rules/common/spec-driven-development.md`. Template:
`templates/plan.md` (next to this file).

## Preconditions

- The spec exists and has no remaining `[NEEDS CLARIFICATION]`. If it has,
  stop and send the user back to `spec-new` / `spec-review`.
- Tier L only. For tier M, the spec's inline task list is enough.

## Steps

1. **Read** the spec fully, the project `CLAUDE.md`, `docs/decisions/`, and
   the layout rules that match the stack (`rules/common/project-architectures.md`
   and the per-stack files it points to).
2. **Explore for reuse**: find existing code the feature should build on
   (CodeGraph if `.codegraph/` exists, otherwise `rg`; delegate broad
   searches to a subagent to protect context). The plan must cite what it
   reuses by path — never recreate an existing class or helper.
3. **Check unfamiliar libraries** with Context7 first, web search as fallback
   (`rules/common/doc-lookup.md`).
4. **Choose the approach**: when several are valid, compare them briefly and
   ask the user with `AskUserQuestion` about decisions that are theirs to
   make; otherwise recommend one.
5. **Write** `docs/specs/<NNN-slug>/plan.md` from the template: approach,
   components and interfaces, reuse, data model, risks, rule check, ADR
   candidates, requirement coverage (every `R<n>` mapped).
6. **Create ADRs** in `docs/decisions/` only for hard-to-reverse choices,
   with the user's approval.
7. **Hand off**: propose `spec-review` (consistency) then `spec-tasks`.

## Guardrails

- Plans describe design, not code; include code only to pin down an interface.
- Every requirement must appear in the coverage table; flag any that the plan
  cannot satisfy rather than silently dropping it.
- No scope beyond the spec's goals; anything extra goes to open questions.
- Keep it short; a plan longer than its spec is a smell.
