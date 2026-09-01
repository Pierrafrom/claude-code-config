---
name: init-project
description: Interactively scaffolds a new project step by step — asks about stack, context/goals, team size, GitHub repo situation, other AI tools used by teammates, and rigor-level extras, then builds a working hello-world skeleton with all tooling configured (Python: ruff, pytest, pydocstyle; C/C++: CMake, vcpkg, clang-format, clang-tidy, cppcheck; plus pre-commit, logging, docs scaffold for either) and git/GitHub set up accordingly. Use when the user wants to start/init/bootstrap/scaffold a new project.
---

# Init Project — step-by-step interactive scaffold

> All commands below are calls to external tools (git, gh, uv, ruff,
> pytest, cmake, vcpkg, pre-commit) — identical regardless of the shell
> environment (Fish, Bash, PowerShell).

## Goal

Produce a working, fully-tooled hello-world skeleton through a short
interactive Q&A — not a fixed template stamped out blindly. Ask one logical
group of questions at a time, adapt what actually gets created to the
answers, and never create structure nobody asked for. Use `AskUserQuestion`
for branching/multiple-choice decisions; use plain conversational questions
for open-ended context (project description, goals) where fixed options
would be too restrictive.

Templates/tooling exist in this config for **Python** and **C/C++** — see
`rules/common/repo-structure.md` (Python) and `rules/cpp/build-architecture.md`
(C/C++), both backed by copy-paste config in `examples/`. If the project
turns out to need another language, say so explicitly and adapt using that
ecosystem's own standard tools rather than forcing either template.

## Step 0 — Stack

```
AskUserQuestion: "What's this project's primary language/stack?"
  - Python (data/ML, scripts, APIs, dashboards)
  - C/C++ (systems, coursework labs, CLI tools)
  - Something else (I'll say what)
```

This decides which branch of Steps 5 and 7 applies below. For "something
else," ask what it is, confirm there's no dedicated template in this config,
and proceed using that ecosystem's own standard equivalent tools (its own
lockfile/dependency isolation, its own lint/format/test stack) rather than
adapting the Python or C/C++ templates to fit.

## Always created, regardless of answers

Language-agnostic baseline, non-negotiable (see `rules/common/repo-structure.md`):
`.gitignore`, `.gitattributes`, `.pre-commit-config.yaml`, project `CLAUDE.md`,
`.github/copilot-instructions.md` (Copilot is used unconditionally,
regardless of team/solo or what teammates use — generate it via the
`copilot-instructions` skill every time, never skip it), `README.md`, and a
real hello-world entry point with a matching passing test.

Stack-specific, per Step 0's answer:
- **Python**: `pyproject.toml` with the standard ruff/pytest/pydocstyle
  config, `src/<package>/` + `tests/` layout.
- **C/C++**: `CMakeLists.txt` + `CMakePresets.json` + `vcpkg.json` +
  `.clang-format` + `.clang-tidy`, `include/<project>/` + `src/` + `tests/`
  layout per `rules/cpp/build-architecture.md` level 1 (small tool — the
  default starting point; only move to level 2 if the project already has
  multiple independent internal modules from day one).

## Step 1 — Project context (open conversation, not multiple choice)

Ask in plain conversation:
- Project name (used for the folder/package name — confirm the slug, e.g. "my-project" → Python package `my_project`, or C/C++ target name `my_project`)
- One-line description and goal: what problem it solves, for whom
- Anything beyond the base stack worth knowing now: for Python, a specific framework (FastAPI, Dash, Streamlit, a CLI, a Discord bot, a data pipeline...); for C/C++, whether it needs any vcpkg dependency beyond GoogleTest (networking, JSON, a specific library) — since this changes which optional deps and folders get added

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
  - GitHub Actions CI (Recommended) — ruff+mypy+pytest for Python, or CMake+sanitizers+clang-tidy+cppcheck for C/C++
  - Issue and PR templates
  - CODEOWNERS (only offer if Step 2 was "with a team")
  - Dependabot for dependency updates
  - Docker (Dockerfile + docker-compose, from examples/) — only offer if Step 1 suggests a long-running service; otherwise ask explicitly first
  - CodeGraph indexing (code intelligence MCP for faster code navigation — the index grows automatically as the project does, worth starting from day one)
