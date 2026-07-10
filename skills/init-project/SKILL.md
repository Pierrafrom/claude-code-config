---
name: init-project
description: Interactively scaffolds a new project step by step — asks about context/stack/goals, team size, GitHub repo situation, other AI tools used by teammates, and rigor-level extras, then builds a working hello-world skeleton with all tooling configured (ruff, pytest, pydocstyle, pre-commit, logging, docs scaffold) and git/GitHub set up accordingly. Use when the user wants to start/init/bootstrap/scaffold a new project.
---

# Init Project — step-by-step interactive scaffold

> All commands below are calls to external tools (git, gh, pip, ruff,
> pytest, pre-commit) — identical regardless of the shell environment
> (Fish, Bash, PowerShell).

## Goal

Produce a working, fully-tooled hello-world skeleton through a short
interactive Q&A — not a fixed template stamped out blindly. Ask one logical
group of questions at a time, adapt what actually gets created to the
answers, and never create structure nobody asked for. Use `AskUserQuestion`
for branching/multiple-choice decisions; use plain conversational questions
for open-ended context (project description, goals) where fixed options
would be too restrictive.

Current scope is Python (the only stack with templates/tooling in this
config — see `rules/common/repo-structure.md`). If the project turns out
to need another language, say so explicitly and adapt using that
ecosystem's standard tools rather than forcing the Python templates.

## Always created, regardless of answers

These are non-negotiable baseline, not opt-in (see `rules/common/repo-structure.md`):
`.gitignore`, `.gitattributes`, `.pre-commit-config.yaml`, `pyproject.toml`
with the standard ruff/pytest/pydocstyle config, project `CLAUDE.md`,
`.github/copilot-instructions.md` (Copilot is used unconditionally,
regardless of team/solo or what teammates use — generate it via the
`copilot-instructions` skill every time, never skip it), `README.md`, the
`src/<package>/` + `tests/` layout, and a real hello-world entry point with
a matching passing test.

## Step 1 — Project context (open conversation, not multiple choice)

Ask in plain conversation:
- Project name (used for the folder/package name — confirm the slug, e.g. "my-project" → package `my_project`)
- One-line description and goal: what problem it solves, for whom
- Anything beyond plain Python worth knowing now: a specific framework (FastAPI, Dash, Streamlit, a CLI, a Discord bot, a data pipeline...), since this changes which optional deps and folders get added

Take the most reasonable default for anything not specified rather than
chaining endless follow-up questions — mention the assumption in one line.

## Step 2 — Team & collaboration

```
AskUserQuestion: "Solo project or with a team?"
  - Solo
  - With a team
```

If **with a team**:

```
AskUserQuestion (multiSelect): "Besides Claude Code and GitHub Copilot (always configured), do your teammates use any other AI tools?"
  - Cursor
  - Windsurf
  - Other / various
  - None of these
```

