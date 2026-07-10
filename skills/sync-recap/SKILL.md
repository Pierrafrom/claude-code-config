---
name: sync-recap
description: Fetches all changes made on the remote repo, across all branches, and produces a clear recap of who did what and when, plus an overview of the project's progress. Use when the user wants a status check on a collaborative project (student-run consultancy, UTC group project), asks "what's new on the repo", or wants to know where other contributors stand.
---

# Sync Recap — collaborative multi-branch recap

> All commands below are git calls — identical regardless of the
> shell environment (Fish, Bash, PowerShell).

## Goal

Give a clear, per-person overview of a collaborative project's progress,
without the user having to manually go through every branch and every
commit.

## Steps

### 1. Fetch the full remote state

```fish
git fetch --all --prune
git branch -a
```

### 2. List active branches and their state relative to main/master

```fish
git for-each-ref --sort=-committerdate refs/remotes/ --format='%(refname:short) %(committerdate:relative) %(authorname)'
```

Identify the main branch (main or master) and compute, for each
remote branch:

```fish
git log main..origin/<branch> --oneline
git rev-list --left-right --count main...origin/<branch>
```

→ how many commits ahead/behind relative to main.

### 3. Recap per contributor

For the requested period (default: since the last `fetch` of the
previous recap, or the last 7 days if it's the first recap):

```fish
git log --all --since="7 days ago" --pretty=format:"%an|%ad|%s" --date=short
```

Group by author, then by branch, in this presentation order:

```
## [Contributor name]
- Branch `feature/xyz` (3 commits, 2 days ahead of main)
  - feat: short description
  - fix: short description
- Branch `main`
  - chore: short description
```

### 4. Detect items worth flagging

- **Potential conflicts**: files modified in parallel on several active branches (cross `git diff <branch1> <branch2> --stat` on diverging branches)
- **Stale branches**: no activity for more than 2-3 weeks — flag as cleanup candidates, never delete automatically
- **Pending PR/MR**: if the remote is GitHub and the GitHub MCP is connected, list open PRs with their review status

### 5. Produce the final recap

Concise output format:

```
# Project recap — [repo name] — [date]

## Overview
- Main branch: main, up to date with origin
- N active branches, M pending merge

## By contributor
[per-person sections, see step 3]

## Points of attention
- [potential conflicts, stale branches, pending PRs]

## Suggested next steps
- [if obvious from commits/PRs: e.g. "feature/auth ready to merge, 0 conflicts with main"]
```

## Guardrails

- Never merge, rebase, or push anything automatically — this skill is strictly informational/read-only
- Don't assume other contributors' intent beyond what their commit messages say — stay factual
- If the repo is large (many branches/commits), filter on a reasonable time window rather than loading everything — ask for the period if it isn't obvious
