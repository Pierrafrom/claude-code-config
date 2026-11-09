# Native Windows profile (PowerShell + Docker) — course notes and OneDrive folders

Companion to `rules/common/shell-fish.md` (shell detection and equivalence
table). Applies when the working directory is a Windows path such as
`C:\Users\...\OneDrive\TravailUTC\GI05\...`, not inside WSL.

## Split between the two environments

| Work | Where | Why |
|---|---|---|
| Code, assignments, projects (Python, ML, Docker dev) | WSL2 + Fish, `~/Code/` | Main toolchain (uv, ruff, pytest) and the modern CLI set live there |
| Course notes (LaTeX), slides, course PDFs | Windows, OneDrive `GI05/` | Synced and readable by non-WSL tools; compiled through Docker, no local TeX Live |

## Rules

- **Shell**: the Bash tool here is Git Bash, the PowerShell tool is PowerShell 7. Pick the syntax of the tool actually called. Detection: `$PSVersionTable.PSEdition` (PowerShell), `echo $BASH_VERSION` (Bash).
- **Paths with spaces** (`DVA263 - Applied Machine Learning`): always quote. Prefer absolute paths.
- **Git Bash path mangling**: prefix `docker run` commands that pass container paths (`-w /workspace`) with `MSYS_NO_PATHCONV=1`, or use `compile.ps1`.
- **Docker**: Docker Desktop must be running (`docker info`). If the daemon is down, say so; do not try to start it or build `cours-latex:latest` implicitly (heavy, several minutes).
- **No git inside OneDrive**: a `.git` directory in a synced folder risks corruption (OneDrive syncs object files non-atomically). Version-controlled work goes in WSL (`~/Code/`); OneDrive folders hold documents only. Course-note folders (`Summaries/`) have no git by design.
- **Legacy tools table** (`modern-cli-tools.md`) applies to WSL only; on Windows use the PowerShell cmdlets or Git Bash equivalents.
- **Line endings**: files created here are UTF-8 without BOM. Shell scripts meant for Bash (`compile.sh`) must stay LF.
