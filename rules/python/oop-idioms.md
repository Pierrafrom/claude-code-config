# Python OOP idioms

Concrete Python instantiation of `rules/common/oop-design.md`. Apply these
by default when modeling stateful behavior in Python — see that file for
the underlying principles (SOLID, composition over inheritance, real
encapsulation, etc.).

## Dataclasses and their pitfalls

```python
from dataclasses import dataclass, field


@dataclass(frozen=True, slots=True)
class Point:
    x: float
    y: float
```

- `frozen=True` for immutability (Value Objects) — bonus: makes the object hashable automatically if every field is.
- `slots=True` (Python 3.10+) for memory efficiency and to forbid dynamically adding attributes (fail-fast on typos).
- Classic trap: never a mutable default (`field: list = []`). Always `field(default_factory=list)`.

## Properties — pythonic encapsulation

Python has no real private/protected, just a convention (`_attr`, `__attr` with name mangling). Good practice: start with simple public attributes, and migrate to a `@property` only once real logic is needed (validation, derived computation, lazy loading). This preserves the public API without breaking calling code.

```python
class Temperature:
    def __init__(self, celsius: float) -> None:
        self._celsius = celsius

    @property
    def celsius(self) -> float:
        return self._celsius

    @celsius.setter
    def celsius(self, value: float) -> None:
        if value < -273.15:
            raise ValueError("temperature below absolute zero")
        self._celsius = value

    @property
    def fahrenheit(self) -> float:
        return self._celsius * 9 / 5 + 32
```

## ABC and Protocol — two polymorphism philosophies

- **ABC** (`abc.ABC`): explicit nominal inheritance. Useful when you control the whole hierarchy and want to force implementation of methods (`@abstractmethod`).
- **Protocol** (`typing.Protocol`): structural typing, real duck typing with static checking. No explicit inheritance needed — if the object has the right methods/signatures, it satisfies the protocol. Often preferable in modern Python: it respects the language's spirit and fully decouples implementations from interfaces.

```python
from typing import Protocol


class Drawable(Protocol):
    def draw(self) -> str: ...


def render(shape: Drawable) -> None:
    print(shape.draw())
```

No class needs to inherit from `Drawable` — mypy just checks the shape.

## Dunder methods — compose with the language, not against it

Implement `__eq__`, `__hash__`, `__repr__`, `__lt__` (or `functools.total_ordering`), `__enter__`/`__exit__` for context managers, `__iter__`/`__next__` for custom iterables. This is what makes objects first-class citizens of the language — they integrate with `sorted()`, `in`, f-strings, `with`, instead of reinventing `.equals()`/`.compareTo()`-style methods.

Golden rule: if `__eq__` is defined, define `__hash__` consistently with it (or set it to `None` explicitly if the object is mutable and shouldn't be hashable).

## Composition the idiomatic way: disciplined mixins

Mixins are the pythonic version of composing behaviors via multiple inheritance — but they need discipline:
- A mixin must never have its own `__init__` with complex state.
- A mixin must never be instantiated on its own.
- Name it with a `Mixin` suffix by convention, with a single, clear role (`SerializableMixin`, `ComparableMixin`).

## `__init_subclass__` and metaclasses — use sparingly

`__init_subclass__` lets you validate/configure subclasses at definition time (registry pattern, contract validation) without the complexity of a full metaclass. Rule: always prefer `__init_subclass__` or a decorator over a custom metaclass — metaclasses are rarely justified and hurt readability a lot.

## Exceptions — custom hierarchy, specific catches

```python
class DomainError(Exception):
    """Base exception for business-rule errors."""


class InsufficientFundsError(DomainError):
    def __init__(self, balance: float, requested: float) -> None:
        self.balance = balance
        self.requested = requested
        super().__init__(f"balance {balance} insufficient for {requested}")
```

Never a generic `except Exception` in production code except at system boundaries (API handler, main loop). Catch the most specific type possible, and build a business exception hierarchy that mirrors the domain — it documents error contracts the same way types document data contracts.

## Strict typing as an OOP discipline

Typing in Python isn't cosmetic — it's a design tool. `mypy --strict` forces every method's contract to be explicit, catches LSP violations (incompatible signatures), and makes polymorphism explicit. Use generics (`TypeVar`, `Generic[T]`) for reusable container classes, and union types (`X | Y`) rather than a lazy `Any`. Full mandatory baseline (mypy config, modern syntax, `Protocol`/`TypedDict`/`Self`, `# type: ignore` policy) in `rules/python/typing-strict.md`.

## `__slots__` as an invariant discipline

Beyond performance, `__slots__` blocks dynamically adding undeclared attributes — it forces every class to have a closed, explicit structure, directly in line with the Design by Contract invariant principle in `rules/common/oop-design.md`.

## Python-specific anti-patterns to avoid

- **Excess `@staticmethod`**: usually a sign the function has no business being in the class — move it to a module-level function instead.
- **Getters/setters with no logic**: in Python, a plain public attribute is already the equivalent of a Java getter/setter with no logic. Only add a `@property` when there's a real reason.
- **Cascading `isinstance()` to simulate type pattern matching**: use polymorphism (a virtual method) instead, or, since 3.10, real structural `match`/`case`.
