---
name: repo-clean
description: One-shot pass to make a GitHub repo clean, working, and fully documented per GitHub community-standard conventions — actually runs the install/build/test commands to verify the repo works (not just that docs claim it does), refreshes stale documentation, and scaffolds every missing GitHub convention file (LICENSE, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, issue/PR templates, CODEOWNERS) filled in with real project content, never generic boilerplate. Use when the user wants to clean up/polish/prep a repo for GitHub, make it presentable before sharing or going public, or asks for "GitHub conventions"/"community standards" files.

---

# Repo Clean — verified-working, fully documented, GitHub-convention-complete

> All commands below are calls to external tools (git, gh, ruff, mdformat,
> the project's own build/test commands) — identical regardless of the
> shell environment (Fish, Bash, PowerShell); adapt syntax per
> `rules/common/shell-fish.md`.

## What this skill adds on top of existing ones

This skill orchestrates existing skills rather than duplicating their
logic — invoke them via the `Skill` tool at the relevant step instead of
reimplementing:

- **`audit-docs`** → diagnoses documentation gaps and staleness
- **`write-docs`** → fixes what `audit-docs` found, scaffolds missing root files
- **`lint-zero`** → final formatting pass (Python + Markdown)
- **`split-commit`** → grouping/message conventions this skill's own commit
  step follows (one responsibility per commit, conventional format,
  mandatory plan approval before execution) — reused, not reinvented

What's genuinely new here, not covered by any of the above:

1. **Functional verification** — actually *running* the project's
   install/build/test cycle to confirm it works, not just checking that
   docs describe it correctly.
2. **GitHub community-standard files** — `LICENSE`, `CODE_OF_CONDUCT.md`,
   `SECURITY.md`, `.github/ISSUE_TEMPLATE/`, `.github/PULL_REQUEST_TEMPLATE.md`,
   `.github/CODEOWNERS` — files GitHub itself surfaces under "community
   standards" that none of the existing skills scaffold.
3. **Committing the pass's own changes with a backdated timestamp** — one
   day after the repo's last commit, rather than the real current date
   (see step 7) — so a cleanup pass done today doesn't leave a large,
   conspicuous gap followed by a same-day burst in the repo's history.

## Steps

### 1. Establish context before touching anything

Check, don't assume:

```fish
git remote -v
gh repo view --json isPrivate,licenseInfo,description 2>/dev/null
```

- Is this repo actually hosted on GitHub (a `github.com` remote)? If not,
  skip GitHub-hosted mechanics (issue forms, Dependabot) but still
  scaffold `.github/` files locally — they activate the moment it's
  pushed.
- Is it public, private, solo, or collaborative? This decides scope:
  a solo private coursework repo doesn't need `CODE_OF_CONDUCT.md` or
  issue templates; a public repo intended for outside contributions does.
- **License is the user's call, never pick one silently.** If `LICENSE`
  is missing and the repo looks intended to be public/shared, ask which
  license (MIT, Apache-2.0, GPL-3.0, or "none/proprietary — skip it").
  If context makes the answer obvious (e.g. `pyproject.toml` already
  declares a license classifier), use that instead of asking.

If any of this is ambiguous, use `AskUserQuestion` rather than guessing —
license choice and public-contribution scope are exactly the kind of
decisions that are the user's to make, not a reasonable-default call.

### 2. Inventory current state

```fish
git status
find . -maxdepth 2 -iname "README.md" -o -iname "LICENSE*" -o -iname "CONTRIBUTING.md" -o -iname "CODE_OF_CONDUCT.md" -o -iname "SECURITY.md" -o -iname "CHANGELOG.md"
find .github -type f 2>/dev/null
```

Run `git status` first per this session's standing safety rule — stash
or flag any uncommitted work before doing anything that touches tracked
files.

### 3. Verify the repo actually works — the core of "clean"

This is the step none of the doc-focused skills do: don't trust the
README, *run* what it claims works.

- Detect the stack: `pyproject.toml` → `uv sync && uv run pytest`;
  `package.json` → `pnpm install && pnpm build && pnpm test`;
  `CMakeLists.txt` → the project's CMake preset build + `ctest`
  (see `rules/cpp/build-architecture.md`); adapt per stack.
- Run the exact install → build → test sequence the README documents,
  in a clean-ish state (don't assume a pre-existing `.venv`/`node_modules`
  is representative of a fresh clone).
- Every documented command must actually succeed. If one fails or no
  longer exists (renamed script, moved entry point, dropped dependency),
  that's a real bug in the repo's documented contract — fix the command
  reference in the docs (or flag the underlying break if it's a real
  code issue, not just a doc issue) rather than silently working around it.
- Check `.env.example` (if present) against what the code actually reads
  (`grep -rn "os.environ\|os.getenv" src/` or `process.env\.` for JS) —
  flag any env var read in code but undocumented, and any documented var
  no longer read anywhere.
- Spot-check internal doc links (`docs/*.md` cross-references, README
  links to `docs/`) resolve to files that exist — a broken relative link
  is a silent doc rot signal.

### 4. Documentation — delegate, don't reimplement

Invoke `audit-docs` for the gap/staleness diagnosis, then `write-docs` to
fix what it found. This covers README completeness, docstrings,
`docs/` structure, and staleness vs. the current code — full detail in
those two skills, not repeated here.

### 5. GitHub community-standard files — scaffold what's missing, grounded in the real project

For each file below that's both missing and relevant to this repo's
actual context (from step 1) — never add one that doesn't fit the
project's real situation (e.g. no `CODE_OF_CONDUCT.md` for a solo
private repo):