```

Only offer the CodeGraph option if the `codegraph` CLI is actually on `PATH`
(check with `which codegraph`) — if it's missing, mention briefly that it's
available as a global install (`npm install -g @colbymchenry/codegraph`) but
don't install a new global tool without the user asking for it separately;
just skip the option for this run.

## Step 5 — Build the skeleton

Reuse `~/.claude/examples/` as the base, adapted to the gathered context —
never copy it verbatim without filling in the project-specific parts.
Shared across both stacks:

- **`.gitignore`, `.gitattributes`, `.pre-commit-config.yaml`**: copy from
  `examples/`. The `.pre-commit-config.yaml` template has both a Python
  block and a C/C++ block, each commented `# <stack> projects only` —
  delete whichever block doesn't apply to this project, keep the other.
  Same for `.gitignore`'s trailing C/C++-only section. Immediately run
  `pre-commit autoupdate` on the copied config to pin real current hook
  versions — the template ships with placeholder revs on purpose, never
  leave them in place.
- **`README.md`**: built FROM the Step 1 context, not a generic template — one-liner, install, run, test commands that match what was actually set up here, link to `docs/` if created.
- **Project `CLAUDE.md`**: project-specific context only (goal, stack specifics, team) — never repeat the global `~/.claude/CLAUDE.md` (see `rules/common/repo-structure.md`).
- **`.github/copilot-instructions.md`**: always, unconditionally — invoke the `copilot-instructions` skill rather than duplicating its logic here.
- **`.github/workflows/ci.yml`** (only if CI was selected in Step 4): for Python, copy `examples/.github/workflows/ci.yml` as-is (ruff+mypy+pytest, same gate as the local pre-commit hook); for C/C++, copy `examples/.github/workflows/ci-cpp.yml` as-is (CMake sanitized preset + clang-format + clang-tidy + cppcheck + CTest). Never improvised from scratch, so CI and local checks never silently drift apart. Check `astral-sh/setup-uv`'s (Python) or the toolchain apt packages' (C/C++) current versions against the template's pinned versions before leaving them in place.
- **AI instructions for other tools** (only the ones selected in Step 2):
  - Cursor → `.cursor/rules/project.mdc` (current convention as of writing — verify via web search if this has moved, conventions for these tools shift fast)
  - Windsurf → `.windsurfrules`
  - Other/various/unlisted tool → `AGENTS.md` at the repo root (the emerging cross-tool vendor-neutral convention)
  - Base every one of these, and the Copilot file, on the same project context as `CLAUDE.md` — don't let them drift into a different description of the same project.
- **`CONTRIBUTING.md`**: only if "with a team" — branch/PR workflow, commit convention, how to run tests locally before pushing.
- **`CHANGELOG.md`**: only if requested or team — start with an empty `## [Unreleased]` section.
- **`docs/`**: skip entirely unless the project is clearly non-trivial. If created, only scaffold `docs/architecture.md` with an explicit placeholder marker (e.g. `<!-- TODO: fill in once the architecture has more than one obvious component -->`) — this is the one place where a placeholder file is fine even though `rules/common/documentation.md` normally says not to create empty doc stubs, because this is the initial scaffold, not an ongoing audit.
- **Docker** (only if requested): `Dockerfile` + `docker-compose.yml` from `examples/`.
- **CodeGraph indexing** (only if requested in Step 4): run `codegraph init` at the project root once the hello-world skeleton files exist. `.codegraph/` is already covered by the `.gitignore` template (see `examples/.gitignore`) — it's a local generated index, never committed. Report the index stats from the command output (files/nodes/edges) as part of Step 7's verification, not silently.

### If Python (Step 0)

- **Folder tree** per `rules/common/repo-structure.md`: `src/<package>/{core,io}`, `tests/`, `scripts/`, `logs/.gitkeep`, `docker/` only if Docker was requested.
- **`pyproject.toml`**: copy from `examples/pyproject.toml`, replace `name`/`description`, add any stack-specific dependency via `uv add <pkg>` (e.g. `fastapi`, `dash`, `streamlit`) rather than hand-editing the dependency list — keeps `uv.lock` in sync from the start.
- **`src/<package>/logging_config.py`**: copy from `examples/logging_config.py`.
- **Hello world**: `src/<package>/__init__.py`, `src/<package>/main.py` (or `cli.py`) with one real function returning/printing a greeting, complete Google-style docstring, and `tests/test_main.py` with a passing test for it — this proves the whole toolchain (ruff, pytest, pydocstyle) actually works end to end, not just that files exist.

