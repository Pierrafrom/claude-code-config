# Common rules (all languages) — UNCOMPROMISING level

These rules are not suggestions. If a constraint below cannot be respected
without breaking something, flag it explicitly rather than silently
ignoring it.

## Clean code — non-negotiable

- **One function = one responsibility.** If a function has more than one reason to change, split it.
- **Size limit**: function > 40 lines or file > 300 lines → flag it and propose a split, unless explicitly justified (e.g. constants file, config).
- **Nuance on splitting (Ousterhout vs. dogmatic Clean Code)**: split a function into sub-functions only when each sub-function has an autonomous, reusable meaning and name — never to chase a line-count target for its own sake. Robert Martin's "Clean Code" is debated in the community precisely on this point (see the Martin/Ousterhout discussion in the book's 2nd edition appendix): excessive fragmentation into micro-functions can hurt readability by forcing the reader to jump through a dozen tiny functions to follow one logical flow. Ousterhout's "deep modules" counter-argument (simple interface, substantial implementation) is the better default here. A linear, readable 30-line function beats 5 six-line functions that must be chased like a thread to understand.
- **No magic numbers/strings**: extract into a named constant on the second use, or on the first if the value isn't self-explanatory.
- **No dead code**: no unused function, import, or variable should remain. The linter must catch it (see lint rules).
- **No duplication**: if a block of logic appears 3 times, extract it. 2 times = watch it, 3 times = mandatory.
- **Early return** rather than deeply nested branches (max 2-3 indentation levels in a function).
- **No premature abstraction** (YAGNI): don't generalize before having at least 2 real use cases.
- **Comment the "why", never the "what"**: a comment that repeats what the code already says should be removed.

## Naming — language-agnostic principles

- **Explicit, unambiguous names.** A name that needs a comment to be understood is a bad name — rename it instead of commenting.
- **A name should make obvious what a variable/function/class holds or does.** If no clear name comes to mind, treat that as a signal of a design problem (often an SRP violation — too many responsibilities to name in one word), not just a naming problem.
- **Never encode the type in the name** (`senders`, not `sender_list`) — the type system/type hint already carries that information; repeating it in the name is noise that goes stale the moment the type changes.
- **No cryptic abbreviations.** `f(x, y)` is unacceptable — prefer a name that makes the function self-documenting (`calculate_total(items, tax_rate)`).
- **Booleans read as a predicate/question**: a boolean variable or a function returning one should be named so reading it answers a yes/no question (`is_valid`, `has_permission`, `can_retry`, `should_retry`) — not as an action verb (`validate()` implies a side effect, not a query). Concrete prefix convention by language idiom (e.g. `is_`/`has_`/`can_`/`should_` in Python — see `rules/python/python-patterns.md`).
- **No boolean "flag" parameters that radically change behavior** (`def process(data, fast=False)`) — prefer two clearly named functions, or a Strategy/enum (see `rules/common/oop-design.md`). A flag parameter is usually a sign two unrelated behaviors got merged into one function.

## Object-oriented design — favor it by default

- Favor an object-oriented approach whenever a problem has meaningful state and behavior to model — full principle set (SOLID, composition over inheritance, encapsulation, Law of Demeter, anti-patterns) in `rules/common/oop-design.md`, Python instantiation in `rules/python/oop-idioms.md`.
- Recognized design patterns are welcome — they're a shared vocabulary that helps code review and collaboration. Still subject to the YAGNI rule above: use one because it fits a real, current need, not preemptively.

## Typing — strict by default, in any language that supports it

