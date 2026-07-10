# Rule freshness — checking this config's own rules for drift

Companion to `rules/common/config-standards.md` (which covers *generated*
tool configs) and `rules/common/doc-lookup.md` (which covers *external*
library/API docs). This file covers a third case: the rules **already
written down in this config** can themselves go stale as ecosystems
evolve — a tool config example, an architecture pattern, or a "current
best practice" claim can be accurate today and wrong in a year.

## Which rules this applies to

Not every rule in this config is time-sensitive. Foundational principles
(SOLID, TDD, clean-code fundamentals, Law of Demeter, the general shape
of feature-based-vs-layer-based) don't meaningfully go stale — don't
second-guess those.

This check applies specifically to rules that carry a **freshness
signal**:
- An explicit "as of \<date/version\>" or "current gap" callout (e.g. the
  Biome/ESLint gap note in `rules/typescript/lint-strict.md`).
- A "Sources to watch" table (`rules/python/lint-strict.md`,
  `rules/typescript/lint-strict.md`).
- A concrete tool-version-pinned config example (a specific
  `typescript-eslint` preset, a specific `ruff` category list, a
  framework-specific directory tree like
  `rules/frontend/nextjs-architecture.md`).
- A named fast-moving ecosystem in general, even without an explicit date
  — frontend tooling, LLM/RAG practices, cloud/DevOps tooling.

## Procedure — before applying a flagged rule to a real task

1. **Notice the signal.** If the rule about to be applied carries one of
   the markers above, don't apply it silently as settled truth.
2. **Warn the user, citing the specific rule(s).** Name the file, the
   section, and the specific claim suspected of drift — not a vague "this
   might be outdated." Example: *"`rules/typescript/lint-strict.md`'s
   Biome/ESLint gap note is dated mid-2026 and Biome ships fast — want me
   to verify it's still accurate?"*
3. **Ask before searching.** Don't spend a web search automatically —
   confirm with the user first. This mirrors `rules/common/doc-lookup.md`'s
   "when NOT to check" economy: verification has a cost, and the user
   might already know the rule is still fine.
4. **If yes: verify.** Context7 first for a library/framework-specific
   claim (per `rules/common/doc-lookup.md`), web search otherwise. Check
   the specific claim, not the whole surrounding topic.
5. **If the rule changed: update the config file itself, not just this
   session's answer.** Edit the relevant file under this repo (which is
   what `~/.claude/` symlinks to — see the repo's README), cite the new
   source and check date in the diff, then commit and push following the
   same pattern already used to build this config out. A stale rule left
   uncorrected after being flagged is worse than one nobody noticed yet.
6. **If the rule is still accurate: say so briefly** and, if the file has
   an explicit "as of" date, consider refreshing it to the verification
   date so the same check doesn't unnecessarily re-trigger soon after.
7. **If the user says no:** proceed with the existing rule for the
   current task as-is — don't block on an update the user didn't ask for.

## Expected behavior from Claude

- Apply this check when a flagged rule is about to materially shape a
  concrete deliverable (a generated config file, a chosen project
  structure) — not on every passing mention of a rule in conversation.
- One flag per relevant rule, not a blanket "some of my rules might be
  outdated" disclaimer — cite specifics or don't raise it.
- Never silently patch a rule file without the user's go-ahead from step
  3 — the confirmation gate is the point of this whole procedure.
