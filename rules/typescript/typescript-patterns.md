# TypeScript/JavaScript rules

See `rules/typescript/typing-strict.md` for the strict-typing baseline and
`rules/typescript/lint-strict.md` for tooling/formatting (Biome/ESLint).
This file covers modern JS idioms, error handling, async patterns, tests,
and context-specific conventions (Node.js backend, React frontend).
`rules/typescript/design-patterns.md` covers composition/DI/architecture
patterns and the custom error hierarchy.

## Modern JavaScript idioms

- `const` by default, `let` only when reassignment is required. Never
  `var`.
- Destructuring to pull properties off objects/arrays — clearer than
  repeated chained access.
- Optional chaining (`?.`) and nullish coalescing (`??`) over an `if`
  cascade: `config.database?.host ?? "localhost"`.
- Template literals over string concatenation with `+`.
- Spread for shallow copies (`{...obj}`, `[...arr]`) — clearer than
  `Object.assign` outside a specific reason to use it.
- `for...of` to iterate iterables — preferred over `forEach` (no
  well-defined `break`/`continue`/`return`) and over `for...in` (iterates
  prototype-chain properties too).
- ESM only: `import`/`export`, never `require()` in new code.
  `"type": "module"` in `package.json` for Node projects.

## Async and concurrency

- `Promise.all` for independent async operations run in parallel.
  `Promise.allSettled` when partial failure is acceptable and results are
  still needed either way. Never `await` independent promises
  sequentially inside a loop.
- `async`/`await` everywhere over `.then()`/`.catch()` chains — more
  readable, and stack traces stay usable.
- **Floating promises are a bug class, not a style nit**: never call an
  async function without `await`-ing it or chaining `.catch()` — the
  error otherwise evaporates silently. Enforce with
  `@typescript-eslint/no-floating-promises` or Biome's
  `noFloatingPromises` (see `rules/typescript/lint-strict.md`).
- `new Promise()` wrapped around code that's already async is a classic
  anti-pattern that complicates error handling for no benefit — use
  `async`/`await` directly instead.
- Cancel long-running/abortable operations (especially `fetch`) with
  `AbortController` — the 2026 standard, no external dependency needed.
- Debounce/throttle handlers on frequent events (`resize`, `scroll`,
  `input`) — never call an expensive function or an API directly inside a
  frequent event listener.
- Guard against race conditions when two async calls can resolve in
  either order — protect the result with a cancellation flag or
  `AbortController`, don't assume completion order.

## Anti-patterns to ban

- **Explicit `any`** — each `any` is a hole in the type system. Use
  `unknown` and narrow explicitly, or `never` for branches that should be
  unreachable.
- **`as X` without a prior runtime check** — an assertion verifies
  nothing at runtime. Reserve assertions for cases where the runtime
  check (an `instanceof` or a type guard) already happened.
- **Cascading casts** (`obj as unknown as TargetType`) — a strong smell
  that the type model upstream is wrong, not a fix.
- **Silent mutation of a parameter** that isn't obvious from the
  name/signature — a hidden side effect. Document it explicitly or return
  a new object instead.
- **`console.log` in production** — use a structured logger (see
  `rules/common/logging.md` for the JSONL format/fields this project
  standardizes on; `pino` is a good fit for structured JSON logging in
  Node). Configure `no-console` at `warn` minimum.
- **Callback hell** — more than 2 levels of nested callbacks is a signal
  to refactor to `async`/`await`.
- **`delete obj.property`** to remove a key — prefer rest destructuring:
  `const { keyToRemove, ...rest } = obj`.
- **`==`** — always `===`. Implicit coercion from `==` is a well-known
  source of silent bugs.
- **Mutating `Array.prototype`/`Object.prototype`** — never extend native
  prototypes; it causes unpredictable name collisions with other
  libraries.

## Testing (Vitest / Jest)

- **Vitest** is the 2026 default for Vite/Next.js projects — Jest
  -compatible API, faster, native ESM with no extra config. Jest with
  `ts-jest` or `@swc/jest` only for a legacy project already on Jest.
- Structure tests as **Arrange / Act / Assert**, one blank line between
  phases.
- Mock your own code's interfaces, not third-party library internals —
  needing to mock a vendor module's internals signals coupling that's too
  tight.
- One test verifies one observable behavior (not necessarily one
  `expect`, but one behavior).
- Test names describe observable behavior: `"should return null when
  user is not found"`, not `"test getUser"`.

## Node.js backend specifics

- Validate environment variables at startup with Zod or `t3-env` — never
  read `process.env.X` directly in business code; go through a typed
  config object that fails fast if a variable is missing.
- Use the `node:` prefix for built-in imports
  (`import { readFile } from "node:fs/promises"`) — more explicit and
  marginally faster to resolve.
- Handle graceful shutdown: catch `SIGTERM`/`SIGINT` to close DB
  connections and HTTP servers cleanly before the process exits.

## React frontend specifics

- Type public component props with `interface`, destructured directly in
  the component signature.
- `ReactNode` for props accepting JSX children — never `JSX.Element`
  (too restrictive) or `any`.
- Extract complex state logic into a custom hook — a component with more
  than 3-4 `useState`/`useEffect` calls is a candidate for extraction.
- Co-locate a component's own types, utils, and hooks in the same folder
  — a global `types/` folder only for things genuinely shared across
  components.
- For component styling/design-system decisions, see
  `rules/frontend/design-skill-routing.md` — which installed design skill
  to reach for depends on whether the surface is marketing/landing
  (brand-oriented) or product/dashboard UI.

## Dependencies & environment

- **pnpm** as the default package manager: fast, disk-efficient
  (content-addressable store), and strict by default — no phantom
  dependencies from hoisting the way plain `npm` allows. `npm` is
  acceptable when a project constraint requires it.
- Always an isolated `node_modules` per project via the lockfile
  (`pnpm-lock.yaml` / `package-lock.json`) — never a global install for a
  project dependency, mirroring the `uv` rule for Python
  (`rules/python/python-patterns.md`).

## Common mistakes to avoid

- A `type`/`interface` choice that's inconsistent file to file — pick one
  convention per shape kind (see `rules/typescript/typing-strict.md`) and
  hold the line repo-wide.
- Re-deriving a type by hand instead of using a utility type (`Partial`,
  `Pick`, `Omit`, `Record`) — drifts out of sync with the base type.
- Skipping the `catch (error)` narrowing step — `error` is `unknown` in
  strict mode, not `Error` (see `rules/typescript/typing-strict.md`).
- Excessive generics on functions with a single call site — premature
  abstraction, same YAGNI rule as everywhere else in this config.
