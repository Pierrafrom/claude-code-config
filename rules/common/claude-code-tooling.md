---
paths:
  - "**/settings.json"
  - "**/settings.example.json"
  - "**/.claude/**"
  - "**/agents/*.md"
  - "**/CLAUDE.md"
---

# Claude Code tooling — model routing, hooks, memory, plugin decisions

How this config tunes Claude Code itself, and which popular add-ons were
evaluated and why they were adopted or rejected. Read before changing
`settings.json`, an agent's frontmatter, or installing a plugin. Facts below
come from code.claude.com/docs (model-config, sub-agents, advisor, costs,
hooks, memory), checked on Claude Code 2.1.321.

## Model and effort routing

There is no automatic per-task model picker. The levers, from cheapest to
most targeted:

- **Main model** (`model` in `settings.json`, `/model`). Sonnet covers most
  coding at lower cost; Opus for hard reasoning. The user's choice in
  settings wins; do not change it unasked. **Current choice (2026-11-10):
  Sonnet main + Opus advisor** (`"model": "sonnet"`, `"advisorModel": "opus"`)
  — Opus is consulted only at decision points. `/model opus` for a session
  that needs Opus throughout.
- **Effort** (`effortLevel` in settings, `/effort`, `effort` in agent
  frontmatter): `low`/`medium`/`high`/`xhigh`/`max`. 5.5 models default to
  `medium`. Raise effort before switching model for a one-off hard task.
- **`MAX_THINKING_TOKENS` is dead config** on Opus/Sonnet/Haiku 5.5 and
  Fable: they always use adaptive reasoning and ignore it. Use effort.
- **Subagent model**, resolved in this order (v2.1.251+): per-call `model`
  parameter → agent frontmatter `model` (`inherit` = main model) →
  `CLAUDE_CODE_SUBAGENT_MODEL` → main model. So the
  `CLAUDE_CODE_SUBAGENT_MODEL=haiku` set here is only a **fallback** for
  agents with no `model` (built-in Explore/general-purpose/Plan); the custom
  reviewers in `agents/` pin `sonnet` and keep it. `CLAUDE_CODE_SUBAGENT_MODEL_FORCE=1`
  would override frontmatter — not used.
- **`opusplan`**: Opus in plan mode, Sonnet for execution. Fits this
  config's "plan mode by default" workflow (`rules/common/reasoning-planning-routing.md`).
- **Advisor tool** (`/advisor <model>`, `advisorModel` in settings): the
  main model consults a stronger one at decision points (before committing
  to an approach, on recurring errors, before declaring done). This is the
  only native mechanism that switches model on intermediate steps. The
  advisor must rank at or above the main model: Sonnet main + Opus advisor
  is the documented cost-efficient pair; with Opus main, only Opus/Fable
  qualify. Experimental; counts toward plan limits; disabled if
  `DISABLE_TELEMETRY` is set.

## Hooks — what actually loads

- User hooks live only in the `hooks` key of `~/.claude/settings.json`.
  `~/.claude/hooks/hooks.json` is **not read** (that path is for plugins);
  this repo's `hooks/` only holds scripts.
- Matchers are tool names/regex (`"Write|Edit"`, `"Bash"`). Expressions like
  `tool == "Bash" && ...` are invalid. Failed Bash commands (non-zero exit)
  fire `PostToolUseFailure` — verified in-session 2026-11-09.
- Claude never sees stderr from a hook that exits 0. To reach Claude:
  exit 2 with stderr (PostToolUse/PostToolUseFailure), plain stdout
  (SessionStart), or JSON `hookSpecificOutput.additionalContext`.
- No SessionStart reminder hook: it would only repeat `CLAUDE.md` and cost
  tokens every session.

## Memory

Built-in auto memory (on by default, `~/.claude/projects/<project>/memory/`,
`MEMORY.md` index, first 200 lines/25 KB loaded) plus path-scoped rules
(`paths:` frontmatter) cover persistent context. `CLAUDE.md` target: under
200 lines; `@imports` do not reduce its cost.

## Add-ons evaluated (2026-11-09)

| Tool | Verdict | Why |
|---|---|---|
| `claude-code-setup` (anthropics/claude-plugins-official) | **Adopted (installed 2026-11-10)** | Official, read-only: analyzes a repo and recommends 1–2 MCP servers/skills/hooks/subagents per category. One skill (`claude-automation-recommender`, ~140 tokens always-on). In a project, ask "recommend automations for this project". Apply its suggestions selectively against these rules. |
| `claude-mem` (thedotmack) | **Reject** | Duplicates built-in auto memory (its installer offers to disable it), installs Bun + uv + a background worker, anonymous telemetry on by default, its observer agent costs tokens on your plan or a paid service, and its README promotes an unrelated crypto token. Revisit only if auto memory proves insufficient on a long project. |
| Free LLM APIs via claude-code-router / OpenRouter / Gemini free tier | **Reject for Claude Code** | Swaps Claude for weaker open models with small context and low daily caps (OpenRouter free: ~50 req/day); free tiers may train on submitted code; routing real Claude traffic through a proxy to dodge billing is a ToS risk. Acceptable for **app-level** LLM calls inside a project (prototyping a LangChain/RAG pipeline), with no confidential data. |
| Third-party model routers (CCR, routing hooks) | **Reject** | Native routing above (subagent models, effort, `opusplan`, advisor) covers the need without a proxy in the request path. |
| Token savers (Caveman, RTK) | **Not needed / optional** | "Caveman style" is already a rule in `CLAUDE.md`. RTK (CLI output compression) is untested here; `/context` first to see where tokens go. |

## MCP hygiene

Prefer a CLI over an MCP server when both exist (`gh` over the GitHub MCP,
built-in Read/Write over a filesystem MCP) — official cost guidance. MCP
tool definitions are deferred by default, so an idle server costs little,
but an unused one is still attack surface: disable it with `/mcp`.

Current state (2026-11-10): the filesystem MCP was removed (redundant with
built-in tools). The GitHub MCP is kept on purpose (the user's choice; the
permission allow-list uses its PR tools) — don't propose removing it again.

## Sources to watch (as of 2026-11-09)

| Domain | Canonical source | Change signal |
|---|---|---|
| Models, effort, opusplan | code.claude.com/docs/en/model-config | New aliases, default effort changes |
| Subagent model precedence | code.claude.com/docs/en/sub-agents | Precedence order (changed in v2.1.251) |
| Advisor | code.claude.com/docs/en/advisor | Leaves experimental, pairing table |
| Hooks | code.claude.com/docs/en/hooks | New events, exit-code semantics |
| Official plugins | github.com/anthropics/claude-plugins-official | New setup/optimization plugins |