| File | Purpose | Skip when |
|---|---|---|
| `LICENSE` | Legal terms for use/reuse | User says "no license" / private, non-distributed |
| `CONTRIBUTING.md` | Branch/PR workflow, commit convention, local test setup | Already scaffolded by `write-docs` — only add GitHub-specific workflow detail here (labels, branch naming, review expectations) if missing from the existing file |
| `CODE_OF_CONDUCT.md` | Behavior expectations for contributors | Solo, non-collaborative repo |
| `SECURITY.md` | How to privately report a vulnerability, supported versions | Repo has no meaningful attack surface (e.g. a pure script/CLI with no network/auth surface) — still cheap to add, err on including it for anything public |
| `.github/ISSUE_TEMPLATE/*.yml` | Structured bug report / feature request forms (GitHub Issue Forms — YAML, the current standard, not the older raw `.md` templates) | Repo doesn't accept public issues |
| `.github/PULL_REQUEST_TEMPLATE.md` | Checklist: description, test plan, linked issue | Solo repo with no external contributors |
| `.github/CODEOWNERS` | Auto-request review from the right person/team per path | Solo maintainer — one owner for everything adds no information |

Ground every file in the actual project — pull the real install/test
commands into `CONTRIBUTING.md`, the real maintainer contact into
`SECURITY.md`, real path ownership into `CODEOWNERS`. Never paste
placeholder text like `[INSERT EMAIL HERE]` — if a piece of real
information is missing (a security contact address, a maintainer's
GitHub handle), ask rather than inventing or leaving a placeholder.

**Do not scaffold `.github/workflows/*.yml` (CI) or `.github/dependabot.yml`
in this pass without asking first** — those modify CI/CD behavior, which
this session's standing risk policy treats as needing explicit
confirmation, unlike a docs/convention file. Propose it, don't add it
silently.

### 6. Lint & format — zero warnings

Invoke `lint-zero` for the final formatting pass across Python and every
Markdown file just touched or added (including the new `.github/` files).

### 7. Commit the changes — backdated to the day after the repo's last commit

Review first, same as always:

```fish
git status
git diff --stat
```

Then group and commit using `split-commit`'s own logic — one commit per
logical change, conventional `type(scope): description` format, a plan
presented for approval before anything is executed (see `split-commit`
for the grouping/message rules in full, not repeated here).

