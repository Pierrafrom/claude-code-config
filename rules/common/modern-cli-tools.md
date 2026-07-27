# Modern CLI toolset — WSL2 Ubuntu / Fish environment

Concrete instantiation of the OS/shell environment named in this config's
own "Stack & environment" section: every tool below is actually installed
and configured on this machine, not a suggestion to install. Source of
truth for exact versions/install method/update procedure is
`~/Code/dotfiles/TOOLS.md` (current state) and `CHANGELOG.md` (history) —
read those instead of re-deriving the setup from scratch when working
inside that repo.

## Default to the modern tool over the legacy one

When suggesting a shell command **to run interactively on this machine**,
prefer the installed modern replacement over the legacy POSIX tool it
replaces — all of them are faster, have better defaults (`.gitignore`
-aware, colored output), and the user already knows their basic usage:

| Legacy | Use instead | Why |
|---|---|---|
| `find` | `fd` | Respects `.gitignore`, simpler syntax, faster |
| `grep` | `rg` (ripgrep) | Same, plus better default output |
| `cat` | `bat` (aliased over `cat` itself, see `dotfiles/fish/conf.d/bat.fish`) | Syntax highlighting, git-change markers, line numbers |
| `ls`/`ll`/`la` | `eza` (aliased, see `dotfiles/fish/conf.d/eza.fish`) | Icons, git status, native `--tree`/`--level=N` |
| `ps` | `procs` | Colored, tree-aware, readable columns |
| `top`/`htop` | `btop` (`htop` was removed — redundant, `top` still exists as the POSIX fallback) | Modern UI, mouse support, graphs |
| `du` | `dust` | Same info, sorted and visually scannable |
| `df` | `duf` | Table output instead of raw columns |
| `diff` | `delta` (also git's configured pager/diffFilter — every `git diff`/`git log` already goes through it) | Syntax-highlighted, side-by-side |
| `curl` (for API calls specifically, not downloading files) | `xh` | HTTPie-like ergonomics (`xh POST url key=value`), single fast binary |
| `cd` | still `cd` — it *is* the modern tool | Wired to zoxide (`--cmd cd`, see `dotfiles/fish/conf.d/zoxide.fish`): `cd <fragment>` fuzzy-jumps by frecency, exact paths behave exactly as plain `cd` always did |
| `man <cmd>` for a quick "how do I..." | `tldr <cmd>` first, `man` for the full reference | tldr is examples-first, much faster to scan |
| file browser (`yazi` — removed, was unused) | `spf` (superfile) | `cd_on_quit` wired — quitting `spf` `cd`s the shell to wherever was navigated |

**Exception**: shared/reusable scripts (anything meant to run on another
machine or in CI) must stick to POSIX tools (`find`, `grep`, `ps`...) —
same reasoning as this config's shell-detection rule (`rules/common/shell-fish.md`)
for why portable scripts never assume the interactive environment. This
table is about commands suggested for *this user, this machine,
interactively* — not about what to write inside a script.

## fzf — deep integration, not just installed

`patrickf1/fzf.fish` (fisher) provides fuzzy widgets bound to key sequences,
extended in `dotfiles/fish/conf.d/fzf-custom.fish` with `bat`/`eza`/`delta`
previews and a Catppuccin Mocha theme:

| Binding | Does |
|---|---|
| Ctrl+R | Command history search |
| Alt+Ctrl+F | Fuzzy file/directory search in the current directory |
| Alt+Ctrl+L | `git log` search with commit preview |
| Alt+Ctrl+S | `git status` search with diff preview |
| Alt+Ctrl+P | Process search |
| Ctrl+V | Shell variable search |
| Alt+Ctrl+G | **Content** search (live `ripgrep`, not just filenames) — the one widget not provided by the plugin itself |

Plus three standalone functions built on the same `fzf` primitives:
`fkill` (kill a process, `-9` to force), `fbr` (checkout a git branch),
`fcd` (`cd` into a directory found by `fd`).

`fzf` itself, `bat`, and `zoxide` are **not** the apt-packaged versions —
apt's copies on this Ubuntu release were years out of date and broke real
functionality (git-delta panicking, `--scheme` unsupported, an actual
infinite-recursion bug in zoxide's old `cd` codegen — full story in
`dotfiles/CHANGELOG.md`). They're cargo-installed or a manual GitHub
release binary instead — see `dotfiles/TOOLS.md` for exactly which.

## Terminal tips system

`dotfiles/fish/conf.d/tips.fish` prints a one-line, non-blocking hint (once
per session per command) when the user types a legacy command that has a
modern installed replacement — same table as above, surfaced live instead
of only living in this doc.

## Maintenance — this is the user's job, not something to suggest recreating

Everything above is kept up to date via fish functions already defined in
`~/Code/dotfiles/fish/functions/`: `update-all` (updates every ecosystem —
apt, cargo, uv, fnm/npm/pnpm — and retires superseded versions, e.g. old
`uv`-managed Python patches or the previous Node LTS), `clean-all` (prunes
caches), `clean-heavy` (interactive `node_modules`/`.venv` sweep),
`check-global-deps` (verifies no pip/npm dependency leaked outside a
project venv). Don't propose reinventing any of these — if one seems to be
missing something, check `TOOLS.md`/`CHANGELOG.md` first, it's very likely
already covered or a deliberate decision is documented there.

## CodeGraph doesn't apply to this repo or to `dotfiles`

Both `claude-code-config` (markdown rules) and `~/Code/dotfiles` (Fish
scripts + TOML/config files) yield little to nothing for CodeGraph to
index — Fish isn't a language CodeGraph parses (`codegraph init` in
`dotfiles` returns "No files found to index"), and a pure-markdown repo has
no real symbol/call graph. Don't suggest running `codegraph init` in
either — for these two repos, `grep`/`rg`/Read (or `Explore` for anything
broader) is the actual efficient path, and `dotfiles/TOOLS.md` +
`CHANGELOG.md` are the current-state/history entry points to read first
(same "start with the README, not a blind grep" principle as
`rules/common/repo-structure.md`).
