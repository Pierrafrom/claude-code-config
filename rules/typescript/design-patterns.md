# TypeScript/JavaScript architecture and error handling

Concrete JS/TS instantiation of `rules/common/oop-design.md` — same
principles (composition over inheritance, real encapsulation, SOLID), how
they materialize in an ESM/functional-leaning language. Mirrors
`rules/python/oop-idioms.md`'s role for Python.

## Composition over inheritance

Same default as `rules/common/oop-design.md`. In JS/TS, composition
materializes naturally via higher-order functions, object composition,
and interfaces — there's rarely a reason to reach for a class hierarchy
when a function taking a dependency, or an object built from smaller
pieces, does the job.

## Dependency injection via constructor, not framework

Pass dependencies through the constructor (or a factory function) rather
than instantiating them inside a class — makes code testable without a DI
framework in most cases:

```ts
class OrderService {
  constructor(private readonly repository: OrderRepository) {}
}
```

For genuinely complex dependency graphs, `InversifyJS` or `tsyringe` are
reasonable — don't reach for them by default (YAGNI, same as everywhere
else in this config).

## Repository pattern for data access

Type the `Repository` interface, provide one concrete implementation per
backing store. Makes code testable (mock the interface), swappable
(change database without touching callers), and type-safe end to end:

```ts
interface UserRepository {
  findById(id: UserId): Promise<User | null>;
  save(user: User): Promise<void>;
}
```

## Singleton via ESM module, not a `getInstance()` class

The module system guarantees a module is evaluated once — exporting an
instance directly from the module is the idiomatic JS singleton, no class
ceremony required:

```ts
// db.ts
export const db = createConnection(config);
```

## Strategy via first-class functions

A strategy can be a plain function passed as a parameter — reserve an
interface + injection setup for when multiple strategies genuinely need a
shared, richer contract:

```ts
type PricingStrategy = (order: Order) => number;

function checkout(order: Order, pricing: PricingStrategy): number {
  return pricing(order);
}
```

## Immutability for shared data structures

Prefer operations that return new values (`map`, `filter`, spread) over
in-place mutation (`push`, `splice`) for anything shared across scopes.
`Object.freeze()` or `Readonly<T>` (see `rules/typescript/typing-strict.md`)
for configuration objects that must never mutate.

## Error handling

### Never let an error evaporate

No empty `catch {}` or `catch (e) {}`. Either handle the error, rethrow
it, or log it with context — same posture as
`rules/common/logging.md`'s "never a vague message" rule.

### Result pattern for expected failure

When failure is a normal outcome of business logic (not a bug), make it
explicit in the return type instead of throwing — forces the caller to
handle it:

```ts
type Result<T, E = Error> =
  | { success: true; data: T }
  | { success: false; error: E };
```

Reserve actual exceptions for genuinely unexpected cases (a bug, a system
failure) — not for "the user wasn't found," which is an expected branch.

### Custom error hierarchy per domain

```ts
class DomainError extends Error {
  constructor(message: string) {
    super(message);
    this.name = new.target.name;
  }
}

class UserNotFoundError extends DomainError {
  constructor(public readonly userId: UserId) {
    super(`user not found: ${userId}`);
  }
}
```

A domain-specific hierarchy (`class UserNotFoundError extends Error`)
over a generic `new Error("something went wrong")` — enables selective
`catch` and structured logging, exactly the same rationale as the Python
exception-hierarchy rule in `rules/python/oop-idioms.md`.

### Never `throw` a bare string or plain object

Always throw an `Error` instance (or subclass) — anything else loses the
stack trace.
