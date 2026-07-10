# Doc lookup — systematic verification before writing code

Goal: never generate code based on an outdated version of a lib/API stored
in training memory when up-to-date docs are available.

## When to check (mandatory)

- Before using a function/class of an external lib not used in the last 2 messages of the conversation
- Before using an API whose interface may have changed (fast-release frameworks: FastAPI, LangChain, Polars, Pydantic, Docker Compose syntax...)
- If a build/run error mentions a parameter, method, or behavior that doesn't match what Claude believes it knows → check the docs before patching blindly
- Before recommending a new dependency

## When NOT to check (avoid wasting tokens)

- Stable Python stdlib (os, sys, pathlib, json, re, itertools...) unless an unexpected error occurs
- Basic language syntax
- A lib already confirmed up to date earlier in the same session

## How to check — priority order

1. **Context7 MCP** (connected by default in `settings.json`) → always first. No need to say "use context7" explicitly every time: this rule stands as a permanent instruction — invoke Context7 as soon as a lib/API is involved in the current task, without asking for confirmation. Mention the version if known (e.g. "Next.js 15", "Pydantic v2") for a more precise lookup.
2. **Web search** as a fallback if Context7 doesn't resolve the lib ("library not found") or returns an insufficient answer.
3. Never combine both for the same question if the first source already answered clearly — one pass is enough.

Note: Context7 doesn't always index very recent libs (released a few days ago) — in that case, switch directly to web search.

## Citation rule

If the docs change a technical decision already made (e.g. deprecated API, new required parameter),
mention it explicitly in the response: "Up-to-date docs: X changed since [version], so..."
Don't mention it if the docs simply confirm what was already assumed (no unnecessary noise).