For every tool selected, generate the matching instructions file (see "AI
instructions for other tools" below) so teammates on a different tool get
equivalent context, not a worse experience.

```
AskUserQuestion: "Configure branch protection on main once the repo exists?"
  - Yes — require a PR + review before merging to main (Recommended for teams)
  - No — keep main open
```

Only ask this if a GitHub repo will exist (see Step 3) — branch protection
needs a repo to apply to.

## Step 3 — Repository

```
AskUserQuestion: "Repo situation?"
  - Already have a GitHub repo for this
  - Need to create one on GitHub
  - Local git only for now, no GitHub
```

- **Already have one**: ask for the owner/repo or URL, `git init` locally if needed, `git remote add origin <url>`.
- **Need to create one**: ask public/private, then `gh repo create <owner>/<name> --public|--private --source=. --remote=origin` (the GitHub MCP is connected — use it if more convenient than the CLI; `gh auth status` confirms auth before assuming it works).
- **Local only**: `git init`, no remote — skip GitHub-specific steps below (branch protection, CI badges referencing a remote, etc.).

Apply branch protection (if requested in Step 2) only **after** the first
commit exists and has been pushed — a branch with no commits can't be
protected:

```fish
gh api repos/<owner>/<repo>/branches/main/protection --method PUT \
  --input - <<'EOF'
{"required_pull_request_reviews":{"required_approving_review_count":1},"required_status_checks":null,"enforce_admins":false,"restrictions":null}
EOF
```

**Never create a remote repo, push, or apply branch protection without
explicit confirmation of the exact name/visibility from the user** — these
are visible/hard-to-reverse actions.

## Step 4 — Rigor-level extras

```
AskUserQuestion (multiSelect): "Anything else to set up now?"
  - GitHub Actions CI (ruff + mypy + pytest on every PR) (Recommended)
  - Issue and PR templates
  - CODEOWNERS (only offer if Step 2 was "with a team")
  - Dependabot for dependency updates
  - Docker (Dockerfile + docker-compose, from examples-perso/) — only offer if Step 1 suggests a long-running service; otherwise ask explicitly first
  - CodeGraph indexing (code intelligence MCP for faster code navigation — the index grows automatically as the project does, worth starting from day one)
```

Only offer the CodeGraph option if the `codegraph` CLI is actually on `PATH`
(check with `which codegraph`) — if it's missing, mention briefly that it's
available as a global install (`npm install -g @colbymchenry/codegraph`) but
don't install a new global tool without the user asking for it separately;
just skip the option for this run.

## Step 5 — Build the skeleton

Reuse `~/.claude/examples-perso/` as the base, adapted to the gathered
context — never copy it verbatim without filling in the project-specific
parts:

- **Folder tree** per `rules/common/repo-structure.md`: `src/<package>/{core,io}`, `tests/`, `scripts/`, `logs/.gitkeep`, `docker/` only if Docker was requested.
- **`pyproject.toml`**: copy from `examples-perso/pyproject.toml`, replace `name`/`description`, add any stack-specific dependency via `uv add <pkg>` (e.g. `fastapi`, `dash`, `streamlit`) rather than hand-editing the dependency list — keeps `uv.lock` in sync from the start.
- **`.gitignore`, `.gitattributes`, `.pre-commit-config.yaml`**: copy as-is from `examples-perso/`. Immediately run `pre-commit autoupdate` on the copied config to pin real current hook versions — the template ships with placeholder revs on purpose, never leave them in place.
- **`src/<package>/logging_config.py`**: copy from `examples-perso/logging_config.py`.
- **`README.md`**: built FROM the Step 1 context, not a generic template — one-liner, install, run, test commands that match what was actually set up here, link to `docs/` if created.
- **Project `CLAUDE.md`**: project-specific context only (goal, stack specifics, team) — never repeat the global `~/.claude/CLAUDE.md` (see `rules/common/repo-structure.md`).
- **`.github/copilot-instructions.md`**: always, unconditionally — invoke the `copilot-instructions` skill rather than duplicating its logic here.
- **`.github/workflows/ci.yml`** (only if CI was selected in Step 4): copy as-is from `examples-perso/.github/workflows/ci.yml` — same ruff + mypy + pytest gate as the local pre-commit hook, never improvised from scratch, so CI and local checks never silently drift apart. Check the `astral-sh/setup-uv` action version against its current release before leaving the template's pinned major version in place.
- **AI instructions for other tools** (only the ones selected in Step 2):
  - Cursor → `.cursor/rules/project.mdc` (current convention as of writing — verify via web search if this has moved, conventions for these tools shift fast)
  - Windsurf → `.windsurfrules`
  - Other/various/unlisted tool → `AGENTS.md` at the repo root (the emerging cross-tool vendor-neutral convention)
  - Base every one of these, and the Copilot file, on the same project context as `CLAUDE.md` — don't let them drift into a different description of the same project.
- **`CONTRIBUTING.md`**: only if "with a team" — branch/PR workflow, commit convention, how to run tests locally before pushing.
- **`CHANGELOG.md`**: only if requested or team — start with an empty `## [Unreleased]` section.
- **`docs/`**: skip entirely unless the project is clearly non-trivial. If created, only scaffold `docs/architecture.md` with an explicit placeholder marker (e.g. `<!-- TODO: fill in once the architecture has more than one obvious component -->`) — this is the one place where a placeholder file is fine even though `rules/common/documentation.md` normally says not to create empty doc stubs, because this is the initial scaffold, not an ongoing audit.
- **Hello world**: `src/<package>/__init__.py`, `src/<package>/main.py` (or `cli.py`) with one real function returning/printing a greeting, complete Google-style docstring, and `tests/test_main.py` with a passing test for it — this proves the whole toolchain (ruff, pytest, pydocstyle) actually works end to end, not just that files exist.
- **Docker** (only if requested): `Dockerfile` + `docker-compose.yml` from `examples-perso/`.
- **CodeGraph indexing** (only if requested in Step 4): run `codegraph init` at the project root once the hello-world skeleton files exist. `.codegraph/` is already covered by the `.gitignore` template (see `examples-perso/.gitignore`) — it's a local generated index, never committed. Report the index stats from the command output (files/nodes/edges) as part of Step 7's verification, not silently.

## Step 6 — Git & GitHub wiring

1. `git init` if not already a repo
2. `uv add --dev pre-commit && uv run pre-commit install` (never a bare `pip install` — see `rules/common/coding-style.md`)
3. First commit: `chore: initial project scaffold` (conventional format, see `rules/common/coding-style.md`)
4. Remote setup / `gh repo create` per Step 3, then push
5. Branch protection per Step 2/3, after the push

## Step 7 — Final verification (prove it actually works, don't just claim it)

```fish
uv run ruff check .
uv run mypy src
uv run pytest
uv run python -m <package>   # or however the hello-world entry point runs
```

Report the actual output of each, not an assumption. If anything fails,
fix it before declaring the scaffold done.

## Step 8 — Final report

Summary of: what was created, what's a placeholder still to fill in
(list explicitly — e.g. "`docs/architecture.md` — TODO", "`CHANGELOG.md`
— empty Unreleased section"), and the next suggested step (e.g. "rename
the hello-world module once the first real feature starts").

## Guardrails

- Never create something not asked for or not justified by an answer (no Docker, no CODEOWERS, no CI without it being selected in Step 4)
- Placeholders are explicit TODO markers, never fake/generic filler content pretending to be real documentation
- Never push to a remote, create a GitHub repo, or apply branch protection without explicit confirmation of the exact name/visibility/scope from the user first
- If `gh auth status` shows not logged in, say so and fall back to local-only git rather than failing silently on the GitHub steps
