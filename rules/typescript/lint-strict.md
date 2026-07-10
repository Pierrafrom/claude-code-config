# TypeScript/JavaScript lint — STRICT level

See `rules/common/config-standards.md` for the general "extend the
official baseline, don't rewrite it" principle — this file is the
JS/TS instantiation, mirroring `rules/python/lint-strict.md`.

## Tool choice — Biome vs ESLint + Prettier

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

## Biome config — extend `biome:recommended`

```jsonc
// biome.json
// Base: biomejs.dev/reference/configuration/ — extends biome:recommended
{
  "$schema": "https://biomejs.dev/schemas/1.x/schema.json",
  "extends": ["biome:recommended"],
  "formatter": {
    "lineWidth": 100,
    "indentStyle": "space",
    "indentWidth": 2
  },
  "linter": {
    "rules": {
      "recommended": true,
      "suspicious": {
        "noExplicitAny": "warn"
      },
      "correctness": {
        "noUnusedVariables": "warn"
      }
    }
  },
  "organizeImports": { "enabled": true }
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
