# Object-oriented design — principles to apply by default

General-purpose design rules, language-agnostic. Favor an object-oriented
approach whenever a problem has meaningful state and behavior to model,
regardless of language — composition and clear object boundaries first,
not procedural code passing bags of primitives around. Python-specific
instantiation (dataclasses, properties, ABC/Protocol, dunders...) is in
`rules/python/oop-idioms.md`.

## SOLID — understood properly, not the shallow version

- **SRP (Single Responsibility)** — not "one class, one job" in the vague sense. The actual definition (Robert Martin): a class must have only one reason to change. Test: list every actor/stakeholder who could plausibly request a change to this class. More than one → it violates SRP. A `User` class handling authentication AND data validation AND DB persistence has three reasons to change (security, business rules, infra) → split into three classes.
- **OCP (Open/Closed)** — open for extension, closed for modification. In practice: if adding a new case (a new payment type, a new export format) forces editing an existing `if`/`elif` chain instead of adding a new class, the design violates OCP. The Strategy pattern or plain composition solve this naturally.
- **LSP (Liskov Substitution)** — the most misunderstood one. It's not "a subclass must have the same methods." It's: any code that works with the parent type must keep working, unbeknownst to it, with any subclass, with no behavioral surprise. The classic square-inherits-rectangle example is a trap: mathematically correct, but if `Rectangle` has an independent `set_width`/`set_height`, `Square` breaks the implicit contract. Practical rule: if a subclass weakens a precondition, strengthens a postcondition, or raises an exception the parent never raises, it breaks LSP.
- **ISP (Interface Segregation)** — prefer several small, cohesive interfaces over one large one. A client must never be forced to depend on methods it doesn't use. Usually a symptom of poor responsibility splitting upstream.
- **DIP (Dependency Inversion)** — high-level modules must not depend on low-level modules; both depend on abstractions. This is what makes dependency injection and testing with mocks/fakes possible without touching business code.

## Kent Beck's Four Rules of Simple Design

In priority order, a good design:
1. Passes all tests.
2. Reveals intention (the code reads as what it does, no decoding required).
3. Has no duplication.
4. Has the fewest elements (no unnecessary classes/abstractions/indirection).

## Elegant Objects principles

A stricter, opinionated discipline — apply pragmatically, not dogmatically, but treat each as a strong default to deviate from only with a reason:
- No `null` — model absence with a type/object instead of letting `None` propagate through layers.
- No code in constructors beyond simple assignment — constructors build, they don't compute or validate at length.
- No getters/setters as a default — see "real encapsulation" below.
- No mutable objects when avoidable — prefer immutable Value Objects.
- No static methods, not even private ones — they can't be polymorphic or mocked.
- No `instanceof`/type casting/reflection as control flow — it signals a missing polymorphic design.
- No implementation inheritance as a default — see "composition over inheritance" below.

## CUPID

- **Composable**: plays well with others, easy to combine without special-casing.
- **Unix philosophy**: does one thing well.
- **Predictable**: behaves exactly as its name/signature implies, no hidden surprises.
- **Idiomatic**: feels natural in the language/ecosystem it's written in.
- **Domain-based**: the solution's structure and vocabulary mirror the problem domain's, not an abstract technical model disconnected from it.

## Composition over inheritance

Inheritance creates strong, fragile coupling (the "fragile base class problem"): changing the parent can silently break every subclass. Composition is more flexible: behaviors are assembled via member objects instead of a rigid hierarchy.

Decision rule: use inheritance only to express an "is-a" relationship that is semantically true AND stable over time. If the relationship is "has-a" or "behaves-like", use composition. When in doubt, composition is almost always the safer choice.

## Real encapsulation, not cosmetic

Encapsulation isn't "put getters/setters everywhere" — that's often an anti-pattern exposing internal state while protecting nothing. Real encapsulation means:
- Exposing behavior (methods that do things), not raw data.
- Maintaining invariants: an object must never be able to reach an inconsistent state, even through a clumsy or adversarial sequence of calls.
- **Tell, Don't Ask**: instead of asking for an object's state to decide what to do (`if account.balance < amount: ...`), tell the object to do the action itself (`account.withdraw(amount)`, which raises if it can't).

## Law of Demeter ("principle of least knowledge")

An object should only talk to its direct "friends": itself, its parameters, objects it creates locally, its direct attributes. Avoid chains like `a.get_b().get_c().get_d().do_something()` — they expose the entire object graph's internal structure and make the code extremely fragile to change.

## Design by Contract

Every public method has an implicit contract:
- **Preconditions**: what it expects on input.
- **Postconditions**: what it guarantees on output.
- **Invariants**: what must remain true about the object at all times.

Documenting and enforcing these (via assertions, validation, or types) drastically reduces integration bugs.

## Value Objects vs Entities

A distinction often neglected:
- **Entity**: has its own identity that persists over time, independent of its attributes (a `User` is still the same `User` even after their email changes). Equality by identity/ID.
- **Value Object**: fully defined by its attributes, immutable, interchangeable (an `Amount(10, "EUR")`). Equality by value.

Modeling this correctly avoids comparison bugs and makes domain intent far clearer.

## Anti-patterns to avoid

- **God Object**: a class that knows everything, does everything, depends on everything. A symptom of missing decomposition.
- **Anemic Domain Model**: classes that are just data bags (getters/setters) with all business logic scattered across external "Service" classes. Technically OOP, but loses the point — it's procedural code in disguise. Behavior should live with the data it operates on.

## Design patterns are welcome

Well-known, widely recognized design patterns (Strategy, Factory, Decorator, Observer, Adapter, etc.) are encouraged, not just tolerated — they're a shared vocabulary that makes code easier for others to read and review. Use one when it actually fits a real, current need; this is consistent with the YAGNI rule in `rules/common/coding-style.md`, not a license to add a pattern "because it might be needed later."