### If C/C++ (Step 0)

- **Folder tree** per `rules/cpp/build-architecture.md` level 1: `include/<project>/`, `src/`, `tests/`, `docs/`.
- **`CMakeLists.txt`**: copy from `examples/CMakeLists.txt`, replace `my_tool`/`my_tool_lib` with the real project/target name throughout (including in `tests/CMakeLists.txt`'s `target_link_libraries`).
- **`CMakePresets.json`**: copy from `examples/CMakePresets.json` as-is — already wires `VCPKG_ROOT`, `CMAKE_EXPORT_COMPILE_COMMANDS`, and the `default`/`sanitized` presets. Ask the user if the project targets MinGW-w64 specifically (vs. MSVC or a Linux toolchain) — if so, add `"CMAKE_C_COMPILER": "gcc"`, `"CMAKE_CXX_COMPILER": "g++"`, and `"VCPKG_TARGET_TRIPLET": "x64-mingw-dynamic"` to the `default` preset's `cacheVariables` (see the project's VS Code C/CPP profile setup for why).
- **`vcpkg.json`**: copy from `examples/vcpkg.json`, rename `"name"` to the project's slug, add any dependency named in Step 1 via `vcpkg add port <name>` (keeps the manifest and any lockfile-equivalent state in sync) rather than hand-editing the array.
- **`.clang-format`, `.clang-tidy`**: copy from `examples/` as-is — these already extend Google style / the LLVM check families per `rules/cpp/lint-strict.md`, no per-project customization needed by default.
- **`tests/CMakeLists.txt`**: copy from `examples/tests/CMakeLists.txt`, rename the target to match.
- **Hello world**: `include/<project>/widget.h` + `src/widget.cpp` with one real function (e.g. a greeting builder) and a Google-style-equivalent doc comment (Doxygen `@brief`/`@param`/`@return`), `src/main.cpp` calling it, and `tests/test_widget.cpp` with a passing GoogleTest case — this proves the whole toolchain (CMake configure+build, clang-format, clang-tidy, CTest) actually works end to end, not just that files exist.

## Step 6 — Git & GitHub wiring

1. `git init` if not already a repo
2. Install pre-commit and wire the hook:
   - **Python project**: `uv add --dev pre-commit && uv run pre-commit install` (never a bare `pip install` — see `rules/common/coding-style.md`).
   - **C/C++ project** (no Python venv to anchor a dev dependency to): `uv tool install pre-commit` (idempotent global install, see `dotfiles/TOOLS.md`'s uv-managed tools) then plain `pre-commit install` inside the repo.
3. First commit: `chore: initial project scaffold` (conventional format, see `rules/common/coding-style.md`)
4. Remote setup / `gh repo create` per Step 3, then push
5. Branch protection per Step 2/3, after the push

## Step 7 — Final verification (prove it actually works, don't just claim it)

**Python**:
```fish
uv run ruff check .
uv run mypy src
uv run pytest
uv run python -m <package>   # or however the hello-world entry point runs
```

**C/C++**:
```fish
cmake --preset default
cmake --build --preset default
ctest --preset sanitized --output-on-failure
clang-format --dry-run --Werror src/*.cpp include/*/*.h
clang-tidy -p build --warnings-as-errors='*' src/*.cpp
```

Report the actual output of each, not an assumption. If anything fails,
fix it before declaring the scaffold done.

## Step 8 — Final report

Summary of: what was created, what's a placeholder still to fill in
(list explicitly — e.g. "`docs/architecture.md` — TODO", "`CHANGELOG.md`
— empty Unreleased section"), and the next suggested step (e.g. "rename
the hello-world module once the first real feature starts").

## Guardrails

- Never create something not asked for or not justified by an answer (no Docker, no CODEOWNERS, no CI without it being selected in Step 4)
- Placeholders are explicit TODO markers, never fake/generic filler content pretending to be real documentation
- Never push to a remote, create a GitHub repo, or apply branch protection without explicit confirmation of the exact name/visibility/scope from the user first
- If `gh auth status` shows not logged in, say so and fall back to local-only git rather than failing silently on the GitHub steps
