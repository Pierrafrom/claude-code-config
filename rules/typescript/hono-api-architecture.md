---
paths: ["**/*.ts", "**/package.json", "**/tsconfig*.json"]
---

# Hono API — structure and conventions

TypeScript counterpart of `rules/python/fastapi-architecture.md`. Same
governing rule (`rules/common/project-architectures.md`): pick the level
that matches the project's size today, not the most sophisticated one.
Hono is runtime-agnostic (Node, Bun, Workers); keep the runtime adapter
in one entry file so a runtime change touches nothing else.

## Non-negotiables

- **Chain every route** (`new Hono().get(...).post(...)`) and compose
  sub-routers with `.route()`. Type inference for the RPC client (`hc`)
  and `testClient()` only works through chained calls on a declared
  variable. Registering routes on a separate statement silently loses
  types.
- Export the type once (`export type AppType = typeof routes`) from a
  dedicated `types.ts`; clients import it with **`import type`** only.
- **Validate every external input with Zod** via `@hono/zod-validator`
  (`json`, `query`, `param`, headers). Business code receives parsed,
  typed data only. Shared schemas live in a shared package so client and
  server agree.
- **CORS**: explicit origin allow-list; never reflect the `Origin`
  header, never `*` with `credentials: true`.
- Public, cacheable resources set `Cache-Control` so a CDN absorbs
  traffic; authenticated responses are `private`/`no-store`.
- Centralized error handling (`app.onError`) mapping domain errors
  (`rules/python/oop-idioms.md` pattern: exception hierarchy mirroring the
  domain) to HTTP codes; handlers never leak stack traces or SQL errors.
- Graceful shutdown on `SIGTERM`/`SIGINT`: stop accepting requests, drain,
  close DB pool.

## Level 1 — small service

```
api/
├── src/
│   ├── index.ts          # runtime adapter (serve) only
│   ├── app.ts            # chained app + AppType
│   ├── routes/           # one chained sub-router per resource
│   ├── db/               # client + schema
│   └── config.ts         # env parsed once with Zod, fail-fast
└── tests/
```

## Level 2 — production API (feature-based, the default)

```
apps/api/src/
├── index.ts
├── app.ts                    # mounts feature routers, global middleware
├── types.ts                  # export type AppType
├── features/
│   └── <feature>/
│       ├── router.ts         # chained routes + validators
│       ├── service.ts        # business logic (no Hono imports)
│       ├── repository.ts     # data access
│       └── schemas.ts        # or re-exported from the shared package
├── core/                     # config, errors, middleware, logger
├── db/                       # client, schema, migrations
└── workers/                  # queue processors (see rules/devops/queues-and-workers.md)
```

Dependency direction: `router -> service -> repository`. Services never
import `hono`; this keeps them unit-testable without HTTP and honors
`rules/common/oop-design.md` (DIP).

## Level 3 — hexagonal

Same as `rules/python/fastapi-architecture.md` level 3 (domain / application /
infrastructure / presentation, ports as interfaces). Only for large or
audited systems.

## Testing

- Unit-test services without HTTP. Test routes with `app.request()` or
  `testClient()`; integration tests hit a real Postgres (container), not
  a mock of the ORM.
- A contract test per public route: valid input, each validation failure,
  authorization failure.

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| Hono, RPC, best practices | hono.dev/docs | Release notes, `@hono/zod-validator` majors |
| Zod | zod.dev | Major version bumps |
