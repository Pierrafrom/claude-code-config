# TypeScript typing — STRICT level

Typing is a design tool, not decoration — same posture as
`rules/python/typing-strict.md`. This file is the mechanical baseline:
what `tsconfig` flags to use, which patterns are mandatory, and how to
handle the cases that resist typing cleanly.

See `rules/common/config-standards.md` for the general "extend the
official baseline, don't rewrite it" principle this file follows.

## Baseline: `strict: true`, not optional

```jsonc
// tsconfig.json
// Base: typescriptlang.org/tsconfig — extend strict, don't hand-pick flags
{
  "compilerOptions": {
    "strict": true, // bundles ~8 flags: noImplicitAny, strictNullChecks,
                     // strictFunctionTypes, strictBindCallApply,
                     // strictPropertyInitialization, noImplicitThis,
                     // useUnknownInCatchVariables, alwaysStrict

    // Flags strict:true does NOT include — add explicitly:
    "noUncheckedIndexedAccess": true,   // array/index access returns T | undefined
    "noImplicitOverride": true,         // requires explicit `override` keyword
    "exactOptionalPropertyTypes": true, // distinguishes `undefined` from "absent"
    "noPropertyAccessFromIndexSignature": true,
    "noFallthroughCasesInSwitch": true,

    "moduleResolution": "bundler", // correct default for Vite/Next.js/any bundler
    "module": "ESNext",
    "target": "ES2022",

    "esModuleInterop": true,
    "skipLibCheck": true, // acceptable for third-party .d.ts noise; never
                           // relied on to hide errors in your own files
    "forceConsistentCasingInFileNames": true,
    "incremental": true
  }
}
```

- `strict = true` is the floor, not the ceiling — in 2026 there is no
  excuse for a project outside strict mode.
- The five extra flags above are not part of `strict` and must be added
  by hand — `noUncheckedIndexedAccess` in particular catches a very common
  class of runtime `undefined` bugs that `strict` alone misses.
- `skipLibCheck: true` speeds up compilation by skipping `.d.ts` checking
  in `node_modules` — fine for third-party noise, never a substitute for
  fixing type errors in your own declaration files.

## `any` is mandatory to avoid — it propagates

A function returning `any` means every caller receives `any`, and every
caller's caller after that — a small amount of `any` at a low level
silently untypes a large fraction of the call graph above it. You get
TypeScript's syntax without its guarantees.

- Use `unknown` instead of `any` for values whose type is genuinely not
  known yet, and narrow explicitly before use.
- Use `never` for branches that are supposed to be unreachable (exhaustive
  `switch` over a union, impossible error states) — the compiler flags it
  if a new case makes the branch reachable.

## `@ts-ignore` — last resort, `@ts-expect-error` preferred

- `@ts-ignore` is banned except in a documented, justified case (same bar
  as Python's `# type: ignore` policy).
- Prefer `@ts-expect-error`: it fails loudly the moment the underlying
  type error is fixed, instead of silently becoming a stale, meaningless
  comment like `@ts-ignore` does.

```ts
// @ts-expect-error — legacy untyped vendor callback, no upstream types available
vendorSdk.call(untypedArg);
```

## `interface` vs `type` — pick by role, stay consistent

- `interface` for object shapes that are part of a public API or might be
  extended (declaration merging).
- `type` for unions, intersections, and mapped types.
- Consistency across the repo matters more than the specific rule — never
  mix conventions file to file for the same kind of shape.

## Inference vs explicit annotation

Let TypeScript infer when the type is obvious from the assignment
(`const name = "John"` — no `: string` needed). Annotate explicitly on
public function signatures, parameters, and return types — an untyped
public function is, for the same reason as Python, treated as having no
real guarantee at all.

## Discriminated unions over optional-property soup

Preferred over a bag of optional properties for complex state — the
compiler narrows automatically on the discriminant and forces every case
to be handled:

```ts
type ApiResponse<T> =
  | { status: "success"; data: T }
  | { status: "error"; message: string; code: number };
```

## Branded types for semantically distinct primitives

Prevents mixing values that share a primitive type but aren't
interchangeable (`UserId` vs `OrderId`, both `string`):

```ts
type UserId = string & { readonly __brand: "UserId" };
type OrderId = string & { readonly __brand: "OrderId" };
```

## Utility types before custom types

`Partial`, `Required`, `Pick`, `Omit`, `Record`, `Readonly` before hand
-rolling an equivalent — any change to the base interface then propagates
automatically instead of drifting out of sync with a duplicate.

## Generics — only for a real, current reuse need

Same YAGNI posture as Python generics (`rules/python/typing-strict.md`).
`<T>` for containers/repositories with more than one concrete use case
already in hand — not on every function "just in case."

## `satisfies` over `as`

`satisfies` validates structure without widening the type and, unlike
`as`, doesn't bypass type checking:

```ts
const routes = {
  home: "/",
  about: "/about",
} satisfies Record<string, string>;
```

## `Readonly<T>` / `ReadonlyArray<T>` on non-mutating parameters

Documents intent and is statically checked — use for any function
parameter that reads but must not mutate its input.

## Type guards over `as` casting

Prefer an explicit type-predicate guard (`value is User`) for reusable
narrowing over an `as` assertion, which asserts and doesn't verify:

```ts
function isUser(value: unknown): value is User {
  return typeof value === "object" && value !== null && "id" in value;
}
```

## `catch` is `unknown` in strict mode — always narrow it

```ts
try {
  await riskyCall();
} catch (error) {
  if (error instanceof Error) {
    logger.error(error.message);
  }
  throw error;
}
```

Never access `.message` (or any property) on a caught value without
narrowing first — `strict: true` makes the caught value `unknown`, and
skipping the check is exactly the kind of implicit-any hole `strict`
exists to close.

## Expected behavior from Claude

- Write full type annotations on every public function/method as the code
  is written, not as a follow-up pass — same standing rule as Python.
- Run `tsc --noEmit` before presenting TypeScript code as done; treat a
  strict-mode error the same as a lint warning — fix it, don't suppress
  it.
- If a third-party lib has no types and genuinely blocks strict typing for
  one module, flag it explicitly rather than silently loosening `strict`
  project-wide.
