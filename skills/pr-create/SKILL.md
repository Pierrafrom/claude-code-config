---
name: pr-create
description: Generates a complete pull request with a standardized title, detailed description, context, test plan, and reviewer notes — designed to maximize review quality and speed. Use when the user wants to create/open a PR, or asks to prepare their changes for review.
---

# PR Create — complete pull requests for optimal review

> All commands below are calls to external tools (git, gh) —
> identical regardless of the shell environment (Fish, Bash, PowerShell).

## Goal

Produce a PR that gives the reviewer everything needed to understand it
without having to reread the diff in detail to grasp the intent — reduces
review time and the number of back-and-forths.

## Steps

### 1. Check the state before creating the PR

```fish
git status
git log main..HEAD --oneline
```

- If changes aren't committed: propose running the `split-commit`
  skill first rather than creating a PR on a dirty state
- If the branch isn't pushed: `git push -u origin <branch>`

### 2. Gather the change's context

```fish
git diff main...HEAD --stat
git log main..HEAD --pretty=format:"%s%n%b"
```

Analyze all of the branch's commits (not just the last one) to
understand the overall intent, not just the raw diff.

### 3. Build the PR title

Same convention as commits: `type(scope): short description`,
representing the branch's overall change (not a list of commits).

### 4. Build the description — full structure required

```markdown
## Context
[Why this change is needed — problem solved or need addressed]

## Changes
- [List of significant changes, grouped by theme, not a copy-paste of commit messages]

## How to test
1. [Concrete steps so the reviewer can verify on their own]
2. ...

## Notes for the reviewer
- [Debatable design decisions, accepted trade-offs, parts that deserve close attention]
- [Added dependencies and why]

## Checklist
- [ ] Tests pass (`pytest`)
- [ ] Clean lint (`ruff check .`)
- [ ] Clean strict typing (`mypy`)
- [ ] No secret/debug code in the diff
- [ ] Documentation updated if needed
```

Adapt the sections if the PR is very small (typo, minor fix) — no need
to over-document a trivial change, but never skip "How to test"
even for a small change.

### 5. Create the PR

With the GitHub MCP connected, create the PR directly. Otherwise, fall back to the CLI:

```fish
gh pr create --title "type(scope): short description" --body-file /tmp/pr-body.md --base main
```

(Writing the body to a temp file rather than inline `--body` avoids
escaping issues on long/multi-line descriptions.)

### 6. Confirm and present the link

Show the link of the created PR, don't duplicate the full description a
second time in chat — the link is enough, the user can open it.

## Guardrails

- Never create a PR if tests fail locally — run `pytest` first and flag it if red, rather than creating a broken PR
- Never force-push (`--force`) in this flow
- If the target branch isn't clear (several possible base branches), ask rather than guessing
