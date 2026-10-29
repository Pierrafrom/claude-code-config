---
paths:
  - "**/*.py"
  - "**/pyproject.toml"
---

# FastAPI — project structure by complexity level

See `rules/common/project-architectures.md` for the governing rule: pick
the level that matches the project's actual size today, not the one that
looks the most sophisticated. Jumping straight to the hexagonal layout
for a 5-route internal tool is over-engineering in the exact way
`rules/common/coding-style.md`'s YAGNI rule warns against.

**Source**: community-compiled production patterns, not a single official
FastAPI doc the way Next.js has one — treat this as a well-established
convention, not a canonical spec, and adapt it if a project's real needs
diverge.

## Level 1 — small service / MVP (layer-based)

Acceptable up to roughly 10 routes and 2-3 developers. Past that, migrate
to level 2 rather than letting the layer folders grow indefinitely.

```
my-api/
├── app/
│   ├── main.py               # FastAPI app + included routers
│   ├── routers/
│   │   ├── users.py
│   │   └── items.py
│   ├── models/                # SQLAlchemy models
│   │   └── user.py
│   ├── schemas/               # Pydantic request/response schemas
│   │   └── user.py
│   ├── services/              # Business logic
│   │   └── user_service.py
│   ├── db/session.py
│   └── core/
│       ├── config.py          # Pydantic Settings
│       └── security.py
├── tests/
│   └── test_users.py
├── pyproject.toml
└── Dockerfile
```

## Level 2 — production API (feature-based, the default)

The reference choice for most real backend projects — see
`rules/common/project-architectures.md`'s feature-based vs layer-based
discussion.

```
my-api/
├── app/
│   ├── main.py
│   ├── api/
│   │   └── v1/                # Explicit versioning
│   │       ├── __init__.py
│   │       └── router.py      # Aggregates every feature router
│   │
│   ├── features/               # Split by business domain
│   │   ├── users/
│   │   │   ├── __init__.py
│   │   │   ├── router.py      # HTTP endpoints
│   │   │   ├── service.py     # Business logic
│   │   │   ├── repository.py  # Data access
│   │   │   ├── schemas.py     # Pydantic request/response
│   │   │   └── models.py      # SQLAlchemy models
│   │   │
│   │   ├── billing/
│   │   │   ├── router.py
│   │   │   ├── service.py
│   │   │   └── schemas.py
│   │   │
│   │   └── notifications/
│   │       ├── service.py
│   │       └── tasks.py       # Celery/ARQ tasks
│   │
│   ├── core/                   # Global infrastructure
│   │   ├── config.py           # Settings (Pydantic BaseSettings)
│   │   ├── security.py         # JWT, hashing
│   │   ├── exceptions.py       # Global custom exceptions
│   │   └── middleware.py
│   │
│   ├── db/                     # Shared persistence layer
│   │   ├── session.py          # Async SQLAlchemy session
│   │   ├── base.py             # Declarative base
│   │   └── migrations/         # Alembic
│   │
│   └── shared/                 # Utilities shared across features
│       ├── dependencies.py     # Reusable FastAPI Depends()
│       └── utils.py
│
├── tests/
│   ├── conftest.py
│   ├── features/
│   │   ├── users/
│   │   │   ├── test_router.py
│   │   │   └── test_service.py
│   │   └── billing/
│   └── integration/
│
├── pyproject.toml
├── Dockerfile
└── docker-compose.yml
```

## Level 3 — hexagonal architecture (complex / audited systems)

Justified when the system is large, needs strong auditability, or must be
able to swap backends (DB, broker) without touching business logic. Not
a default — see the governing-rule note above.

```
my-api/
├── app/
│   ├── main.py
│   │
│   ├── users/                  # One module per domain
│   │   ├── domain/             # Zero external dependency — the core
│   │   │   ├── entities.py     # Business entities (pure dataclasses)
│   │   │   ├── value_objects.py
│   │   │   ├── exceptions.py   # Domain exceptions
│   │   │   └── ports.py        # Interfaces (Protocol/ABC) — what the domain needs
│   │   │
│   │   ├── application/        # Use cases — orchestrates the domain
│   │   │   ├── commands.py     # CreateUser, UpdateUser...
│   │   │   ├── queries.py      # GetUser, ListUsers...
│   │   │   └── handlers.py     # Implements the use cases
│   │   │
│   │   ├── infrastructure/     # Concrete adapters (depend on third-party libs)
│   │   │   ├── repository.py   # SQLAlchemy impl of ports.UserRepository
│   │   │   ├── email.py        # SendGrid impl of ports.EmailPort
│   │   │   └── cache.py        # Redis impl of ports.CachePort
│   │   │
│   │   └── presentation/       # HTTP, CLI, gRPC entry points
│   │       └── router.py       # FastAPI endpoints
│   │
│   └── shared/
│       ├── config.py
│       └── database.py
│
└── tests/
    ├── unit/                   # Domain tested without infra (mocked ports)
    └── integration/            # Adapters tested against a real DB
```

**Dependency rule**: `presentation → application → domain`. The domain
knows nothing above it. Adapters implement the ports the domain defines
— see `rules/python/oop-idioms.md` for `Protocol` vs `ABC` as the port
definition mechanism, and `rules/common/oop-design.md`'s Dependency
Inversion principle, which this structure is a direct instantiation of.
