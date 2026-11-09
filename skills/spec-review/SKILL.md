---
name: spec-review
description: Reviews a spec in two modes — before implementation (quality checklist and spec/plan/tasks consistency) and after implementation (fresh-context check that every requirement is implemented and tested and nothing out of scope changed), by delegating to the spec-reviewer agent. Use when the user asks to review, audit, challenge or validate a spec, or to check an implementation against its spec.
---

# Spec Review — pre- and post-implementation

Doctrine and quality bar: `rules/common/spec-driven-development.md`.
Execution is delegated to the `spec-reviewer` agent so the review happens in
a fresh context, uninfluenced by whoever wrote the spec or the code.

## Choose the mode

- **pre** — before any code: the spec (and plan/tasks if they exist).
- **post** — after implementation: the diff (`git diff <base>...HEAD` or the
  working tree) against the spec.
If the user did not say, infer from whether the implementation exists and
state the choice in one line.

## Steps

1. Locate the spec folder (`docs/specs/<NNN-slug>/`); ask if several match.
2. Launch the `spec-reviewer` agent with: the mode, the spec folder path,
   and for **post** the diff range and the test/verification commands from
   the spec. Ask for findings only, no rewrites.
3. Relay the findings grouped as blocking / important / minor, each tied to
   a requirement id and, for **post**, to a file and line.
4. **Triage with the user**: fix blocking and important items; treat minor
   as optional. A reviewer asked for gaps will often find some even in sound
   work — do not chase style or hypothetical edge cases outside the stated
   requirements.
5. For **pre** findings, offer to apply the spec edits directly (update
   `spec.md`, re-run the review). For **post** findings, list the fixes to
   implement, run the verification commands, and re-review only if blocking
   items were fixed.

## What each mode checks

**pre**: ambiguity; untestable or non-atomic criteria; missing non-goals,
edge cases, failure modes or numbers; invented context; code or
implementation detail in the spec; unresolved `[NEEDS CLARIFICATION]`;
requirement ids missing from plan/tasks; plan items with no requirement;
plans recreating existing code.

**post**: each requirement implemented and covered by a passing test;
out-of-scope changes; contract mismatches; verification commands actually
run, with evidence (output), not asserted.

## Guardrails

- Never edit code in review mode.
- Evidence over assertion: run the spec's verification step in **post** mode
  and report the result.
