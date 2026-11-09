---
paths: ["**/drizzle.config.*", "**/schema.ts", "**/schema/**/*.ts", "**/db/**/*.ts", "**/migrations/**"]
---

# Drizzle ORM (PostgreSQL) — conventions

Schema-design principles are in `rules/data/db-design.md`; transactional
patterns (idempotency, ledger, locking) in
`rules/data/postgres-oltp-patterns.md`. This file is only the Drizzle
tooling layer.

## Versioning

- Pin `drizzle-orm` and `drizzle-kit` **exactly** (they are versioned
  separately and a pre-1.0 line can break on a minor). Check the
  release status of the next major before any bump — a release
  candidate is not a target for a production project.
- Documented fallback if Drizzle becomes a liability: Prisma. Keep
  queries behind repositories so the ORM is replaceable.

## Migrations

- Local prototyping: `drizzle-kit push` is acceptable.
- **Any shared or production database: `drizzle-kit generate` then
  `drizzle-kit migrate`** — versioned SQL files committed to git, reviewed
  in PRs. Never `push` against production.
- Migrations are forward-only in production; a rollback is a new
  migration. Test them on a copy of realistic data before release.
- Destructive changes (drop/rename column) in two steps across releases.

## Driver and connection

- `postgres` (postgres.js) via `drizzle-orm/postgres-js`; one client per
  process, created in one module; pool size explicit. Add PgBouncer only
  when connection count requires it (note: transaction pooling limits
  prepared statements and session features).
- Connection string from validated env config, never inline.

## Queries

- Everything touching money or inventory runs in `db.transaction(...)`;
  row locks (`.for("update")`) when read-modify-write is needed. See
  `rules/data/postgres-oltp-patterns.md`.
- No N+1: batch with `inArray`/joins or the relational query API;
  paginate by cursor (indexed, stable sort key), not `OFFSET`, on large
  tables.
- Indexes follow real query plans (`EXPLAIN ANALYZE`), not guesses;
  declare them in the schema so they travel with migrations.
- Return explicit column lists on public queries — never leak columns
  (OWASP API3 object-property exposure).

## Generated schemas (auth libraries)

If a library generates tables (e.g. Better Auth), regenerate them with
its CLI whenever plugins change and commit the diff; hand-written copies
drift (`rules/common/auth-patterns.md`).

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| Drizzle ORM / Kit | orm.drizzle.team | 1.0 stable release, migration-format changes |
| postgres.js | github.com/porsager/postgres | Releases |
