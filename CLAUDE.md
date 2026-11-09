# Global context

Computer science engineering student, data & AI focus. Comfortable across
the full stack but spends most time in Python data/ML work and general
software engineering.

## Stack & environment

- OS: WSL2 Ubuntu, Fish shell, modern CLI toolset (eza, bat, fd, ripgrep,
  dust, duf, procs, btop, delta, xh, zoxide, tldr, superfile, fzf) — prefer
  these over legacy equivalents for commands suggested on this machine;
  table in `rules/common/modern-cli-tools.md`.
- **Main stack: Python + shell + Docker** (ruff, pytest, mypy, uv). The
  general rules are language-agnostic: for a language without a dedicated
  template, apply the same principles with that ecosystem's standard tools.
- Python: data, ML, dashboards (Polars, pandas, LangChain, dbt/Snowflake).
- Frontend: TypeScript-first React/Next.js, shadcn/ui. Read
  `rules/frontend/design-skill-routing.md` before any UI work.
- C/C++: coursework and personal projects, not safety-critical by default.
- **Dependency isolation is mandatory, for any language**: never install
  project dependencies into a global interpreter. Python: `uv add` /
  `uv sync` / `uv run`, never a bare `pip install` (exception: standalone
  one-off script without `pyproject.toml`).

- **Two environments**: WSL2/Fish for code and practical work; native
  Windows/PowerShell for course notes (LaTeX via Docker, OneDrive folder
  `GI05/`). Rules in `rules/common/shell-windows.md`.

## Rules layout

Always loaded from `rules/common/`: `coding-style`, `config-standards`,
`doc-lookup`, `documentation`, `modern-cli-tools`, `reasoning-planning-routing`,
`rule-freshness`, `shell-fish`, `shell-windows`. All other rules (`logging`,
`oop-design`, `project-architectures`, `repo-structure`, and the `python/`,
`typescript/`, `cpp/`, `data/`, `devops/`, `frontend/` folders) carry a
`paths:` frontmatter and load only when a matching file is read. When
starting a project from scratch (no file read yet), read the relevant rule
files explicitly.

## Rigor level: UNCOMPROMISING

Details live in `rules/`; non-negotiable pillars:

- **Clean code**: single responsibility, zero dead code, zero duplication; split into sub-functions only when each has an autonomous meaning (`rules/common/coding-style.md`).
- **Strict typing** in any language that supports it (`mypy --strict`, TS `strict`); type hints mandatory on public signatures.
- **All code in English**: names, comments, docstrings, commits, docs. Conversation stays in the user's language.
- **OOP by default**: SOLID, composition over inheritance, real encapsulation (`rules/common/oop-design.md`).
- **Systematic TDD**: test first, 80%+ coverage on business logic.
- **Zero-warning lint** (`ruff check .`, `biome check .` / `eslint .`) before any commit.
- **Generated configs extend an official baseline**, cite source and version (`rules/common/config-standards.md`).
- **Docs written incrementally, like TDD**, never as a later pass: docstrings, README, `docs/*` updated in the same change. Skills `write-docs` / `audit-docs` (`rules/common/documentation.md`).
- **Up-to-date docs**: check Context7 before using an unfamiliar or fast-evolving lib/API.
- **Rules can go stale**: flag and ask before applying a rule with a freshness signal (`rules/common/rule-freshness.md`).
- **Structured JSONL logging** (`rules/common/logging.md`) and **context-optimized repo structure** (`rules/common/repo-structure.md`).

## Debugging — core rule

When an error is reported and a `logs/` folder exists, check the structured
logs first (grep/jq on ERROR level) before rereading code or speculating.

## Response style

- Direct, technical, concise — no filler, no unnecessary recaps.
- If a request is ambiguous, take the most reasonable assumption and state
  it in one line rather than blocking on a question.
- No over-engineering, but never at the expense of the clean-code rules.
- **Caveman style** on mechanical tasks and confirmations: telegraphic, code
  and result only. Disable for learning, architecture discussion, debugging
  an unknown error.

## Shell

Before a one-off command, detect the active shell once per session
(`echo $FISH_VERSION` for Fish, `$PSVersionTable.PSEdition` for PowerShell;
an empty value means wrong shell, not an error). Shared/reusable scripts are
always Bash with `#!/usr/bin/env bash`, never shell-dependent. Equivalence
table in `rules/common/shell-fish.md`.

## Token & context management

- **Default model: Sonnet.** Switch up for complex multi-file debugging,
  architecture decisions, or after a failed attempt on a hard task.
- **Planning**: plan mode by default for non-trivial implementation;
  sequential-thinking (MCP) inline for one hard reasoning step, not for
  trivial edits; `Plan` subagent only on explicit request
  (`rules/common/reasoning-planning-routing.md`).
- **CodeGraph**: only if a `.codegraph/` directory exists at the repo root;
  use `codegraph_explore` (MCP) or `codegraph explore "<query>"` before
  grep/Read. Not applicable to markdown/Fish-only repos (this config repo,
  `~/Code/dotfiles`) — don't suggest indexing them.
- `/clear` between unrelated tasks. `/compact` proactively around 250-300k
  tokens at a natural breakpoint, never mid-refactor or mid-debugging.

## Permanent guardrails

- Never commit secrets/API keys — check before every `git add`.
- Always read existing code before modifying it.
- Flag a heavy dependency or a lighter alternative.
- Flag any constraint from this file that cannot be respected, never ignore it silently.
