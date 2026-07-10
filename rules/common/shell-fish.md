# Shell: real technical detection (Fish/PowerShell), Bash forced for shared scripts

## Base rule

Before giving a command to run directly (not a shared script),
**detect the active shell via an environment variable or detection
command**, rather than deducing or assuming Fish by default.

## Detection commands (tested/verified against official docs)

| Shell        | Detection variable/command                  | Value if absent (wrong shell) |
|---------------|---------------------------------------------------|-------------------------------------|
| Fish          | `echo $FISH_VERSION` or `echo $version`           | empty string (no error)          |
| PowerShell    | `$PSVersionTable.PSEdition` (or the full `$PSVersionTable`) | variable doesn't exist outside PowerShell |
| Bash          | `echo $BASH_VERSION`                              | empty string (no error)          |

**Verified watch point**: a missing variable doesn't make the command
fail, it silently returns an empty string — so always explicitly test
that the value is non-empty (`test -n "$FISH_VERSION"`
in Fish), not just "the command returned no error".

## Detection procedure before a one-off command

1. If the active shell is already known with certainty from the
   current session's context (e.g. a previous command in the same session
   already confirmed Fish or PowerShell), don't redetect every time —
   only at the start of a new session or if the context changes (machine
   change, explicit mention of another shell).
2. Otherwise, run the detection command suited to the most likely
   environment given the context (WSL/Linux → test Fish first;
   native Windows → test PowerShell first), then confirm before
   giving the final command.
3. Give the command in the syntax confirmed by the detection — never
   blindly.

## Bash → Fish → PowerShell equivalences

| Action                  | Bash                       | Fish                          | PowerShell                          |
|--------------------------|----------------------------|--------------------------------|---------------------------------------|
| Env variable (session) | `export VAR=value`        | `set -x VAR value`            | `$Env:VAR = "value"`                |
| Local variable           | `VAR=value`               | `set VAR value`               | `$var = "value"`                    |
| Command substitution  | `$(command)`              | `(command)`                   | `$(command)` (natively supported)  |
| File exists condition  | `if [ -f file ]; then`     | `if test -f file`              | `if (Test-Path file) { }`            |
| Loop over sequence       | `for x in $(seq 1 10)`     | `for x in (seq 1 10)`          | `1..10 \| ForEach-Object { }`         |
| Logical AND between commands| `cmd1 && cmd2`             | `cmd1; and cmd2`               | `cmd1; if ($?) { cmd2 }`             |
| Logical OR between commands| `cmd1 \|\| cmd2`            | `cmd1; or cmd2`                | `cmd1; if (-not $?) { cmd2 }`        |
| Heredoc                   | `command <<EOF ... EOF`    | no equivalent — multi-line `echo` or a file | `@"`...`"@` (here-string) |
| Shell config file   | `~/.bashrc`                | `~/.config/fish/config.fish`   | `$PROFILE`                           |
| List env variables    | `env`                      | `env` (compatible)             | `Get-ChildItem Env:`                 |
| Simple grep                | `grep "pattern" file`     | `grep "pattern" file` (external binary, identical) | `Select-String "pattern" file` (or `grep` with WSL interop) |

## Common practical cases

```fish
# Fish (WSL) — detection then environment variable
echo $FISH_VERSION
set -x LOG_LEVEL DEBUG
source .venv/bin/activate.fish
grep '"level":"ERROR"' logs/app.jsonl
```

```powershell
# PowerShell — detection then environment variable
$PSVersionTable.PSEdition
$Env:LOG_LEVEL = "DEBUG"
.venv\Scripts\Activate.ps1
Select-String '"level":"ERROR"' logs\app.jsonl
```

Identical commands in both cases (external binaries, no shell
syntax involved): `uv add --dev ruff`, `ruff check .`,
`git status`, `uv run pytest` — only the syntax *around* them (variables,
conditions, chaining) changes between Fish and PowerShell.

## Exception — shared/reusable scripts

Scripts meant to be saved, shared, reused, or run by
CI/another system (e.g. `install.sh`): always Bash, shebang
`#!/usr/bin/env bash`, invoked via `bash script.sh`. Never any detection
or dependency on the interactive shell of whoever runs them — a shared
script must work regardless of the environment.

## Why technical detection rather than a simple assumption

A command written in the wrong shell syntax fails or silently behaves
differently (`export` does nothing useful in PowerShell, a bash heredoc
crashes in Fish, a missing variable returns an empty string with no
visible error). Detecting via a reliable variable before giving a
command avoids these false positives, rather than guessing from the
conversation's context, which can be ambiguous or absent.
