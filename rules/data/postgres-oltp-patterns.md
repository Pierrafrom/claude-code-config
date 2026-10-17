---
paths: ["**/*.sql", "**/migrations/**", "**/schema.ts", "**/schema/**/*.ts", "**/db/**/*.ts", "**/repository*.ts"]
---

# PostgreSQL OLTP — transactional patterns

Operational companion to `rules/data/db-design.md` (modeling, constraints,
keys, money as integer cents — not repeated here) and
`rules/typescript/orm-drizzle.md` (ORM tooling). Applies to any
application where concurrent users mutate shared state: wallets,
inventories, auctions, bookings.

## Transactions

- Keep them **short**: no network call, file I/O or user wait inside one.
- Row-level locks (`SELECT ... FOR UPDATE`) on exactly the rows being
  read-modify-written; **lock in a consistent order** (e.g. by id
  ascending) to avoid deadlocks.
- Never table locks for application logic.
- Pick the isolation level deliberately; default `READ COMMITTED` plus
  explicit row locks and constraints covers most cases. If using
  `SERIALIZABLE`, code a retry on serialization failure.

## Idempotency

- Every mutating endpoint or job that must not run twice takes an
  **idempotency key**, stored in a table with a unique constraint scoped
  by owner + operation (all key columns `NOT NULL`: unique constraints
  treat NULLs as distinct).
- Claim the key with `INSERT ... ON CONFLICT DO NOTHING` **in the same
  transaction as the business effect** — a check-then-insert is a race.
- Store a fingerprint (hash) of the request body so a reused key with a
  different payload is rejected rather than silently replayed.
- Plan key expiry/cleanup (batched delete by primary key).
- Queue consumers are at-least-once: handlers must be idempotent by
  construction, not by hoping for exactly-once delivery
  (`rules/devops/queues-and-workers.md`).

## Ledger for virtual or real currency

- **Double-entry**: every movement is a balanced set of entries
  (debit = credit), written in one transaction. Balances are derived or
  maintained alongside, never edited alone.
- **Append-only**: corrections are reversing entries, never updates or
  deletes. Enforce with permissions/triggers where possible.
- Integer minor units only (`BIGINT`), never float/decimal drift.
- `CHECK` constraints for invariants (balance >= 0 where required);
  the database is the last line of defense, not the application.
- Audit fields on every entry: who, what, when, correlation/idempotency
  key. Economic operations are always logged.

## Queue-like tables and `SKIP LOCKED`

`FOR UPDATE SKIP LOCKED` lets several workers claim distinct rows
without blocking. The PostgreSQL manual warns it yields an inconsistent
view of the data, so use it only for queue-style claiming, filter on the
locked table itself (not on a joined table), and still make the handler
idempotent.

## Random selection at scale

Never `ORDER BY random()` on large tables (full scan + sort). Use dense
integer ids: draw a bucket/weight first, then a random id within the
matching range; handle holes (retry or ranges of live ids).

## Operations

- Backups: continuous WAL archiving to object storage (WAL-G or
  pgBackRest) **plus a scheduled restore test** — an untested backup is
  not a backup. Define RPO/RTO explicitly.
- Monitor slow queries (`pg_stat_statements`), connection count, replication
  lag, table/index bloat.
- Native `uuidv7()` (PostgreSQL 18+) gives time-ordered ids with good
  index locality.
- Never expose the database to the public internet; app and worker
  connect over a private network with least-privilege roles (the
  migration role differs from the runtime role).

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| PostgreSQL | postgresql.org/docs/current | Major release notes |
| Locking / isolation | postgresql.org/docs/current/explicit-locking.html | Behavior changes |
| Backup tooling | pgbackrest.org, github.com/wal-g/wal-g | Releases |
