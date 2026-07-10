# Config generation — extend official standards, never start from scratch

Applies to every generated tool config, in any language: linter, formatter,
type checker, compiler options. Companion to `rules/common/coding-style.md`
(the "strictest setting available" principle) — this file is about *how*
to reach that strict setting without inventing a bespoke rule set.

## Core principle

Always start from an official, actively maintained standard config and
extend it minimally. Never write a lint/type/format config from scratch.

The official baseline is maintained by a dedicated team, receives security
and bug fixes, and encodes years of community feedback that a from-scratch
config can't replicate. Every custom rule added on top is maintenance debt
— it has to be re-justified every time the underlying tool changes its own
defaults.

Concretely: `extend-select` / `extends` / `extend` (whatever the tool calls
its inheritance mechanism) over redeclaring the full rule set by hand. See
`rules/python/lint-strict.md` and `rules/typescript/lint-strict.md` for the
per-language instantiation.

## Meta-rules for Claude when generating a config

1. **Never a config from scratch.** Always start from the tool's official
   preset (`ruff`'s default baseline, `typescript-eslint`'s
   `strictTypeChecked`, `js.configs.recommended`, `biome:recommended`,
   TypeScript's `strict: true`, mypy's `strict = true`) and layer additions
   on top with the tool's extension mechanism.
2. **Override as little as possible.** Each custom rule is something a
   human has to remember exists and re-justify later. If the official
   preset already covers it, don't redeclare it.
3. **Always comment the source and the version at generation time.** Every
   non-trivial config block gets a one-line comment pointing at the
   canonical doc and, where it matters, the tool version:
   ```
   // Base: typescript-eslint.io/users/configs/ — v8.x (as of generation)
   // Check the changelog for breaking changes on major version bumps.
   ```
4. **Flag configs that are explicitly unstable under semver.** Some
   official presets (e.g. `typescript-eslint`'s `strict` /
   `strict-type-checked`) are documented by their maintainers as not
   following strict semver — their rule set can change on a minor bump.
   Say so explicitly in the comment when using one.
5. **Severity mirrors category, not personal taste.** Correctness/security
   rules (bugs, floating promises, SQL injection patterns) are `error`.
   Style/idiomatic rules are `warn`. Never downgrade a correctness rule to
   `warn` for convenience.
6. **Always carve out a test-file override.** Production code and test
   code have different legitimate needs (mocking, relaxed typing in
   fixtures). Provide a `per-file-ignores` / `overrides` block for
   `tests/**`, `**/*.test.*`, `**/*.spec.*` rather than loosening the
   global config.
7. **Point to where to check for drift.** End each generated config with a
   pointer to the changelog/release notes to watch — see the per-language
   "sources to watch" table in `rules/python/lint-strict.md` and
   `rules/typescript/lint-strict.md`. A config is a snapshot of "current
   best practice as of generation time," not a permanent truth — flag it
   as such rather than presenting it as settled forever.
8. **Before relying on one of this config's own time-sensitive rules**
   (not just when generating a fresh config), see
   `rules/common/rule-freshness.md` for the check-before-applying
   procedure: flag the specific rule, ask before verifying online, update
   the file itself if it changed.

## Why this matters more for Claude than for a human author

A human maintainer builds tacit knowledge of when a tool's defaults
changed. Claude's training data has a cutoff and no persistent memory of
a specific project's tool versions — treating every generated config as
provisional, sourced, and versioned is what keeps that gap from silently
producing stale advice.
