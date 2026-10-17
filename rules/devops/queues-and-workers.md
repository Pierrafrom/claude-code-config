---
paths: ["**/workers/**", "**/*worker*.ts", "**/*queue*.ts", "**/docker-compose*.yml", "**/docker-compose*.yaml", "**/valkey*.conf", "**/redis*.conf"]
---

# Background jobs — BullMQ on Valkey/Redis

Applies to delayed/recurring/background work in Node services (auction
closing, imports, email, cleanup). Container-level hardening is in
`rules/devops/devops.md`; database patterns in
`rules/data/postgres-oltp-patterns.md`.

## Store configuration (BullMQ official production guidance)

- **`maxmemory-policy noeviction` is mandatory** — it is the only setting
  that guarantees queue correctness. An evicting instance silently
  corrupts queues.
- A queue instance is **never** also the application cache. Need a cache?
  Run a second instance with an eviction policy.
- Persistence (AOF) on; password (`requirepass`) set; reachable only on
  the private network, never published to the internet.
- Redis >= 6.2 is required; Valkey is a compatible fork — pin the major.

## Workers

- The `Worker` connection needs `maxRetriesPerRequest: null`. If you pass
  an existing ioredis instance, set it explicitly (BullMQ warns
  otherwise — treat that warning as an error).
- **Graceful shutdown**: on `SIGTERM`/`SIGINT` call `await worker.close()`
  before exit, so in-flight jobs are not marked stalled.
- Bound retention: `removeOnComplete: { count: N }` and a larger
  `removeOnFail: { count: M }` (keep failures for debugging).
- Retries with exponential backoff and a max attempts; a final failure
  goes to a dead-letter queue/alert, not silent loss.
- Concurrency is explicit per worker; CPU-bound work in a separate
  process or sandboxed processor.

## Job design

- **Idempotent by construction**: a replayed job (stall, retry, crash
  after commit) must not double-apply. Use an idempotency key / a
  conditional state transition in the database, in the same transaction
  as the effect.
- Job payloads carry **ids, not entities** — read fresh state when the
  job runs. Payloads are small and versionable.
- Prefer scheduled/repeatable jobs with a stable job id over
  "check everything every minute" polling.
- Log each job with the structured JSONL fields from
  `rules/common/logging.md` (job id, queue, attempt, duration).

## Observability

Track queue depth, oldest waiting job age, failure rate, stalled count;
alert on growth, not just on failures.

## Sources to watch (as of 2026-10-17)

| Domain | Canonical source | Change signal |
|---|---|---|
| BullMQ | docs.bullmq.io (Going to production) | Major releases |
| Valkey | valkey.io | Major versions, config changes |