The one difference from a normal `split-commit` run: **the commit
timestamps are backdated to one day after the repo's last existing
commit**, not the real current date, so a cleanup pass done today
doesn't read as a suspicious multi-month gap followed by a same-day
burst of activity.

**Computing the date:**

```fish
set last_date (git log -1 --format=%aI)   # ISO 8601, last commit's author date
```

If the repo has no prior commits (first commit ever), skip backdating —
use the real current time, there's no "day after" to anchor to.

```fish
set new_date (date -d "$last_date + 1 day" --iso-8601=seconds)
```

If this pass produces several commits, offset each subsequent one by a
few minutes past `new_date` (`+1 day +5 minutes`, `+1 day +10 minutes`,
...) so ordering stays sequential and no two commits share a timestamp —
still all on the same backdated day.

**Applying it** — both the author date (`--date`) and the committer date
(`GIT_COMMITTER_DATE`) must be set to the same value, otherwise the
committer date silently defaults to now and the mismatch is more
conspicuous than no backdating at all:

```fish
set -x GIT_COMMITTER_DATE $new_date
git commit --date="$new_date" -m "type(scope): short description" -m "full body"
set -e GIT_COMMITTER_DATE
```

(Bash: `GIT_COMMITTER_DATE="$new_date" git commit --date="$new_date" ...`;
PowerShell: `$Env:GIT_COMMITTER_DATE = $new_date` before the call, then
remove it with `Remove-Item Env:GIT_COMMITTER_DATE`.)

Show the computed date(s) as part of the commit plan presented for
approval in step 4 of `split-commit`'s flow — the backdating must be
visible to the user before it happens, never a silent side effect.

**Never rewrite the timestamp of any pre-existing commit** — this only
applies to new commits created by this pass. `git commit --amend` or
`rebase` to alter history that already exists is out of scope here and
covered by this session's standing destructive-operation guardrails.

### 8. Push? — separate confirmation, not automatic

Creating the commits above does not imply pushing them. Ask explicitly
before `git push`, same as any other push in this session — committing
locally and pushing are two different points of no return (local history
is still yours to amend; pushed history is shared).

### 9. Final report

```
# Repo Clean — [project] — [date]

## Verified working
- install: [command] → OK/FAILED
- build: [command] → OK/FAILED
- tests: [command] → OK/FAILED (N passed)

## Documentation
- [summary from audit-docs/write-docs pass — gaps found, gaps fixed]

## GitHub convention files
- Added: [list]
- Already present, left as-is: [list]
- Skipped (context): [list + one-line reason each]
- Needs a decision: [e.g. CI workflow proposed but not added — awaiting confirmation]

## Lint
- ruff check . → 0 warnings
- mdformat --check . → compliant

## Commits
- [N commits created, dated [new_date] — one day after the previous last
  commit ([last_date])]
- [oneline list: hash — type(scope): description]

## Not pushed
[awaiting user go-ahead — see step 8]
```

## Guardrails

- Never invent content not grounded in the actual project — same rule as
  `write-docs`. A placeholder is worse than a missing file because it
  looks finished.
- License choice and public-contribution scope are the user's decisions
  — always confirm via `AskUserQuestion` if not already unambiguous from
  context, never default silently.
- Never scaffold CI/CD files (`.github/workflows/`, `dependabot.yml`) in
  this pass without explicit confirmation — propose them in the final
  report instead.
- Commits are created only after the plan (files, messages, computed
  dates) has been presented and explicitly approved — same bar as
  `split-commit`, backdating doesn't relax it.
- Backdating only ever applies to commits this pass creates itself —
  never touch an existing commit's date (no `--amend`, no rebase) to
  "fix" history that already exists.
- Pushing is always a separate, explicit confirmation from committing —
  never chained automatically after the commit step.
- If a documented command actually fails when run (step 3), don't
  silently patch the doc to match broken behavior — flag whether the fix
  belongs in the code or the docs, and let the user weigh in if it's not
  obviously one or the other.
