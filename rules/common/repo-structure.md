# Repo structure — context & token optimization

A poorly structured repo forces Claude to read/grep more files than
necessary to understand a task's context. These rules reduce the volume of
tokens consumed in every session, to apply from a project's very start.

## Standard layout (Python + shell + Docker)

```
project/
├── CLAUDE.md              # context SPECIFIC to the project (inherits the global one, never repeats it)
├── README.md              # one-liner + setup — not a novel
├── pyproject.toml          # deps + centralized ruff/pytest config (no scattered config files)
├── .env.example             # documented env vars, never a committed .env
├── .gitignore               # always present, see examples-perso/.gitignore
├── .gitattributes           # always present, see examples-perso/.gitattributes — line-ending normalization, binary file marking
├── .pre-commit-config.yaml  # always present, see examples-perso/.pre-commit-config.yaml — ruff + mdformat + mypy run before every commit
├── src/
│   └── <package>/
│       ├── __init__.py
│       ├── core/            # business logic
│       ├── io/               # file/network/DB access
│       └── cli.py            # entry point if applicable
├── tests/
│   └── (mirrors src/)
├── scripts/                 # one-off scripts, exploration — exempt from strict TDD
├── logs/                    # see rules/common/logging.md — gitignored except .gitkeep
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml
└── docs/                    # organized by topic per rules/common/documentation.md (architecture, setup, testing, ADRs)
```

## Concrete rules against wasting tokens

- **A project's CLAUDE.md never repeats the global one**: it only adds what's specific (e.g. a particular data schema, a business constraint). The global context (style, rigor, default stack) is already inherited.
- **One module = one focused file.** Avoid catch-all `utils.py` files with 500 lines — Claude has to read the whole file to understand a single used function. Prefer `utils/strings.py`, `utils/dates.py`, etc.
- **Short README**: setup + run command + link to `docs/` for everything else. Full documentation rules (folder layout, docstring format, AI-readability) in `rules/common/documentation.md` — not repeated here.
- **Strict `.gitignore` from the start**: `__pycache__/`, `.venv/`, `*.pyc`, `.env`, `logs/*.jsonl`, `.pytest_cache/`, `.ruff_cache/`, `.mypy_cache/`, `.codegraph/` (local CodeGraph index, if used) — keeps Claude from reading/indexing binary or generated noise.
- **`.gitattributes` and `.pre-commit-config.yaml` are always present**, regardless of project size or rigor level — line-ending consistency and a formatting gate before every commit are non-negotiable baseline, not opt-in extras. Use the `init-project` skill to scaffold both from `examples-perso/`.
- **No duplicated config files**: anything that can live in `pyproject.toml` (ruff, pytest, mypy if used) stays there rather than in separate `.flake8`, `pytest.ini`, `setup.cfg` files. A single file to know the whole config.
- **No decorative separator comments** (`# ----- SECTION -----`) — wastes tokens with no informational value; split into files/functions instead.

## When exploring an existing repo (reducing read cost)

- Always start with the project's `README.md` + `CLAUDE.md` + layout (`tree` or equivalent), not a blind `grep -r` over the whole repo.
- Target reading to the file(s) actually relevant to the task rather than loading all of `src/` as a precaution.
- If a broad search is needed, prefer a targeted `grep`/`rg` (a precise pattern) over opening whole files one by one.
