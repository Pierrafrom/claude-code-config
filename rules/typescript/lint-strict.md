# TypeScript/JavaScript lint — STRICT level

See `rules/common/config-standards.md` for the general "extend the
official baseline, don't rewrite it" principle — this file is the
JS/TS instantiation, mirroring `rules/python/lint-strict.md`.

## Tool choice — Biome vs ESLint + Prettier

Biome and ESLint are genuine competitors on the same ground (lint +
format) — the rule below is which ONE leads a given project, not both
running in parallel as a full duplicate setup.

- **Biome**: lint + format in a single tool, sub-500ms on ~300 files, no
  separate formatter needed. Default choice for a new TypeScript project
  with no strong dependency on the ESLint plugin ecosystem.
- **ESLint (flat config) + Prettier**: keep when the project needs
  `eslint-plugin-react-hooks` (`rules-of-hooks` / `exhaustive-deps`) or
  type-aware rules Biome doesn't yet fully cover (e.g.
  `@typescript-eslint/no-floating-promises`).
- **Practical rule**: non-React TypeScript project with a standard config
  → Biome covers it with no gap. React project, or anything needing
  type-aware linting → ESLint + `typescript-eslint` for those specific
  rules, Biome or Prettier for formatting either way.

### Current gap (check this periodically, it's actively closing)

As of mid-2026: Biome has type-aware linting, but not the deepest
cross-file generic resolution the full TypeScript language service does;
and Biome's rules-of-hooks coverage doesn't yet match the full
`eslint-plugin-react-hooks` v6/v7 rule set. For a React project, ESLint
is still the safer default for those two rule families specifically.

### Hybrid pattern — Biome as the primary tool, ESLint as a thin add-on

Rather than a full duplicate ESLint setup, keep Biome as the primary
lint+format tool and load ESLint only for the specific rule families
Biome doesn't cover yet:

```js
// eslint.config.js
// Thin ESLint layer on top of Biome — NOT a full duplicate setup.
// Biome (biome.json) stays the primary lint+format tool; this file only
// loads the rule families Biome doesn't fully cover yet (mid-2026):
// eslint-plugin-react-hooks and deep type-aware @typescript-eslint rules.
// Re-check rules/typescript/lint-strict.md's "current gap" note before
// assuming this is still needed — Biome is actively closing it.
import tseslint from "typescript-eslint";
import reactHooks from "eslint-plugin-react-hooks";

export default tseslint.config({
  plugins: { "react-hooks": reactHooks },
  rules: {
    ...reactHooks.configs.recommended.rules,
    "@typescript-eslint/no-floating-promises": "error",
  },
});
```

Run Biome for everything else (formatting, general lint, import
organization); this ESLint config exists solely to fill the two known
gaps, not to re-implement what Biome already does.

## Biome config — extend the `recommended` preset

Biome 2.x changed the config format from 1.x — `extends: ["biome:recommended"]`
no longer resolves (`Could not resolve biome:recommended: module not
found`). The current mechanism is `linter.rules.preset: "recommended"`,
and `organizeImports` moved under `assist.actions.source`. Generate the
baseline with `npx biome init` against the actually-installed version
rather than hand-writing it — the schema URL is version-pinned
(`schemas/<installed-version>/schema.json`) and drifts on every Biome
release, so a copy-pasted example goes stale fast. Below is the shape
confirmed against Biome 2.5.3 (2026-07-16); re-verify against a fresh
`biome init` output before trusting an older copy of this file.

```jsonc
// biome.json
// Base: generate with `npx biome init`, then layer these overrides in —
// don't hand-write from scratch. biomejs.dev/reference/configuration/
{
  "$schema": "https://biomejs.dev/schemas/2.5.3/schema.json",
  "vcs": {
    "enabled": true,
    "clientKind": "git",
    "useIgnoreFile": true
  },
  "files": {
    "ignoreUnknown": false
  },
  "formatter": {
    "enabled": true,
    "indentStyle": "space",
    "indentWidth": 2,
    "lineWidth": 100
  },
  "linter": {
    "enabled": true,
    "rules": {
      "preset": "recommended",
      "suspicious": {
        "noExplicitAny": "warn"
      },
      "correctness": {
        "noUnusedVariables": "warn"
      }
    }
  },
  "javascript": {
    "formatter": {
      "quoteStyle": "double"
    }
  },
  "assist": {
    "enabled": true,
    "actions": {
      "source": {
        "organizeImports": "on"
      }
    }
  }
}
```

