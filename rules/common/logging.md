# Logging — optimized for low-token AI debugging

Principle: a log must let Claude diagnose an error by reading the MINIMUM
number of lines possible, without having to parse ambiguous free text.

## Format: JSON Lines (JSONL)

One JSON object per line, never multi-line JSON or free text mixed in.

```json
{"ts":"2026-06-25T10:32:01Z","level":"ERROR","module":"data.loader","msg":"missing column","ctx":{"file":"sales.csv","col":"region"}}
```

Mandatory fields, always in this order:

| Field    | Type   | Content                                                         |
|----------|--------|------------------------------------------------------------------|
| `ts`     | string | ISO 8601 UTC                                                     |
| `level`  | string | DEBUG / INFO / WARNING / ERROR / CRITICAL                        |
| `module` | string | logical module path (`data.loader`, not the file path)|
| `msg`    | string | short, factual message, not a narrative sentence                  |
| `ctx`    | object | relevant structured data (variables, IDs, values) — no free text inside |

Optional field: `trace_id` if several steps of the same pipeline need to be correlated.

## Why this format (and not plain default `logging` text)

- Claude can filter with `grep '"level":"ERROR"'` or `jq 'select(.level=="ERROR")'` on the shell side **before** loading anything into context — zero tokens wasted on irrelevant INFO lines.
- Fixed fields eliminate parsing ambiguity (no need to infer where the message ends and the stack trace begins).
- Structured `ctx` avoids rewriting the same info in prose on every line.

## Python setup (`logging` stdlib + JSON formatter)

- Use the stdlib `logging` module with a custom `Formatter` that serializes to JSONL — no heavy external dependency (`structlog` is fine if already in the project, otherwise stdlib is enough).
- A single logger configured per entry point (`src/<package>/logging_config.py`), not scattered `logging.basicConfig` calls in every file.
- Default level: `INFO` in dev, configurable via an environment variable (`LOG_LEVEL`).
- Output: a file in `logs/<name>.jsonl` (gitignored) AND stdout in dev for immediate visibility.

## C/C++ setup (`spdlog` + JSON pattern)

- `spdlog` is the default choice — header-only or compiled, async-capable,
  no heavy dependency for what's needed here. Add it via the project's
  `vcpkg.json` manifest (see `rules/cpp/build-architecture.md`), never a
  system package.
- Configure a JSON-shaped pattern on the sink so output matches this
  file's fixed field order without a custom formatter:
  ```cpp
  spdlog::set_pattern(
      R"({"ts":"%Y-%m-%dT%H:%M:%S%z","level":"%^%l%$","module":"%n","msg":"%v"})"
  );
  ```
  `ctx` (structured key/value context) doesn't fit a static pattern string
  — recent `spdlog` versions support structured key-value logging via a
  named `kv` argument and a `{kv}` pattern placeholder; on an older
  `spdlog` version, build the `ctx` object with `nlohmann::json` and pass
  it as part of `%v` instead of extending the pattern.
- One logger per module (`spdlog::stdout_logger_mt("module.name")` or a
  file sink), not a single global default logger reused everywhere with
  no `module` distinction.
- Output: a file sink at `logs/<name>.jsonl` (gitignored, same convention
  as Python) plus a stdout sink in dev builds.

## What to log (and what NOT to log)

**Always log:**
- Errors and exceptions with their `ctx` (variables involved, not just the exception message)
- Inputs/outputs of critical operations (external API call, DB write, data pipeline step)
- Non-trivial branching decisions in business logic

**Never log:**
- Secrets, tokens, passwords, sensitive personal data (even at DEBUG level)
- High-frequency loops without aggregation (one log per iteration over 10k rows = noise, log a summary after the loop instead)
- Vague narrative messages ("starting", "almost done") with no diagnostic value

## Debugging rule — expected behavior from Claude

**When an error is reported and logs exist in the project
(`logs/` folder or equivalent), Claude must check the logs FIRST,
before rereading the entire codebase or speculating about the cause.**

Operating order for any debugging session:
1. Check whether `logs/*.jsonl` exists and contains relevant recent entries
2. Filter with `grep`/`jq` on `level:ERROR` or `level:CRITICAL` around the issue's timestamp — don't load the entire log file into context
3. Use the structured `ctx` to identify the cause before reading the source code
4. Only read the source code for the portion identified as responsible, not the whole module by default

If no relevant log exists to reproduce/diagnose the bug, flag it:
propose adding a structured log at the right spot rather than debugging
blindly through an exhaustive code reread.
