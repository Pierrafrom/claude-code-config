# Global context

Computer science engineering student, data & AI focus. Comfortable across
the full stack but spends most time in Python data/ML work and general
software engineering.

## Stack & environment

- OS: WSL2 Ubuntu, Fish shell, Rust CLI tools (eza, bat, yazi, fastfetch)
- **Main stack: Python + shell + Docker.** This is where the config has
  detailed tooling and templates (ruff, pytest, mdformat, pydocstyle,
  `examples/`). The general rules (clean code, TDD, zero-warning lint,
  documentation discipline, git workflow) are language-agnostic and apply
  to any language — if a task involves a language with no dedicated
  template here, apply the same principles using that ecosystem's own
  standard equivalent tools rather than forcing Python tooling onto it.
- Python: data, ML, dashboards (Polars, pandas, LangChain, dbt/Snowflake)
- Frontend/web: TypeScript-first React/Next.js, shadcn/ui as the default
  component library. Detail in `rules/typescript/*` (typing, lint,
  patterns, architecture) and `rules/frontend/design-skill-routing.md`
  (which installed design skill/plugin to reach for, by surface type —
  marketing/landing vs product/dashboard, see that file before starting
  any UI work).
- **Dependency isolation is mandatory, for any language**: project
  dependencies always live in an isolated environment, never installed
  into a global/system interpreter. Concrete instantiation for Python
  (the main stack): **uv** — `uv add`/`uv sync`/`uv run`, never a bare
  `pip install` for project dependencies. `pip install --break-system-packages`
  is reserved for genuinely standalone tools installed outside any project
  context (a one-off throwaway script with no `pyproject.toml`). For
  another language, use that ecosystem's own standard isolation tool
  rather than skipping isolation.

## Expected rigor level: UNCOMPROMISING

See full detail in `rules/common/coding-style.md`, `rules/common/logging.md`,
`rules/common/documentation.md`, `rules/common/oop-design.md`,
`rules/common/config-standards.md`, `rules/python/lint-strict.md`,
`rules/python/oop-idioms.md`, `rules/python/typing-strict.md`. Summary of
non-negotiable pillars:

Domain-specific rule files (load by project context — routing logic is in each file):
- SQL / dbt / data warehouse style → `rules/data/sql-dbt.md`
- Python data engineering (Polars/pandas, Pandera, pipeline structure) → `rules/data/data-engineering.md`
- Database design (OLTP/3NF, Kimball/star schema, Data Vault, SCD) → `rules/data/db-design.md`
- MLOps / LLMOps / RAG pipelines → `rules/data/mlops-rag.md`
- DevOps (CI/CD, Docker, GitOps/IaC, observability, DevSecOps) → `rules/devops/devops.md`
- TypeScript/JavaScript typing, lint, patterns, architecture → `rules/typescript/*`
- Which frontend design skill/plugin to use, by surface type → `rules/frontend/design-skill-routing.md`
- Project directory structure by stack (Next.js, Turborepo, FastAPI, data science/MLOps, dbt) → `rules/common/project-architectures.md` (these are patterns to converge toward, not mandates — read the governing-rule note there before applying one rigidly)