**Known rule conflict**: Biome's `complexity/useLiteralKeys` (wants
`obj.key` dot notation) structurally conflicts with TypeScript's
`noPropertyAccessFromIndexSignature` (see the strict `tsconfig.json`
baseline below), which *requires* bracket notation — `obj["key"]` — for
any value typed via an index signature (`process.env`, CSS Modules
imports, etc.). This isn't a one-off; it recurs for any project using
either. Resolve by disabling the Biome rule in favor of the TypeScript
flag, since the strict-typing baseline is the more foundational,
deliberately-adopted convention:

```jsonc
"linter": {
  "rules": {
    "complexity": {
      "useLiteralKeys": "off"
    }
  }
}
```

## ESLint config — extend `typescript-eslint` presets, never hand-roll

```js
// eslint.config.js
// Base: typescript-eslint.io/users/configs/ — v8.x (check for breaking
// changes on major bumps). strictTypeChecked / stylisticTypeChecked are
// explicitly NOT covered by typescript-eslint's semver stability
// guarantee — their rule set can change on a minor version bump.
import js from "@eslint/js";
import { defineConfig } from "eslint/config";
import tseslint from "typescript-eslint";

export default defineConfig([
  // 1. Official JS baseline
  js.configs.recommended,

  // 2. Official TypeScript preset — strict + type-checked + stylistic
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,

  // 3. Parser config required for type-aware rules
  {
    languageOptions: {
      parserOptions: {
        projectService: true,
        tsconfigRootDir: import.meta.dirname,
      },
    },
  },

  // 4. Minimal overrides on top of the official presets
  {
    rules: {
      "@typescript-eslint/no-floating-promises": "error", // correctness — always error
      "@typescript-eslint/consistent-type-imports": [
        "error",
        { prefer: "type-imports" },
      ],
      "@typescript-eslint/no-unused-vars": [
        "warn",
        { argsIgnorePattern: "^_", varsIgnorePattern: "^_" },
      ],
      "no-console": ["warn", { allow: ["warn", "error"] }],
    },
  },

  // 5. Test-file relaxation — never loosen the global config instead
  {
    files: ["**/*.{test,spec}.{ts,tsx}", "tests/**"],
    rules: {
      "@typescript-eslint/no-unsafe-assignment": "off",
      "@typescript-eslint/no-explicit-any": "off",
    },
  },

  // 6. React projects — add on top:
  // eslint-plugin-react + eslint-plugin-react-hooks
  // "react-hooks/rules-of-hooks": "error"
  // "react-hooks/exhaustive-deps": "warn"
]);
```

## Formatting mechanics (Biome or Prettier — pick one, automate it)

- Line length: 100 (Biome default) or 80/120 by project convention — the
  automation matters, not the specific number.
- Semicolons and quote style: pick one convention, enforce it via the
  formatter — never a human judgment call per file.
- Trailing commas on multi-line lists — cleaner diffs, no reordering
  noise.
- ESM imports always at the top, grouped: Node built-ins → external →
  internal, blank line between groups. No inline dynamic imports for
  synchronous code paths.

## Naming — mechanically enforced where possible

- `camelCase` variables/functions, `PascalCase` classes/types/interfaces/
  components, `UPPER_SNAKE_CASE` module-level constants, `kebab-case` file
  names.
- A file is named after its default export: a `UserCard` component lives
  in `UserCard.tsx`, a `useAuth` hook in `useAuth.ts`.

## Expected behavior from Claude

- Zero tolerance on warnings, not just errors, before considering
  TS/JS code done — same bar as `ruff check .` for Python.
- Run the project's actual lint command (`biome check .` or
  `eslint .`) plus `tsc --noEmit` before presenting code as done.
- Never silence a real lint error with an inline disable comment
  without an explicit one-line justification.
- When generating a new config, always extend the official preset (see
  `rules/common/config-standards.md`) — never write rule selections from
  scratch.

## Sources to watch (best-practice drift)

| Domain | Canonical source | Change signal |
|---|---|---|
| `typescript-eslint` configs | typescript-eslint.io/users/configs/ | Release notes on major/minor bumps |
| ESLint rules | eslint.org/docs/latest/rules/ | ESLint v9+ changelog |
| `tsconfig` options | typescriptlang.org/tsconfig | TypeScript release notes |
| Biome rules | biomejs.dev/linter/rules/ | Biome changelog |
| React patterns | react.dev/learn | Official React blog |

A config generated today is a snapshot of current best practice, not a
permanent truth — re-check the relevant source above before assuming an
older config is still idiomatic.