- Whenever the language has a type system (static or gradual — Python,
  TypeScript, Rust, Go, Java, C#...), use it at the strictest setting the
  language/tooling offers, not the permissive default. Concrete Python
  instantiation (`mypy --strict` baseline, modern syntax, narrowing,
  `Protocol`/generics policy) in `rules/python/typing-strict.md` — apply the
  same posture in other languages via their own strict-mode equivalent
  (TypeScript: `strict: true` in `tsconfig.json`; Rust's type system is strict
  by construction; etc.).
- **Type everything in the way that maximizes readability**, not just to
  satisfy the checker: a precise type (a domain type, a `Sequence`/`Mapping`
  read-only interface, a discriminated union/enum) documents intent better
  than a vague catch-all (`Any`, `object`, an untyped dict/map). Prefer the
  most specific type that's still honest about the contract.
- An untyped public function/method is treated by most checkers as having no
  guarantee at all on its parameters — type hints on public signatures are
  mandatory, not optional, regardless of language.
- Typing complements tests, it never replaces them — a well-typed function can
  still be logically wrong.
- Escape hatches (`# type: ignore`, `as any`, `unsafe`, a raw cast) are a last
  resort, never a convenience fix for a real type error — always paired with
  a one-line reason for why the checker can't be satisfied here.

## Dependency isolation — non-negotiable

- Project dependencies always live in an isolated environment, for any language — never installed into a global/system interpreter or package manager.
- Python (the main stack): **uv** manages the virtual environment automatically — `uv add <pkg>` / `uv add --dev <pkg>` for dependencies, `uv sync` to install from `pyproject.toml`/`uv.lock`, `uv run <cmd>` to execute inside the project's environment. Never a bare `pip install` for project dependencies.
- For a one-off, throwaway script with no `pyproject.toml` (not a project), a direct `pip install --break-system-packages` is acceptable — that's the one case dependency isolation doesn't apply, since there's no project to isolate.
- For any other language, use its ecosystem's own standard isolation tool (e.g. local `node_modules` via npm/pnpm, `bundler` for Ruby) rather than skipping isolation because no template exists here yet.

## Language of the code — non-negotiable

- **Everything that ends up in the code or project documentation is in English**, regardless of the language used in conversation with me (which stays French by default):
  - Names: variables, functions, classes, files, folders, git branches, config keys
  - Comments and docstrings
  - Commit messages and PR descriptions
  - Documentation: README, project CLAUDE.md, docs/*, changelogs
  - Log strings and error messages aimed at logs/devs (not end-user-facing messages if the app targets a French-speaking audience — in that case, state it explicitly in the project's CLAUDE.md)
- Any exception must be flagged explicitly if it exists (e.g. a French-language dataset, UI labels aimed at French-speaking users) — never apply it silently by default.
- If existing code/comments/docs in a project I'm working on are in French, flag it rather than auto-translating without an explicit request.

## Modern best practices — mandatory verification

- Before using an unfamiliar lib/API or one whose usage may have changed recently, **check up-to-date docs** (see `rules/common/doc-lookup.md`) rather than relying solely on training memory.
- Favor current idiomatic patterns of the language/framework (e.g. no deprecated pattern still seen in old tutorials).
- If a standard approach has changed recently (new API, deprecation), flag it explicitly even if the old one still works.

## Git workflow

- Atomic commits, one logical change per commit.
- Format: `type(scope): short description` — types: feat, fix, refactor, test, docs, chore, perf.
- Never commit directly to main for work in progress if the project has CI/collaboration.
- Full `git diff` reviewed before every commit — zero tolerance for forgotten debug code (print, breakpoint, untreated TODO).

## Tests

- TDD by default: failing test → minimal implementation → refactor.
- Target 80%+ coverage on business logic; throwaway/exploration scripts exempted (use judgment).
- A test should test a single behavior, named descriptively (`test_<behavior>_<condition>`).

## Security

- Zero hardcoded secret/key/token — environment variables only, never committed (see `.gitignore`).
- Systematic validation of external inputs (user, API, file).
- Added dependencies checked: actively maintained, no known CVE.

## Before every commit (mandatory checklist)

1. Clean lint (zero warnings, not just zero errors — see lint rules)
2. Full diff reviewed
3. No debug code, no dead code
4. Relevant tests run and green
5. Docs updated for any behavior/interface change — docstrings, README, `docs/*`, project CLAUDE.md (see `rules/common/documentation.md`)
6. Clear, conventional commit message
