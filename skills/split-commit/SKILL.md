---
name: split-commit
description: Splits all uncommitted changes since the last commit into several atomic commits, with standardized conventional messages and full descriptions. Always proposes the split plan and asks for approval before creating a single commit. Use when the user asks to commit work, "split the changes", or mentions having several unrelated changes to commit.
---

# Split Commit — atomic splitting with approval

> All commands below are git calls — identical regardless of the
> shell environment (Fish, Bash, PowerShell).

## Goal

Turn a working state with several mixed changes into a series of
atomic, clean, standardized, traceable commits — never committing
without the user's explicit approval.

## Steps

### 1. Analyze the current state

```fish
git status
git diff HEAD
```

Identify all files modified/added/deleted since the last commit
(staged + unstaged + relevant untracked — ignore files listed in
`.gitignore`).

### 2. Group by logical change

One commit = one responsibility. Grouping criteria:
- A bug fix ≠ a refactor ≠ a new feature, even within the same file
- Test files go with the code they test (same commit)
- Config/dependency changes go in a separate commit (`chore`)
- If a single file contains two different logical changes, use
  `git add -p` (hunk-by-hunk staging) to split them rather than
  committing everything together

### 3. Build the commit plan

For each proposed commit, determine:
- **Type**: feat, fix, refactor, test, docs, chore, perf (consistent with `rules/common/coding-style.md`)
- **Scope**: affected module/file in parentheses
- **Short description**: one line, imperative, no trailing period
- **Message body**: full description explaining the *why*, not just the *what* — context, motivation, impact if relevant
- **Affected files**: exact list of what will be staged for this commit

### 4. Present the plan — MANDATORY before any execution

Always display the full plan in this form before touching `git add`/`git commit`:

```
Split plan (N proposed commits):

1. fix(data/loader): handle missing region column
   Files: src/data/loader.py, tests/data/test_loader.py
   Body: [full description]

2. refactor(api/client): extract retry logic into helper
   Files: src/api/client.py
   Body: [full description]

...
```

**Wait for the user's explicit approval before creating a single commit.**
If the user asks for adjustments (merge two commits, re-split one,
change a message), revise the plan and present it again before executing.

### 5. Execute after approval

For each commit in the approved plan, in logical order (dependencies first):

```fish
git add <files for commit N>
git commit -m "type(scope): short description" -m "full message body"
```

### 6. Final check

```fish
git log --oneline -n <N>
git status
```

Confirm that all changes have been committed and nothing unexpected
remains pending.

## Guardrails

- Never commit a secret/API key detected in the diff — alert and exclude the file from the plan
- Never commit forgotten debug code (print, breakpoint) — flag it before including it in a commit
- If the project's git history follows a different convention than conventional commits, observe it via `git log` and adapt to it rather than imposing the default format
