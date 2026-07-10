---
name: audit-security
description: Deep security audit across the whole project — secrets in git history, dependencies with known vulnerabilities (CVEs), attack surface, input validation. Deeper than the basic security check done by the code-reviewer agent on a one-off diff. Use for an explicit security audit, before making a repo public, or periodically on a project handling sensitive data.
---

# Audit Security — deep security audit

> All commands below are calls to external tools (git, grep,
> pip-audit) — identical regardless of the shell environment (Fish, Bash, PowerShell).

## Difference from code-reviewer (agent)

`code-reviewer` checks for the absence of secrets/injections in the current diff.
This skill goes further: full git history, dependencies with known CVEs,
the whole project's attack surface — not just what was just written.

## Steps

### 1. Secrets in git history (not just the current state)

A secret removed from the code stays in git history until it is
purged — check the entire history, not just current files:

```fish
git log --all -p | grep -iE "(api[_-]?key|secret|password|token|aws_access)" -A2 -B2
```

If a secret is found in history: flag explicitly that
`git filter-repo` or equivalent is needed to actually purge it (a
simple commit removing it isn't enough, it stays in history).

### 2. Secrets in the current state

```fish
grep -rniE "(api_key|secret|password|token).{0,3}=" src/ --include="*.py"
```

Also check that `.env` is in `.gitignore` and was never committed:

```fish
git log --all --full-history -- .env
```

### 3. Vulnerable dependencies

```fish
uvx pip-audit
```

(`uvx` runs the tool in an ephemeral environment — no need to add it as a project dependency for an occasional audit, see `rules/python/python-patterns.md`)

List each CVE found with its severity, the affected package, and the
fixed version available — without updating automatically (a version
bump can break things, to be validated by the user).

### 4. Input validation

- Spot external entry points (CLI args, reading user files, API calls, DB queries):
  ```fish
  grep -rn "input(\|sys.argv\|request\.\|os.environ" src/ --include="*.py"
  ```
- For each entry point found, check that validation exists before use (type, range, format) — flag unvalidated inputs

### 5. Python-specific dangerous patterns

```fish
grep -rn "eval(\|exec(\|pickle.loads(\|subprocess.*shell=True\|yaml.load(" src/ --include="*.py"
```

None of these patterns is automatically a flaw, but each deserves an
explicit justification if present (e.g. `yaml.load` without
`Loader=SafeLoader` is a known flaw, `pickle.loads` on an untrusted
source too).

### 6. File permissions and access (if Docker is involved)

- Check that the `Dockerfile` doesn't run as `root` without reason
- Check that no secret is passed as a hardcoded `ARG`/`ENV` in the `Dockerfile` (visible in the final image)

### 7. Final report

```
# Security audit — [project] — [date]

## Summary
- N potential secrets found (history: X, current: Y)
- M CVEs in dependencies (severity: critical/high/medium/low)
- K unvalidated entry points

## Detail by severity

### Critical (immediate action)
- [exposed secrets, critical CVEs, possible injection]

### Important
- [medium CVEs, unvalidated inputs]

### To watch
- [justified dangerous patterns to keep in mind]

## Recommended actions (prioritized)
1. ...
```

## Guardrails

- Never display the actual value of a secret found in the report — only its location (file:line) and type
- Never fix a vulnerable dependency automatically without confirmation — a major version bump can break the project
- If an active secret is found (not just in history), report it as the top priority before any other point in the report — an exposed secret is more urgent than a low CVE