- **Strict clean code**: short functions/single responsibility, zero dead code, zero duplication, explicit naming without relying on comments — split into sub-functions only when each has an autonomous, reusable meaning, not by dogmatic line-count (see the Ousterhout nuance in `rules/common/coding-style.md`)
- **Strict typing by default, in any language that supports it**: strictest checker setting available (Python baseline: `mypy --strict`, detail in `rules/python/typing-strict.md`), type hints mandatory on public signatures, types chosen to maximize readability rather than just satisfy the checker. Language-agnostic principle in `rules/common/coding-style.md`.
- **All code in English, no exceptions**: names (variables, functions, classes, files, branches), comments, docstrings, commit messages, and all documentation (README, docs/*, project CLAUDE.md) — detail in `rules/common/coding-style.md`. Conversation stays in the user's language of choice unless a switch is explicitly requested.
- **Favor object-oriented design by default**: SOLID (understood properly, not the shallow version), composition over inheritance, real encapsulation (Tell-Don't-Ask, invariants), Law of Demeter, Design by Contract, Value Objects vs Entities — avoid God Objects and Anemic Domain Models. Recognized design patterns are welcome, not just tolerated — they're a shared vocabulary. Language-agnostic detail in `rules/common/oop-design.md`, Python instantiation in `rules/python/oop-idioms.md`.
- **Systematic TDD**: test before code, 80%+ coverage on business logic
- **Zero-warning lint**: `ruff check .` (Python) / `biome check .` or `eslint .` (TS/JS) must be clean before any commit, not just zero errors
- **Generated configs always extend an official standard baseline, never written from scratch** — see `rules/common/config-standards.md`. Every generated lint/type/format config cites its source and, where relevant, flags instability under semver, so it stays checkable against drift instead of going stale silently.
- **Documentation written incrementally, by default, exactly like TDD**: not a separate pass done later or only when asked — every time a feature is implemented or existing code is changed, the docs describing it (docstrings, README, `docs/*`) are written or updated in the same pass, automatically, without being asked. Organized in a coherent `docs/` tree following community conventions, complete Google-style docstrings in English across the codebase, and structured so an AI assistant reading the repo gets the full project context, not half of it. Use the `write-docs` skill for this and `audit-docs` to check for gaps — detail in `rules/common/documentation.md`
- **Up-to-date docs required**: check via Context7 (MCP) before using an unfamiliar or fast-evolving lib/API — never rely solely on training memory for this
- **This config's own rules can go stale too**: before applying a rule that carries a freshness signal (an "as of" date, a "sources to watch" table, a version-pinned config example), flag it to the user citing the specific rule, ask before verifying online, and if it changed, update the rule file itself (not just the answer) — see `rules/common/rule-freshness.md` for the full procedure
- **Structured JSONL logging**: see `rules/common/logging.md` — designed so AI-assisted debugging is fast and cheap in tokens
- **Context-optimized repo structure**: see `rules/common/repo-structure.md` — focused files, no catch-all dumps, project CLAUDE.md that never repeats the global one

## Debugging behavior — core rule

**As soon as an error is reported and a logs folder exists in the project,
always check the structured logs first (targeted filtering via grep/jq on
ERROR level), before rereading the entire codebase or speculating.** Only
read the source code once the logs have pinpointed the problem area.

## Response style

- Direct, technical, concise — no filler, no unnecessary recaps
- Everything produced in code stays in English regardless of conversation
  language: see dedicated rule above and in `rules/common/coding-style.md`.
- If a request is ambiguous, take the most reasonable assumption and mention
  it in one line rather than blocking on a question
- No over-engineering: a simple solution that works > premature abstraction,
  but never at the expense of the clean-code rules above

## Shell: real technical detection (Fish/PowerShell), Bash forced for shared scripts

- Before giving a command to run directly (not a shared script), **detect the active shell via an environment variable** rather than assuming: `echo $FISH_VERSION` (or `$version`) for Fish, `$PSVersionTable.PSEdition` for PowerShell. A missing variable returns an empty string with no error — always check that the value is non-empty, not just the absence of an error.
- If the active shell has already been confirmed earlier in the same session, do not redetect on every command — only at the start of a session or if the context clearly changes (new machine, mention of another shell).
- Fish differences to respect: `set -x VAR value` (not `export`), `(cmd)` (not `$(cmd)`), no heredoc, `if test -f file`, `for x in (seq 1 10)`.
- PowerShell differences to respect: `$Env:VAR = "value"`, `Test-Path` for file conditions, `Select-String` rather than `grep` without WSL interop, here-strings `@"..."@` rather than bash heredoc. Full equivalence table in `rules/common/shell-fish.md`.
- **Explicit exception — shared/reusable scripts** (install.sh, CI scripts, scripts meant to run on any system): always written in Bash with `#!/usr/bin/env bash` as the shebang, invoked via `bash script.sh` — never any detection or dependency on the shell of whoever runs them.
- If a one-off command needs complex features with no simple equivalent in the detected shell, flag it and propose the closest alternative rather than giving a command that will silently fail.

## Token & context management

- **Default model: Sonnet.** Switch manually to a stronger model for complex
  multi-file debugging, architecture decisions, or after a first failed
  attempt on a hard task. Switch back down afterward.
- **Sequential-thinking (MCP)**: invoke explicitly (no reliable auto-trigger,
  like any MCP) for tasks suited to it — debugging a bug spanning multiple
  files, comparing architecture options, planning a non-trivial refactor.
  Do not invoke it for simple tasks (fixing an import, editing one line):
  normal internal reasoning is enough.
- **Sequential-thinking vs plan mode vs the `Plan` subagent**: these three
  overlap on "this needs real thinking before acting" — see
  `rules/common/reasoning-planning-routing.md` for the routing rule. Short
  version: plan mode is the default for any non-trivial implementation task
  (free, same context); sequential-thinking is an inline aid used inside
  whichever workflow is already running, not a competing one; the `Plan`
  subagent is reserved for when the user explicitly wants delegation itself
  (isolated/parallel/background planning), same bar as any other subagent.
- **CodeGraph (MCP)**: see the dedicated `## CodeGraph` section below for
  when and how to use it.
- **Caveman style**: reply telegraphically on mechanical tasks and
  confirmations — no articles, no pleasantries, no rephrasing, no "let me
  know". Code and result only. Disable it for: learning a new topic,
  architecture discussion, debugging an unknown error.
- **`/clear`** between unrelated tasks — a stale context wastes tokens on
  every following message.
- **`/compact`** proactively around 250k-300k tokens — not on hitting the
  limit. Good breakpoints: after an exploration phase before implementation,
  after a resolved debugging session, before switching topics entirely.
  Never compact in the middle of a multi-file refactor or an active
  debugging session.

## Permanent guardrails

- Never commit secrets/API keys — check before every `git add`
- Always read existing code before modifying it (no blind rewrites)
- Flag it if an added dependency is heavy or a lighter alternative exists
- Explicitly flag any constraint from this file that cannot be respected for a given task, rather than silently ignoring it

## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is a per-project opt-in.
