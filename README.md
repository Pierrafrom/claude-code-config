# claude-code-config

My personal [Claude Code](https://claude.com/claude-code) configuration: global
instructions, coding-style rule files, subagents, skills, and hooks — shared
across every machine and environment I use Claude Code from (WSL2, native
Windows, etc.).

This is a **living, opinionated config**, not a generic template. It encodes a
fairly strict, uncompromising engineering baseline (strict typing, TDD,
zero-warning lint, incremental documentation, structured logging). Take what's
useful, fork it, or use it as inspiration for your own.

## What's in here

| Path | Purpose |
|---|---|
| `CLAUDE.md` | Global context loaded into every session: stack, response style, shell-detection rules, token/context management, permanent guardrails |
| `rules/common/` | Language-agnostic rules: clean code, OOP design, documentation discipline, logging format, repo structure, shell detection (Fish/PowerShell) |
| `rules/python/` | Python-specific: lint (ruff strict), typing (`mypy --strict` baseline), OOP idioms |
| `rules/data/` | Data/ML domain rules: SQL & dbt style, database design (OLTP/Kimball/Data Vault), data engineering pipelines, MLOps/LLMOps/RAG |
| `rules/devops/` | CI/CD, Docker, GitOps/IaC, observability, DevSecOps |
| `agents/` | Subagent definitions (build-error-resolver, code-reviewer, python-reviewer, tdd-guide) |
| `skills/` | Custom slash-command skills (audit-docs, audit-quality, audit-security, init-project, lint-zero, pr-create, split-commit, sync-recap, write-docs, ...) |
| `hooks/hooks.json` | Session-start reminder + post-tool-use hook that nudges toward checking structured logs after a failed command |
| `examples/` | Reference templates: `.pre-commit-config.yaml`, `pyproject.toml` (ruff + mypy strict config), `Dockerfile`, `docker-compose.yml`, `.gitattributes`, `.gitignore`, `logging_config.py`, a GitHub Actions CI workflow |
| `settings.example.json` | Sanitized example of `~/.claude/settings.json` (generic permissions only — see below) |

## What's deliberately excluded

- `settings.json` / `settings.local.json` — contain machine- and
  project-specific permission entries (local paths, project directories).
  Copy `settings.example.json` to `~/.claude/settings.json` and adapt it
  instead of using it verbatim.
- Any credentials, session history, MCP auth tokens, or `~/.claude.json`
  backups — none of that belongs in a public repo, and none of it is tracked
  here.

## Philosophy

The short version of the rigor level this config enforces:

- **Strict clean code** — short, single-responsibility functions; zero dead
  code/duplication; explicit naming over comments.
- **Strict typing everywhere it's supported** — `mypy --strict` baseline for
  Python, no legacy typing syntax, typed public signatures mandatory.
- **TDD by default** — test before code, 80%+ coverage on business logic.
- **Zero-warning lint** — a clean `ruff check .` is a commit gate, not a
  suggestion.
- **Documentation written incrementally**, exactly like TDD — docs are part of
  "done", not a follow-up pass.
- **Structured JSONL logging** — designed so AI-assisted debugging can grep/jq
  straight to the relevant `ERROR` lines instead of rereading a whole
  codebase.
- **Favor OOP by default** — real SOLID, composition over inheritance, real
  encapsulation — see `rules/common/oop-design.md`.

Full detail lives in the rule files themselves — `CLAUDE.md` is the entry
point and links out to each one by topic.

## Usage

### Option A — clone + symlink (recommended)

This keeps your live `~/.claude/` config and this Git repo in sync
automatically: edit either one, the change shows up in both.

```bash
git clone https://github.com/Pierrafrom/claude-code-config.git ~/Code/claude-code-config

# back up whatever's already in ~/.claude (optional but safer)
mv ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak 2>/dev/null
mv ~/.claude/rules ~/.claude/rules.bak 2>/dev/null
mv ~/.claude/agents ~/.claude/agents.bak 2>/dev/null
mv ~/.claude/skills ~/.claude/skills.bak 2>/dev/null
mv ~/.claude/hooks ~/.claude/hooks.bak 2>/dev/null

ln -s ~/Code/claude-code-config/CLAUDE.md ~/.claude/CLAUDE.md
ln -s ~/Code/claude-code-config/rules     ~/.claude/rules
ln -s ~/Code/claude-code-config/agents    ~/.claude/agents
ln -s ~/Code/claude-code-config/skills    ~/.claude/skills
ln -s ~/Code/claude-code-config/hooks     ~/.claude/hooks

cp ~/Code/claude-code-config/settings.example.json ~/.claude/settings.json
# then edit ~/.claude/settings.json to add your own project-specific permissions
```

On Windows (native Claude Code install, PowerShell as Administrator —
`mklink` requires elevated privileges or Developer Mode enabled):

```powershell
git clone https://github.com/Pierrafrom/claude-code-config.git $Env:USERPROFILE\claude-code-config
mklink $Env:USERPROFILE\.claude\CLAUDE.md $Env:USERPROFILE\claude-code-config\CLAUDE.md
mklink /D $Env:USERPROFILE\.claude\rules  $Env:USERPROFILE\claude-code-config\rules
mklink /D $Env:USERPROFILE\.claude\agents $Env:USERPROFILE\claude-code-config\agents
mklink /D $Env:USERPROFILE\.claude\skills $Env:USERPROFILE\claude-code-config\skills
mklink /D $Env:USERPROFILE\.claude\hooks  $Env:USERPROFILE\claude-code-config\hooks
```

### Option B — plain copy

If you don't want live sync, just copy the files once:

```bash
git clone https://github.com/Pierrafrom/claude-code-config.git /tmp/ccc
cp -r /tmp/ccc/CLAUDE.md /tmp/ccc/rules /tmp/ccc/agents /tmp/ccc/skills /tmp/ccc/hooks ~/.claude/
cp /tmp/ccc/settings.example.json ~/.claude/settings.json
```

### Note on Claude.ai (web/desktop app)

Claude Code and Claude.ai (the chat web/desktop app) are separate products
with separate storage — there's no config crossover. Claude.ai has its own
account-level, cloud-synced "Custom instructions" under Settings → Profile,
which is the equivalent surface there but is configured independently of
this repo.

## License

[Unlicense](https://unlicense.org) — public domain dedication, no
conditions, no attribution required. See [LICENSE](LICENSE).
